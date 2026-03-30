import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/menu_model.dart';
import '../../../data/models/review.dart';
import '../../../data/providers/restaurant_provider.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/providers/locale_provider.dart';
import '../../../data/services/phase3_service.dart';
import '../../widgets/common/rating_stars.dart';

class ItemDetailsScreen extends StatefulWidget {
  final int itemId;

  const ItemDetailsScreen({super.key, required this.itemId});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final Phase3Service _phase3Service = Phase3Service();
  MenuItem? _item;
  ReviewSummary? _reviewSummary;
  List<Review> _reviews = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  int _quantity = 1;
  final Set<int> _selectedAddOnIds = {};
  final TextEditingController _notesController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_showTitle) {
      setState(() => _showTitle = true);
    } else if (_scrollController.offset <= 200 && _showTitle) {
      setState(() => _showTitle = false);
    }
  }

  Future<void> _loadData() async {
    final provider = context.read<RestaurantProvider>();
    
    try {
      final results = await Future.wait([
        provider.getItemDetails(widget.itemId),
        _phase3Service.getItemReviewSummary(widget.itemId),
        _phase3Service.getItemReviews(widget.itemId),
        _phase3Service.isFavorite(widget.itemId),
      ]);

      if (mounted) {
        setState(() {
          _item = results[0] as MenuItem?;
          _reviewSummary = results[1] as ReviewSummary?;
          _reviews = results[2] as List<Review>;
          _isFavorite = results[3] as bool;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final success = await _phase3Service.toggleFavorite(widget.itemId);
    if (success && mounted) {
      setState(() => _isFavorite = !_isFavorite);
    }
  }

  void _addToCart() {
    if (_item == null) return;

    final cartProvider = context.read<CartProvider>();
    final selectedAddOns = _item!.addOns
        .where((a) => _selectedAddOnIds.contains(a.id))
        .toList();

    cartProvider.addItem(
      _item!,
      quantity: _quantity,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      addOns: selectedAddOns,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('added_to_cart')),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pop();
  }

  double get _totalPrice {
    if (_item == null) return 0;
    
    double addOnsTotal = _item!.addOns
        .where((a) => _selectedAddOnIds.contains(a.id))
        .fold(0, (sum, a) => sum + a.price);
    
    return (_item!.effectivePrice + addOnsTotal) * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(context.tr('error'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Image Header
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: _showTitle ? Colors.white : Colors.transparent,
                elevation: _showTitle ? 2 : 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _showTitle ? Colors.transparent : Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: _showTitle ? AppTheme.textPrimary : Colors.white,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _showTitle ? Colors.transparent : Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : (_showTitle ? AppTheme.textPrimary : Colors.white),
                      ),
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ],
                title: _showTitle ? Text(_item!.getName(isArabic)) : null,
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'item_${widget.itemId}',
                    child: _item!.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: _item!.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: Colors.grey[200]),
                            errorWidget: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.fastfood, size: 80)),
                          )
                        : Container(color: Colors.grey[200], child: const Icon(Icons.fastfood, size: 80)),
                  ),
                ),
              ),

              // Product Info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_item!.getName(isArabic), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                if (_reviewSummary != null)
                                  GestureDetector(
                                    onTap: () {
                                      // Scroll to reviews
                                    },
                                    child: Row(
                                      children: [
                                        RatingStars(rating: _reviewSummary!.averageRating, size: 16),
                                        const SizedBox(width: 8),
                                        Text('(${_reviewSummary!.totalReviews} ${context.tr('reviews')})', style: const TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (_item!.hasDiscount)
                                Text(
                                  '${_item!.price} ${context.tr('currency')}',
                                  style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey),
                                ),
                              Text(
                                '${_item!.effectivePrice} ${context.tr('currency')}',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Description
                      if (_item!.getDescription(isArabic) != null) ...[
                        Text(context.tr('description'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          _item!.getDescription(isArabic)!,
                          style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Info Row
                      Row(
                        children: [
                          _buildInfoChip(Icons.timer_outlined, '${_item!.preparationTimeMinutes} ${context.tr('min')}'),
                          const SizedBox(width: 12),
                          if (_item!.calories != null)
                            _buildInfoChip(Icons.local_fire_department_outlined, '${_item!.calories} ${context.tr('cal')}'),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Add-ons
                      if (_item!.addOns.isNotEmpty) ...[
                        Text(context.tr('add_ons'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        ..._item!.addOns.where((a) => a.isAvailable).map((addOn) {
                          final isSelected = _selectedAddOnIds.contains(addOn.id);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) _selectedAddOnIds.add(addOn.id);
                                else _selectedAddOnIds.remove(addOn.id);
                              });
                            },
                            title: Text(addOn.getName(isArabic)),
                            subtitle: Text('+${addOn.price} ${context.tr('currency')}'),
                            activeColor: AppTheme.primaryColor,
                            contentPadding: EdgeInsets.zero,
                          );
                        }),
                        const SizedBox(height: 24),
                      ],

                      // Special Instructions
                      Text(context.tr('special_instructions'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: context.tr('special_instructions_hint'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Reviews Section
                      _buildReviewsSection(),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                          ),
                          Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _addToCart,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('${context.tr('add_to_cart')} - ${_totalPrice.toStringAsFixed(2)} ${context.tr('currency')}'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.tr('reviews'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_reviews.isNotEmpty)
              TextButton(
                onPressed: () {
                  // Navigate to all reviews
                },
                child: Text(context.tr('view_all')),
              ),
          ],
        ),
        if (_reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(context.tr('no_reviews')),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length > 3 ? 3 : _reviews.length,
            separatorBuilder: (_, __) => const Divider(height: 32),
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(review.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      RatingStars(rating: review.rating.toDouble(), size: 14),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(review.comment ?? '', style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}
