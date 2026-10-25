import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../shared/models/claim_model.dart';
import '../../providers/admin_providers.dart';

/// Admin claims management page — approve/reject claims, view history.
class AdminClaimsPage extends ConsumerStatefulWidget {
  const AdminClaimsPage({super.key});

  @override
  ConsumerState<AdminClaimsPage> createState() => _AdminClaimsPageState();
}

class _AdminClaimsPageState extends ConsumerState<AdminClaimsPage> {
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final claimsAsync = ref.watch(claimsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildFilterChip('All'),
              _buildFilterChip('PENDING'),
              _buildFilterChip('APPROVED'),
              _buildFilterChip('REJECTED'),
            ],
          ),
          const SizedBox(height: 20),

          // Claims table
          Expanded(
            child: claimsAsync.when(
              data: (claims) {
                final filtered = _statusFilter == 'All'
                    ? claims
                    : claims.where((c) => c.status.toUpperCase() == _statusFilter).toList();
                if (filtered.isEmpty) return _emptyState();
                return _buildClaimsTable(filtered);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _statusFilter == label;
    return FilterChip(
      label: Text(label, style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      )),
      selected: isSelected,
      onSelected: (_) => setState(() => _statusFilter = label),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildClaimsTable(List<ClaimModel> claims) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.background),
              columnSpacing: 24,
              headingTextStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              dataTextStyle: GoogleFonts.inter(fontSize: 13),
              columns: const [
                DataColumn(label: Text('CLAIM ID')),
                DataColumn(label: Text('CLAIMANT ID')),
                DataColumn(label: Text('FOUND ITEM')),
                DataColumn(label: Text('LOST ITEM')),
                DataColumn(label: Text('VERIFICATION')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('DATE')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: claims.map((claim) => _buildClaimRow(claim)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildClaimRow(ClaimModel claim) {
    return DataRow(cells: [
      DataCell(Text(
        claim.id.length > 8 ? '${claim.id.substring(0, 8)}...' : claim.id,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      )),
      DataCell(Text(claim.claimantId.length > 12 ? '${claim.claimantId.substring(0, 12)}...' : claim.claimantId)),
      DataCell(Text(claim.foundItemId.length > 12 ? '${claim.foundItemId.substring(0, 12)}...' : claim.foundItemId)),
      DataCell(Text(claim.lostItemId.isNotEmpty
          ? (claim.lostItemId.length > 12 ? '${claim.lostItemId.substring(0, 12)}...' : claim.lostItemId)
          : 'N/A')),
      DataCell(
        Tooltip(
          message: claim.verificationAnswer,
          child: SizedBox(
            width: 160,
            child: Text(
              claim.verificationAnswer,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ),
      ),
      DataCell(_statusChip(claim.status)),
      DataCell(Text(DateFormat('MMM d, yyyy').format(claim.createdAt))),
      DataCell(
        claim.status == 'PENDING'
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                _actionButton('Approve', AppColors.secondary, Icons.check, () => _updateClaim(claim, 'APPROVED')),
                const SizedBox(width: 6),
                _actionButton('Reject', AppColors.error, Icons.close, () => _updateClaim(claim, 'REJECTED')),
              ])
            : Text(claim.status, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
      ),
    ]);
  }

  Widget _actionButton(String label, Color color, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Future<void> _updateClaim(ClaimModel claim, String newStatus) async {
    await ref.read(claimsProvider.notifier).updateClaimStatus(claim.id, newStatus);
    final currentUser = ref.read(currentUserProvider);
    await ref.read(adminRepositoryProvider).logActivity(
      actorId: currentUser?.uid ?? '',
      actorName: currentUser?.name ?? '',
      action: 'CLAIM_$newStatus',
      targetType: 'claim',
      targetId: claim.id,
      details: 'Claim for found item ${claim.foundItemId}',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Claim $newStatus'),
          backgroundColor: newStatus == 'APPROVED' ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Widget _statusChip(String status) {
    Color bg, fg;
    switch (status.toUpperCase()) {
      case 'PENDING': bg = AppColors.statusMatchedBg; fg = AppColors.statusMatchedText; break;
      case 'APPROVED': bg = AppColors.statusReturnedBg; fg = AppColors.statusReturnedText; break;
      case 'REJECTED': bg = const Color(0xFFFEE2E2); fg = const Color(0xFFDC2626); break;
      default: bg = AppColors.statusClosedBg; fg = AppColors.statusClosedText;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_outlined, size: 56, color: AppColors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            _statusFilter == 'All' ? 'No claims found' : 'No $_statusFilter claims',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
