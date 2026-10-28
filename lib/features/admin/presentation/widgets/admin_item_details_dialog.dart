import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/lost_item_model.dart';
import '../../../../shared/models/found_item_model.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../shared/widgets/item_image.dart';

class AdminItemDetailsDialog extends ConsumerWidget {
  final dynamic item;
  final bool isLost;
  final Function(String action) onAction;

  const AdminItemDetailsDialog({
    super.key,
    required this.item,
    required this.isLost,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = item.itemName;
    final category = item.category;
    final description = item.description;
    final location = isLost ? (item as LostItemModel).locationLost : (item as FoundItemModel).locationFound;
    final date = isLost ? (item as LostItemModel).dateLost : (item as FoundItemModel).dateFound;
    final imageUrl = item.imageUrl;
    final status = item.status;
    final reporterName = item.reporterName;
    final reporterEmail = item.reporterEmail;
    final createdAt = item.createdAt;
    final updatedAt = item.updatedAt;

    final displayName = (reporterName != null && reporterName.toString().trim().isNotEmpty)
        ? reporterName
        : 'Unknown user';
    final displayEmail = (reporterEmail != null && reporterEmail.toString().trim().isNotEmpty)
        ? reporterEmail
        : 'No email provided';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 850),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLost ? AppColors.primary : AppColors.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isLost ? 'LOST REPORT' : 'FOUND REPORT',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Report Details',
                      style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Layout: Image and Info side-by-side on larger screens, stacked on small
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 500) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: _buildImageSection(imageUrl, isLost, context)),
                              const SizedBox(width: 24),
                              Expanded(flex: 3, child: _buildInfoSection(title, category, status, date, location, createdAt, updatedAt, isLost)),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImageSection(imageUrl, isLost, context),
                            const SizedBox(height: 24),
                            _buildInfoSection(title, category, status, date, location, createdAt, updatedAt, isLost),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    // Description
                    _buildSectionTitle('Description'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        description.isEmpty ? 'No description provided.' : description,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Reporter Info
                    _buildSectionTitle('Reporter Information'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.background,
                            child: Icon(Icons.person_outline, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(displayName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(displayEmail, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Claims Information
                    _buildSectionTitle('Claim Information'),
                    const SizedBox(height: 12),
                    _buildClaimsSection(ref),
                  ],
                ),
              ),
            ),

            // Footer (Admin Actions)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Text('Admin Actions:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const Spacer(),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (status.toUpperCase() == 'ACTIVE')
                        _buildActionButton('Mark Unclaimed', 'UNCLAIMED', AppColors.statusUnclaimedText, AppColors.statusUnclaimedBg),
                      if (status.toUpperCase() != 'CLOSED')
                        _buildActionButton('Close Report', 'CLOSED', AppColors.statusClosedText, AppColors.statusClosedBg),
                      if (status.toUpperCase() == 'CLAIMED')
                        _buildActionButton('Mark Returned', 'RETURNED', AppColors.statusReturnedText, AppColors.statusReturnedBg),
                      _buildActionButton('Delete', 'DELETE', Colors.white, AppColors.error),
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

  Widget _buildImageSection(String? imageUrl, bool isLost, BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: (imageUrl != null && imageUrl.isNotEmpty)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      child: Stack(
                        children: [
                          InteractiveViewer(
                            child: ItemImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.contain,
                              placeholder: (context) => const Center(child: CircularProgressIndicator()),
                              error: (context) => const Center(child: Icon(Icons.error, color: AppColors.error)),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: ItemImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context) => const Center(child: CircularProgressIndicator()),
                  error: (context) => _buildNoImage(isLost),
                ),
              ),
            )
          : _buildNoImage(isLost),
    );
  }

  Widget _buildNoImage(bool isLost) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isLost ? Icons.search : Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text('No Image Available', style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String category, String status, DateTime date, String location, DateTime createdAt, DateTime updatedAt, bool isLost) {
    final countdownLabel = DateFormatter.getUnclaimedCountdownLabel(createdAt, status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        _statusChip(status),
        const SizedBox(height: 16),
        _buildInfoRow('Report ID:', item.id),
        _buildInfoRow('Category:', category),
        _buildInfoRow(isLost ? 'Date Lost:' : 'Date Found:', DateFormat('MMM d, yyyy').format(date)),
        _buildInfoRow('Location:', location),
        const SizedBox(height: 8),
        _buildInfoRow('Created:', DateFormat('MMM d, yyyy h:mm a').format(createdAt), isSmall: true),
        _buildInfoRow('Updated:', DateFormat('MMM d, yyyy h:mm a').format(updatedAt), isSmall: true),
        if (countdownLabel != null)
          _buildInfoRow('Deadline:', countdownLabel, isSmall: true),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isSmall = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isSmall ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isSmall ? 12 : 13,
                color: isSmall ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg, fg;
    switch (status.toUpperCase()) {
      case 'ACTIVE': bg = AppColors.statusActiveBg; fg = AppColors.statusActiveText; break;
      case 'CLAIMED': bg = AppColors.statusClaimedBg; fg = AppColors.statusClaimedText; break;
      case 'UNCLAIMED': bg = AppColors.statusUnclaimedBg; fg = AppColors.statusUnclaimedText; break;
      case 'RETURNED': bg = AppColors.statusReturnedBg; fg = AppColors.statusReturnedText; break;
      case 'CLOSED': bg = AppColors.statusClosedBg; fg = AppColors.statusClosedText; break;
      default: bg = AppColors.statusMatchedBg; fg = AppColors.statusMatchedText;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
    );
  }

  Widget _buildClaimsSection(WidgetRef ref) {
    final claimsAsync = ref.watch(claimsProvider);
    return claimsAsync.when(
      data: (allClaims) {
        // Filter claims for this specific item
        final itemClaims = allClaims.where((c) {
          return c.itemId == item.id || c.foundItemId == item.id || c.lostItemId == item.id;
        }).toList();

        if (itemClaims.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text('No claim submitted.', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 14)),
          );
        }

        return Column(
          children: itemClaims.map((claim) => _buildClaimCard(claim)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading claims: $e'),
    );
  }

  Widget _buildClaimCard(dynamic claim) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Claim ID: ${claim.id.substring(0, 8)}...', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textMuted)),
              const Spacer(),
              _statusChip(claim.status),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Claimant ID:', claim.claimantId),
          _buildInfoRow('Date Submitted:', DateFormat('MMM d, yyyy').format(claim.createdAt)),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          _buildInfoRow('Verification Answer:', claim.verificationAnswer),
          if (claim.uniqueMarks.isNotEmpty) _buildInfoRow('Unique Marks:', claim.uniqueMarks),
          if (claim.contentsInside.isNotEmpty) _buildInfoRow('Contents:', claim.contentsInside),
          if (claim.additionalInfo.isNotEmpty) _buildInfoRow('Additional Info:', claim.additionalInfo),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, String action, Color fg, Color bg) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => onAction(action),
      child: Text(text, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}
