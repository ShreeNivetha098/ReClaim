import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/date_formatter.dart';
import 'category_style.dart';
import 'custom_card.dart';
import 'item_image.dart';
import 'status_chip.dart';

/// Photo-first card for a lost or found report. Works in grids and lists.
class ItemCard extends StatelessWidget {
  /// Height of a card in a two-column grid. The photo area shrinks to fit,
  /// so the text never overflows even with larger system text sizes.
  static const double gridHeight = 286;

  final String title;
  final String category;
  final String location;
  final DateTime date;
  final DateTime? createdAt;
  final String? imageUrl;
  final String status;
  final bool isLost;
  final double? matchPercentage;
  final String? reporterName;
  final VoidCallback onTap;

  const ItemCard({
    super.key,
    required this.title,
    required this.category,
    required this.location,
    required this.date,
    this.createdAt,
    this.imageUrl,
    required this.status,
    required this.isLost,
    this.matchPercentage,
    this.reporterName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveCreatedAt = createdAt ?? date;
    final countdownLabel = DateFormatter.getUnclaimedCountdownLabel(effectiveCreatedAt, status);
    final typeColor = isLost ? AppColors.lost : AppColors.found;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return CustomCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // In a grid the card has a fixed height: let the photo take what is
          // left after the text. In a list it gets a fixed photo height.
          final photo = _photo(hasImage, typeColor, countdownLabel);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (constraints.hasBoundedHeight) Expanded(child: photo) else SizedBox(height: 140, child: photo),
              _details(),
            ],
          );
        },
      ),
    );
  }

  Widget _photo(bool hasImage, Color typeColor, String? countdownLabel) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            ItemImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (context) => Container(color: typeColor.withValues(alpha: 0.08)),
              error: (context) => _placeholder(typeColor),
            )
          else
            _placeholder(typeColor),

          // Lost / Found pill
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: isLost ? AppColors.lostGradient : AppColors.foundGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isLost ? 'LOST' : 'FOUND',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),

          if (matchPercentage != null)
            Positioned(
              top: 10,
              right: 10,
              child: _overlayPill(
                icon: Icons.auto_awesome_rounded,
                label: '${matchPercentage!.toStringAsFixed(0)}% match',
                color: AppColors.accentDark,
              ),
            ),

          if (countdownLabel != null)
            Positioned(
              bottom: 10,
              left: 10,
              child: _overlayPill(
                icon: countdownLabel == 'Unclaimed period expired'
                    ? Icons.timer_off_outlined
                    : Icons.hourglass_bottom_rounded,
                label: countdownLabel,
                color: countdownLabel == 'Unclaimed period expired'
                    ? AppColors.statusUnclaimedText
                    : AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _details() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          _metaRow(categoryIcon(category), category),
          const SizedBox(height: 4),
          _metaRow(Icons.location_on_rounded, location),
          const SizedBox(height: 4),
          _metaRow(Icons.schedule_rounded, DateFormatter.formatDate(date)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  reporterName != null && reporterName!.trim().isNotEmpty ? reporterName! : 'Unknown user',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(width: 6),
              StatusChip(status: status, compact: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.10), color.withValues(alpha: 0.22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Icon(categoryIcon(category), size: 48, color: color.withValues(alpha: 0.75))),
    );
  }

  Widget _overlayPill({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppStyles.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
