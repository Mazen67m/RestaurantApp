import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/loyalty.dart';
import '../../../data/services/phase3_service.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';

class LoyaltyDashboardScreen extends StatefulWidget {
  const LoyaltyDashboardScreen({super.key});

  @override
  State<LoyaltyDashboardScreen> createState() => _LoyaltyDashboardScreenState();
}

class _LoyaltyDashboardScreenState extends State<LoyaltyDashboardScreen> {
  final Phase3Service _service = Phase3Service();
  LoyaltyPoints? _points;
  List<LoyaltyTransaction> _transactions = [];
  List<LoyaltyTier> _tiers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _service.getMyPoints(),
        _service.getTransactionHistory(limit: 20),
        _service.getTiers(),
      ]);

      if (mounted) {
        setState(() {
          _points = results[0] as LoyaltyPoints?;
          _transactions = results[1] as List<LoyaltyTransaction>;
          _tiers = results[2] as List<LoyaltyTier>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('error_loading_loyalty'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('my_loyalty')),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _buildPointsCard(),
                    _buildTierProgress(),
                    _buildRedeemSection(),
                    _buildTransactionHistory(),
                    _buildTierBenefits(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPointsCard() {
    final points = _points;
    if (points == null) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(context.tr('no_loyalty_data')),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(points.tierColor).withOpacity(0.8),
            Color(points.tierColor),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(points.tierColor).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  points.tierIcon,
                  style: const TextStyle(fontSize: 44),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${points.tier} ${context.tr('member')}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${points.bonusMultiplier}x ${context.tr('points')}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              '${points.points}',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            Text(
              context.tr('available_points'),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPointsStat(context.tr('earned'), points.totalEarned),
                  Container(width: 1, height: 24, color: Colors.white24),
                  _buildPointsStat(context.tr('redeemed'), points.totalRedeemed),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsStat(String label, int value) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTierProgress() {
    final points = _points;
    if (points == null || points.tier.toLowerCase() == 'platinum') return const SizedBox();

    final progress = points.pointsToNextTier > 0
        ? 1.0 - (points.pointsToNextTier / 1000.0) // Simplified logic
        : 1.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${points.pointsToNextTier} ${context.tr('points_to')} ${points.nextTier}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade100,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedeemSection() {
    final points = _points;
    if (points == null || points.points < 100) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '🎁 ${context.tr('redeem_points')}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              _buildRedeemChip(100),
              const SizedBox(width: 12),
              _buildRedeemChip(500),
              const SizedBox(width: 12),
              _buildRedeemChip(1000),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemChip(int value) {
    final isEnabled = (_points?.points ?? 0) >= value;
    final discount = value ~/ 100 * 10; // Simplified logic for demo (100 = 10 L.E)
    
    return Expanded(
      child: InkWell(
        onTap: isEnabled ? () => _showRedeemDialog(value, discount) : null,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isEnabled ? AppTheme.primaryColor.withOpacity(0.05) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEnabled ? AppTheme.primaryColor : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? AppTheme.primaryColor : Colors.grey,
                  ),
                ),
                Text(
                  context.tr('points'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isEnabled ? AppTheme.primaryColor.withOpacity(0.7) : Colors.grey,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Divider(height: 1),
                ),
                Text(
                  '$discount ${context.tr('currency')}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRedeemDialog(int points, int discount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('redeem_points')),
        content: Text('${context.tr('redeem')} $points ${context.tr('points')} ${context.tr('for')} $discount ${context.tr('currency')}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _redeemPoints(points);
            },
            child: Text(context.tr('redeem')),
          ),
        ],
      ),
    );
  }

  Future<void> _redeemPoints(int points) async {
    setState(() => _isLoading = true);
    final result = await _service.redeemPoints(RedeemPointsRequest(points: points));
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (result != null && result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('redeemed_success')} ${result.discountAmount} ${context.tr('currency')}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?.message ?? context.tr('redemption_failed')),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildTransactionHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '📊 ${context.tr('history')}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_transactions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text(context.tr('no_transactions'))),
              ),
            )
          else
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
                itemBuilder: (context, index) {
                  final tx = _transactions[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (tx.isEarning ? Colors.green : Colors.red).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(tx.icon, style: const TextStyle(fontSize: 20)),
                    ),
                    title: Text(
                      tx.transactionType,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(tx.description ?? ''),
                    trailing: Text(
                      tx.formattedPoints,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: tx.isEarning ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTierBenefits() {
    if (_tiers.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '🏆 ${context.tr('tier_benefits')}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Column(
            children: _tiers.map((tier) {
              final isCurrentTier = _points?.tier == tier.name;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isCurrentTier ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrentTier ? AppTheme.primaryColor : Colors.grey.shade200,
                    width: isCurrentTier ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Color(_getTierColorValue(tier.name)),
                    radius: 24,
                    child: Text(
                      '${tier.bonusMultiplier}x',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  title: Text(
                    tier.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCurrentTier ? AppTheme.primaryColor : AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(tier.benefits),
                  ),
                  trailing: isCurrentTier
                      ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  int _getTierColorValue(String tier) {
    switch (tier.toLowerCase()) {
      case 'platinum': return 0xFF2C3E50;
      case 'gold': return 0xFFFFD700;
      case 'silver': return 0xFFC0C0C0;
      default: return 0xFFCD7F32;
    }
  }
}
