import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/reclaim_repository.dart';
import '../../../../shared/models/user_model.dart';
import '../../providers/admin_providers.dart';

/// Admin user management page with searchable, filterable user table.
class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  String _searchQuery = '';
  String _roleFilter = 'All';
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final currentUser = ref.watch(currentUserProvider);
    final currentAuthUid = (FirebaseService.isInitialized ? FirebaseService.auth.currentUser?.uid : null) ??
        ReClaimRepository.currentSharedUser?.uid ??
        currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + filters
          _buildFilters(),
          const SizedBox(height: 20),

          // User table
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final filtered = _filterUsers(users);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 56, color: AppColors.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('No users found', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return _buildUserTable(filtered, currentAuthUid);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Search
        SizedBox(
          width: 300,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by name, email, or ID...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        // Role filter
        _buildFilterDropdown(
          value: _roleFilter,
          items: ['All', 'Student', 'Faculty', 'Staff', 'Admin'],
          onChanged: (v) => setState(() => _roleFilter = v!),
          label: 'Role',
        ),
        // Status filter
        _buildFilterDropdown(
          value: _statusFilter,
          items: ['All', 'Active', 'Inactive'],
          onChanged: (v) => setState(() => _statusFilter = v!),
          label: 'Status',
        ),
        // Refresh
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          tooltip: 'Refresh',
          onPressed: () => ref.read(adminUsersProvider.notifier).loadUsers(),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text('$label: $e', style: GoogleFonts.inter(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    return users.where((u) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!u.name.toLowerCase().contains(q) &&
            !u.email.toLowerCase().contains(q) &&
            !u.rollNumber.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_roleFilter != 'All' && u.role != _roleFilter) return false;
      if (_statusFilter == 'Active' && !u.isActive) return false;
      if (_statusFilter == 'Inactive' && u.isActive) return false;
      return true;
    }).toList();
  }

  Widget _buildUserTable(List<UserModel> users, String? currentAuthUid) {
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
              columnSpacing: 28,
              headingTextStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
              dataTextStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
              columns: const [
                DataColumn(label: Text('NAME')),
                DataColumn(label: Text('EMAIL')),
                DataColumn(label: Text('DEPARTMENT')),
                DataColumn(label: Text('ROLL / ID')),
                DataColumn(label: Text('ROLE')),
                DataColumn(label: Text('COLLEGE ID')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: users.map((u) => _buildUserRow(u, currentAuthUid)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildUserRow(UserModel user, String? currentAuthUid) {
    final isSelf = currentAuthUid != null && currentAuthUid.isNotEmpty && user.uid == currentAuthUid;

    return DataRow(
      cells: [
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
            Text(user.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            if (isSelf) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'You',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ],
          ],
        )),
        DataCell(Text(user.email)),
        DataCell(Text(user.department)),
        DataCell(Text(user.rollNumber)),
        DataCell(_buildRoleChip(user.role)),
        DataCell(_buildVerificationChip(user.verificationStatus)),
        DataCell(_buildStatusChip(user.isActive)),
        DataCell(
          isSelf
              ? Tooltip(
                  message: 'You cannot modify your own administrator account.',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: AppColors.textMuted.withValues(alpha: 0.35),
                        onPressed: null,
                      ),
                      IconButton(
                        icon: Icon(
                          user.isActive ? Icons.block_rounded : Icons.check_circle_outline,
                          size: 18,
                        ),
                        color: AppColors.textMuted.withValues(alpha: 0.35),
                        onPressed: null,
                      ),
                    ],
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit role',
                      color: AppColors.primary,
                      onPressed: () => _showEditRoleDialog(user),
                    ),
                    IconButton(
                      icon: Icon(
                        user.isActive ? Icons.block_rounded : Icons.check_circle_outline,
                        size: 18,
                      ),
                      tooltip: user.isActive ? 'Deactivate' : 'Activate',
                      color: user.isActive ? AppColors.error : AppColors.secondary,
                      onPressed: () => _toggleUserStatus(user),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildVerificationChip(String status) {
    final (label, color) = switch (status) {
      'VERIFIED' => ('Verified', AppColors.success),
      'PENDING' => ('Pending', AppColors.warning),
      'REJECTED' => ('Rejected', AppColors.error),
      _ => ('Not verified', AppColors.textMuted),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == 'VERIFIED') ...[
          Icon(Icons.verified_rounded, size: 16, color: color),
          const SizedBox(width: 4),
        ],
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _buildRoleChip(String role) {
    Color bg, fg;
    switch (role) {
      case 'Admin':
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF7C3AED);
        break;
      case 'Faculty':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        break;
      case 'Staff':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        break;
      default:
        bg = AppColors.statusActiveBg;
        fg = AppColors.statusActiveText;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(role, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.statusReturnedBg : AppColors.statusClosedBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isActive ? AppColors.statusReturnedText : AppColors.statusClosedText,
        ),
      ),
    );
  }

  void _showEditRoleDialog(UserModel user) {
    final currentAuthUid = (FirebaseService.isInitialized ? FirebaseService.auth.currentUser?.uid : null) ??
        ReClaimRepository.currentSharedUser?.uid ??
        ref.read(currentUserProvider)?.uid;
    if (currentAuthUid != null && user.uid == currentAuthUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot modify your own administrator account.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    String selectedRole = user.role;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Update Role for ${user.name}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          content: StatefulBuilder(
            builder: (ctx, setDialogState) {
              return DropdownButton<String>(
                value: selectedRole,
                isExpanded: true,
                items: ['Student', 'Faculty', 'Staff', 'Admin']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedRole = v);
                },
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(adminUsersProvider.notifier).updateUserRole(user.uid, selectedRole);
                // Log activity
                final currentUser = ref.read(currentUserProvider);
                await ref.read(adminRepositoryProvider).logActivity(
                  actorId: currentUser?.uid ?? '',
                  actorName: currentUser?.name ?? '',
                  action: 'USER_ROLE_UPDATED',
                  targetType: 'user',
                  targetId: user.uid,
                  details: 'Changed role from ${user.role} to $selectedRole',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Role updated to $selectedRole'), backgroundColor: AppColors.success),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    final currentAuthUid = (FirebaseService.isInitialized ? FirebaseService.auth.currentUser?.uid : null) ??
        ReClaimRepository.currentSharedUser?.uid ??
        ref.read(currentUserProvider)?.uid;
    if (currentAuthUid != null && user.uid == currentAuthUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot modify your own administrator account.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final newStatus = !user.isActive;
    await ref.read(adminUsersProvider.notifier).toggleUserActive(user.uid, newStatus);
    final currentUser = ref.read(currentUserProvider);
    await ref.read(adminRepositoryProvider).logActivity(
      actorId: currentUser?.uid ?? '',
      actorName: currentUser?.name ?? '',
      action: newStatus ? 'USER_ACTIVATED' : 'USER_DEACTIVATED',
      targetType: 'user',
      targetId: user.uid,
      details: '${user.name} (${user.email})',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} ${newStatus ? 'activated' : 'deactivated'}'),
          backgroundColor: newStatus ? AppColors.success : AppColors.warning,
        ),
      );
    }
  }
}
