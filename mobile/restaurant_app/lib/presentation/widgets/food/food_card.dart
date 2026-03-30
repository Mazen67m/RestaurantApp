import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../common/rating_stars.dart';

enum FoodCardLayout { horizontal, vertical, grid }

class FoodCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String? description;
  final double price;
  final double? rating;
  final int? reviewCount;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onAddToCart;
  final FoodCardLayout layout;
  final String? badge;

  const FoodCard({
    super.key,
    required this.imageUrl,
    required this.name,
    this.description,
    required this.price,
    this.rating,
    this.reviewCount,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
    this.onAddToCart,
    this.layout = FoodCardLayout.horizontal,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    switch (layout) {
      case FoodCardLayout.horizontal:
        return _buildHorizontalCard(context);
      case FoodCardLayout.vertical:
        return _buildVerticalCard(context);
      case FoodCardLayout.grid:
        return _buildGridCard(context);
    }
  }

  Widget _buildHorizontalCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingHorizontal,
        vertical: AppDimensions.spaceSm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              _buildImage(
                width: 100,
                height: 100,
              ),
              const SizedBox(width: AppDimensions.spaceMd),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      name,
                      style: AppTypography.h4,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    if (description != null) ...[
                      const SizedBox(height: AppDimensions.spaceXs),
                      Text(
                        description!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    if (rating != null) ...[
                      const SizedBox(height: AppDimensions.spaceSm),
                      RatingStars(
                        rating: rating!,
                        reviewCount: reviewCount,
                        size: 14,
                      ),
                    ],
                    
                    const SizedBox(height: AppDimensions.spaceSm),
                    
                    // Price and Add Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (onAddToCart != null)
                          _buildAddButton(),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Favorite Button
              if (onFavoriteToggle != null)
                _buildFavoriteButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(AppDimensions.spaceSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with favorite button
            Stack(
              children: [
                _buildImage(
                  width: double.infinity,
                  height: AppDimensions.foodCardImageHeight,
                ),
                if (onFavoriteToggle != null)
                  Positioned(
                    top: AppDimensions.spaceSm,
                    right: AppDimensions.spaceSm,
                    child: _buildFavoriteButton(),
                  ),
                if (badge != null)
                  Positioned(
                    top: AppDimensions.spaceSm,
                    left: AppDimensions.spaceSm,
                    child: _buildBadge(badge!),
                  ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    name,
                    style: AppTypography.h4,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  if (description != null) ...[
                    const SizedBox(height: AppDimensions.spaceXs),
                    Text(
                      description!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  if (rating != null) ...[
                    const SizedBox(height: AppDimensions.spaceSm),
                    RatingStars(
                      rating: rating!,
                      reviewCount: reviewCount,
                      size: 14,
                    ),
                  ],
                  
                  const SizedBox(height: AppDimensions.spaceSm),
                  
                  // Price and Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (onAddToCart != null)
                        _buildAddButton(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(AppDimensions.spaceXs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                _buildImage(
                  width: double.infinity,
                  height: 120,
                ),
                if (onFavoriteToggle != null)
                  Positioned(
                    top: AppDimensions.spaceXs,
                    right: AppDimensions.spaceXs,
                    child: _buildFavoriteButton(size: 32),
                  ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: AppTypography.fontSemiBold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  if (rating != null) ...[
                    const SizedBox(height: AppDimensions.spaceXs),
                    RatingStars(
                      rating: rating!,
                      size: 12,
                      showRatingText: false,
                    ),
                  ],
                  
                  const SizedBox(height: AppDimensions.spaceXs),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (onAddToCart != null)
                        _buildAddButton(size: 28),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage({required double width, required double height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.inputBackground,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppColors.inputBackground,
          child: const Icon(
            Icons.restaurant,
            color: AppColors.textHint,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton({double size = 36}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? AppColors.primary : AppColors.textSecondary,
          size: size * 0.5,
        ),
        onPressed: onFavoriteToggle,
      ),
    );
  }

  Widget _buildAddButton({double size = 36}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.add,
          color: AppColors.textWhite,
          size: size * 0.6,
        ),
        onPressed: onAddToCart,
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: AppDimensions.paddingXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentRed,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: AppColors.textWhite,
          fontWeight: AppTypography.fontBold,
        ),
      ),
    );
  }
}
