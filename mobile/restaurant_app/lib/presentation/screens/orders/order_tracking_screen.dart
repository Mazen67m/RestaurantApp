import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/order_tracking_provider.dart';
import '../../../data/services/signalr_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;
  final String orderNumber;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OrderTrackingProvider>();
      provider.startTrackingOrder(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(context.tr('track_order')),
            Text(
              '#${widget.orderNumber}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Consumer<OrderTrackingProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection Status
                _buildConnectionStatus(provider),
                const SizedBox(height: 24),
                
                // Order Status Card
                _buildStatusCard(provider),
                const SizedBox(height: 24),
                
                // Status Timeline
                _buildStatusTimeline(provider),
                const SizedBox(height: 24),
                
                // Estimated Time
                if (provider.latestStatusUpdate?.estimatedTime != null)
                  _buildEstimatedTime(provider.latestStatusUpdate!.estimatedTime!),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatus(OrderTrackingProvider provider) {
    final isConnected = provider.isConnected;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isConnected ? AppTheme.successColor.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? AppTheme.successColor : Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? context.tr('live_tracking') : context.tr('connecting'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isConnected ? AppTheme.successColor : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(OrderTrackingProvider provider) {
    final update = provider.latestStatusUpdate;
    final statusText = update?.statusText ?? context.tr('waiting_for_update');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFFE64A19)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _getStatusIcon(update?.status ?? ''),
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 20),
          Text(
            statusText,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (update != null) ...[
            const SizedBox(height: 12),
            Text(
              '${context.tr('updated')} ${_formatTime(update.updatedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(OrderTrackingProvider provider) {
    final currentStatus = provider.latestStatusUpdate?.status ?? 'Pending';
    
    final statuses = [
      {'key': 'Pending', 'label': 'order_received', 'icon': Icons.receipt_long},
      {'key': 'Confirmed', 'label': 'order_confirmed', 'icon': Icons.check_circle_outline},
      {'key': 'Preparing', 'label': 'preparing', 'icon': Icons.restaurant},
      {'key': 'Ready', 'label': 'ready', 'icon': Icons.shopping_bag_outlined},
      {'key': 'OutForDelivery', 'label': 'out_for_delivery', 'icon': Icons.delivery_dining},
      {'key': 'Delivered', 'label': 'delivered', 'icon': Icons.home_outlined},
    ];
    
    final currentIndex = statuses.indexWhere((s) => s['key'] == currentStatus);
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('order_progress'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ...statuses.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final isActive = index <= currentIndex;
              final isCurrent = index == currentIndex;
              
              return _buildTimelineItem(
                label: context.tr(status['label'] as String),
                icon: status['icon'] as IconData,
                isActive: isActive,
                isCurrent: isCurrent,
                isLast: index == statuses.length - 1,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String label,
    required IconData icon,
    required bool isActive,
    required bool isCurrent,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppTheme.primaryColor : Colors.grey.shade100,
                  border: isCurrent ? Border.all(color: AppTheme.primaryColor, width: 2) : null,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isActive ? Colors.white : Colors.grey.shade400,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isActive ? AppTheme.primaryColor : Colors.grey.shade100,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimatedTime(String time) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('estimated_arrival'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending': return Icons.receipt_long;
      case 'Confirmed': return Icons.check_circle_outline;
      case 'Preparing': return Icons.restaurant;
      case 'Ready': return Icons.shopping_bag_outlined;
      case 'OutForDelivery': return Icons.delivery_dining;
      case 'Delivered': return Icons.home_outlined;
      case 'Cancelled': return Icons.cancel_outlined;
      default: return Icons.hourglass_top_rounded;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inSeconds < 60) return context.tr('just_now');
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ${context.tr('ago')}';
    if (diff.inHours < 24) return '${diff.inHours}h ${context.tr('ago')}';
    return '${diff.inDays}d ${context.tr('ago')}';
  }
}
