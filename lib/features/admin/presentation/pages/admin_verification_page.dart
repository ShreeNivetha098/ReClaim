import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/id_photo_service.dart';
import '../../../../shared/models/user_model.dart';
import '../../providers/admin_providers.dart';

/// Admin page for reviewing college ID photos. Verifying or rejecting a user
/// deletes their photo in the same step.
class AdminVerificationPage extends ConsumerWidget {
  const AdminVerificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'College ID verification',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Compare each photo with the name and roll number. The photo is deleted when you verify or reject.',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final pending = users
                    .where((u) => u.verificationStatus == AppConstants.verificationPending)
                    .toList();
                if (pending.isEmpty) {
                  return Center(
                    child: Text('No ID photos waiting for review.',
                        style: GoogleFonts.inter(color: AppColors.textSecondary)),
                  );
                }
                return ListView.separated(
                  itemCount: pending.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (_, index) => _PendingUserCard(user: pending[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingUserCard extends ConsumerStatefulWidget {
  final UserModel user;

  const _PendingUserCard({required this.user});

  @override
  ConsumerState<_PendingUserCard> createState() => _PendingUserCardState();
}

class _PendingUserCardState extends ConsumerState<_PendingUserCard> {
  late final Future<Uint8List?> _photo = IdPhotoService.load(widget.user.uid);
  bool _isBusy = false;

  Future<void> _review({required bool approve}) async {
    String? note;
    if (!approve) {
      note = await _askRejectReason();
      if (note == null || !mounted) return;
    }

    setState(() => _isBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    final admin = ref.read(currentUserProvider);
    final adminName = admin?.name.trim().isNotEmpty == true ? admin!.name : 'Admin';
    try {
      await ref.read(repositoryProvider).reviewIdVerification(
            user: widget.user,
            approve: approve,
            adminName: adminName,
            note: note,
          );
      await ref.read(adminRepositoryProvider).logActivity(
            actorId: admin?.uid ?? '',
            actorName: adminName,
            action: approve ? 'USER_VERIFIED' : 'USER_VERIFICATION_REJECTED',
            targetType: 'user',
            targetId: widget.user.uid,
            details: approve ? 'College ID verified' : 'Rejected: $note',
          );
      messenger.showSnackBar(SnackBar(
        content: Text(approve
            ? '${widget.user.name} is verified. Photo deleted.'
            : '${widget.user.name} was asked for a new photo. Photo deleted.'),
        backgroundColor: approve ? AppColors.success : AppColors.warning,
      ));
      await ref.read(adminUsersProvider.notifier).loadUsers();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $e'), backgroundColor: AppColors.error));
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<String?> _askRejectReason() {
    final controller = TextEditingController(text: 'The photo is unclear.');
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reason for rejecting'),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'e.g. Name does not match the ID card'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 320,
              height: 200,
              color: AppColors.background,
              child: FutureBuilder<Uint8List?>(
                future: _photo,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final bytes = snapshot.data;
                  if (bytes == null) {
                    return const Center(child: Text('Photo not found'));
                  }
                  return Image.memory(bytes, fit: BoxFit.contain);
                },
              ),
            ),
          ),
          SizedBox(
            width: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _detail('Email', user.email),
                _detail('Roll / ID', user.rollNumber),
                _detail('Department', user.department),
                _detail('Role', user.role),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isBusy ? null : () => _review(approve: true),
                      icon: const Icon(Icons.verified_rounded, size: 18),
                      label: const Text('Verify'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _isBusy ? null : () => _review(approve: false),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: '$label: ', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          TextSpan(
            text: value.isEmpty ? '—' : value,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );
  }
}
