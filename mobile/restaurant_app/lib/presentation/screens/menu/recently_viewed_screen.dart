import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class RecentlyViewedScreen extends StatelessWidget {
  const RecentlyViewedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy Data
    final List<Map<String, dynamic>> recentItems = [
      {
        'id': '1',
        'name': 'Double Cheese Burger',
        'price': 12.99,
        'image': 'assets/images/burger.jpg',
        'rating': 4.5,
      },
      {
        'id': '2',
        'name': 'Pepperoni Pizza',
        'price': 15.50,
        'image': 'assets/images/pizza.jpg',
        'rating': 4.8,
      },
      {
        'id': '3',
        'name': 'Caesar Salad',
        'price': 8.99,
        'image': 'assets/images/salad.jpg',
        'rating': 4.2,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Recently Viewed', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Clear', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: recentItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  const Text(
                    'No recently viewed items',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: recentItems.length,
              separatorBuilder: (context, index) => const Divider(color: AppColors.border, height: 1),
              itemBuilder: (context, index) {
                final item = recentItems[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  leading: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.fastfood, color: AppColors.primary, size: 30),
                  ),
                  title: Text(
                    item['name'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                      Text(
                        ' ${item['rating']}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  trailing: Text(
                    '\$${item['price']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  onTap: () {},
                );
              },
            ),
    );
  }
}
