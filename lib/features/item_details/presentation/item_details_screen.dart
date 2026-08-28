import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/models/lost_item_model.dart';
import '../../../shared/models/found_item_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../matching/presentation/potential_matches_screen.dart';
import '../../claims/presentation/ownership_verification_screen.dart';

class ItemDetailsScreen extends ConsumerWidget {
  final LostItemModel? lostItem;
  final FoundItemModel? foundItem;

  const ItemDetailsScreen({
    super.key,
    this.lostItem,
    this.foundItem,
  }) : assert(lostItem != null || foundItem != null, 'Either lostItem or foundItem must be supplied');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLost = lostItem != null;
    final title = isLost ? lostItem!.itemName : foundItem!.itemName;
    final category = isLost ? lostItem!.category : foundItem!.category;
    final description = isLost ? lostItem!.description : foundItem!.description;
    final brand = isLost ? lostItem!.brand : foundItem!.brand;
    final colour = isLost ? lostItem!.colour : foundItem!.colour;
    final location = isLost ? lostItem!.locationLost : foundItem!.locationFound;
    final date = isLost ? lostItem!.dateLost : foundItem!.dateFound;
    final imageUrl = isLost ? lostItem!.imageUrl : foundItem!.imageUrl;
    final status = isLost ? lostItem!.status : foundItem!.status;

    return Scaffold(
      appBar: AppBar(
        title: Text(isLost ? 'Lost Item Details' : 'Found Item Details'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Center(
              child: StatusChip(status: status),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header
            Container(
              height: 250,
              width: double.infinity,
              color: isLost
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.secondary.withValues(alpha: 0.08),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        isLost ? Icons.search_off : Icons.find_in_page,
                        size: 64,
                        color: AppColors.textMuted,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isLost ? Icons.search : Icons.inventory_2_outlined,
                            size: 64,
                            color: isLost ? AppColors.primary : AppColors.secondary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No Image Provided',
                            style: TextStyle(
                              color: isLost ? AppColors.primary : AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Badge & Category
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLost ? AppColors.primary : AppColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isLost ? 'LOST ITEM' : 'FOUND ITEM',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Item Name
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Smart Match Box (If Lost Item)
                  if (isLost) ...[
                    Consumer(
                      builder: (context, ref, child) {
                        final matches = ref.watch(potentialMatchesProvider(lostItem!));
                        if (matches.isEmpty) return const SizedBox.shrink();

                        final topMatch = matches.first;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.accent, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: AppColors.accentDark, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Potential Match Found!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accentDark,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${topMatch.matchPercentage.toStringAsFixed(0)}% MATCH',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Found item "${topMatch.foundItem.itemName}" at ${topMatch.foundItem.locationFound} matches this lost item.',
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 12),
                              CustomButton(
                                text: 'View All Potential Matches (${matches.length})',
                                type: CustomButtonType.outlined,
                                height: 42,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PotentialMatchesScreen(lostItem: lostItem!),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Information Cards Grid
                  const Text(
                    'Item Specifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.location_on_outlined, 'Location', location),
                  _buildDetailRow(Icons.calendar_today_rounded, 'Date Reported', DateFormat('MMMM dd, yyyy').format(date)),
                  _buildDetailRow(Icons.branding_watermark_outlined, 'Brand', brand.isEmpty ? 'N/A' : brand),
                  _buildDetailRow(Icons.color_lens_outlined, 'Colour', colour.isEmpty ? 'N/A' : colour),
                  if (isLost && lostItem!.approximateValue.isNotEmpty)
                    _buildDetailRow(Icons.currency_rupee_rounded, 'Approx. Value', lostItem!.approximateValue),
                  if (!isLost && foundItem!.currentHolder.isNotEmpty)
                    _buildDetailRow(Icons.person_pin_circle_outlined, 'Current Holder', foundItem!.currentHolder),

                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Reporter Information (Privacy Protected)
                  const Text(
                    'Reporter Verification Info',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.verified_user_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verified Institutional User',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Department of Computer Science • MCA Student',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Claim Item Button for Found Items
                  if (!isLost && status.toUpperCase() == 'ACTIVE') ...[
                    CustomButton(
                      text: 'Claim This Found Item',
                      icon: Icons.assignment_turned_in_rounded,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OwnershipVerificationScreen(foundItem: foundItem!),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
