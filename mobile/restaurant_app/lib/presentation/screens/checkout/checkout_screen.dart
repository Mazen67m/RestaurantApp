import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/order_model.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/restaurant_provider.dart';
import '../../../data/providers/branch_provider.dart';
import '../../../data/providers/address_provider.dart';
import '../../../data/providers/locale_provider.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/constants.dart';
import 'order_confirmation_screen.dart';
import '../auth/login_screen.dart';
import '../branch/branch_selection_screen.dart';
import '../addresses/address_list_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;
  String? _error;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final authProvider = context.read<AuthProvider>();
    
    // Check if user is logged in
    if (!authProvider.isAuthenticated) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!authProvider.isAuthenticated) return;
    }

    final cartProvider = context.read<CartProvider>();
    
    if (!cartProvider.canCheckout) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete all required fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      cartProvider.setCustomerNotes(_notesController.text);
      
      final orderData = cartProvider.toOrderJson();
      
      final apiService = ApiService();
      final response = await apiService.post<Map<String, dynamic>>(
        ApiConstants.orders,
        body: orderData,
        fromJson: (data) {
          // Handle different response structures
          if (data is Map<String, dynamic>) {
            // Check if data is nested under 'data' key
            if (data.containsKey('data')) {
              final nestedData = data['data'];
              if (nestedData is Map<String, dynamic>) {
                return nestedData;
              }
            }
            return data;
          }
          return <String, dynamic>{};
        },
      );

      if (response.success && response.data != null) {
        final responseData = response.data!;
        
        // Try different possible field names for order number
        final orderNumber = responseData['orderNumber']?.toString() ?? 
                           responseData['OrderNumber']?.toString() ??
                           responseData['id']?.toString() ?? 
                           'ORD-${DateTime.now().millisecondsSinceEpoch}';
        
        // Try different possible field names for order ID
        dynamic orderIdValue = responseData['orderId'] ?? 
                              responseData['OrderId'] ??
                              responseData['id'] ?? 
                              0;
        
        final orderId = orderIdValue is int 
            ? orderIdValue 
            : int.tryParse(orderIdValue.toString()) ?? 0;
        
        cartProvider.clearCart();
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => OrderConfirmationScreen(
                orderNumber: orderNumber,
                orderId: orderId,
              ),
            ),
          );
        }
      } else {
        final errorMsg = response.message ?? 'Failed to place order';
        setState(() => _error = errorMsg);
      }
    } catch (e, _) {
      setState(() => _error = 'Failed to place order: ${e.toString()}');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final cartProvider = context.watch<CartProvider>();
    final restaurantProvider = context.watch<RestaurantProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('checkout')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Type
            Text(
              context.tr('order_type'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildOrderTypeOption(
                    context,
                    OrderType.delivery,
                    Icons.delivery_dining,
                    context.tr('delivery'),
                    cartProvider,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOrderTypeOption(
                    context,
                    OrderType.pickup,
                    Icons.store,
                    context.tr('pickup'),
                    cartProvider,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Branch Selection
            Text(
              context.tr('branch'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Consumer<BranchProvider>(
              builder: (context, branchProvider, child) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.restaurant, color: AppTheme.primaryColor),
                    title: Text(
                      branchProvider.selectedBranch?.getName(isArabic) ?? 
                          context.tr('select_branch'),
                    ),
                    subtitle: branchProvider.selectedBranch != null
                        ? Text(branchProvider.selectedBranch!.address)
                        : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final selected = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BranchSelectionScreen(isFromCheckout: true),
                        ),
                      );
                      if (selected != null) {
                        // Branch selected
                      }
                    },
                  ),
                );
              },
            ),

            // Delivery Address (only for delivery)
            if (cartProvider.orderType == OrderType.delivery) ...[
              const SizedBox(height: 24),
              Text(
                context.tr('delivery_address'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Consumer<AddressProvider>(
                builder: (context, addressProvider, child) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.location_on, color: AppTheme.primaryColor),
                      title: Text(
                        addressProvider.selectedAddress != null
                            ? addressProvider.selectedAddress!.label
                            : context.tr('select_address'),
                      ),
                      subtitle: addressProvider.selectedAddress != null
                          ? Text('${addressProvider.selectedAddress!.building}, ${addressProvider.selectedAddress!.street}')
                          : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final selected = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddressListScreen(isFromCheckout: true),
                          ),
                        );
                        if (selected != null) {
                          // Address selected
                        }
                      },
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 24),

            // Payment Method
            Text(
              context.tr('payment_method'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildPaymentMethodOption(
              context,
              0, // Cash on Delivery
              Icons.money,
              context.tr('cash_on_delivery'),
              context.tr('pay_when_received'),
              cartProvider,
            ),
            const SizedBox(height: 8),
            _buildPaymentMethodOption(
              context,
              1, // Credit Card / Visa
              Icons.credit_card,
              'Credit Card / Visa',
              'Pay securely with your card',
              cartProvider,
            ),

            const SizedBox(height: 24),

            // Notes
            Text(
              context.tr('special_instructions'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: context.tr('special_instructions'),
              ),
            ),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.errorColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('total'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${cartProvider.total.toStringAsFixed(0)} AED',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          context.tr('place_order'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTypeOption(
    BuildContext context,
    OrderType type,
    IconData icon,
    String label,
    CartProvider cartProvider,
  ) {
    final isSelected = cartProvider.orderType == type;
    
    return GestureDetector(
      onTap: () => cartProvider.setOrderType(type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppTheme.primaryColor : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(
    BuildContext context,
    int method,
    IconData icon,
    String title,
    String subtitle,
    CartProvider cartProvider,
  ) {
    final isSelected = cartProvider.paymentMethod == method;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.primaryColor : Colors.grey,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.primaryColor : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
            : const Icon(Icons.circle_outlined, color: Colors.grey),
        onTap: () => cartProvider.setPaymentMethod(method),
      ),
    );
  }

  void _showBranchSelector(
    BuildContext context,
    RestaurantProvider restaurantProvider,
    bool isArabic,
  ) {
    final cartProvider = context.read<CartProvider>();
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('select_branch'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...restaurantProvider.branches.map((branch) => ListTile(
              leading: const Icon(Icons.restaurant),
              title: Text(branch.getName(isArabic)),
              subtitle: Text(branch.getAddress(isArabic)),
              trailing: cartProvider.selectedBranch?.id == branch.id
                  ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                cartProvider.setSelectedBranch(branch);
                Navigator.of(ctx).pop();
              },
            )),
          ],
        ),
      ),
    );
  }
}
