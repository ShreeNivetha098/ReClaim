import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/custom_button.dart';
import 'id_photo_picker.dart';

/// Profile card showing the user's college ID verification and what to do next.
class IdVerificationCard extends ConsumerStatefulWidget {
  final UserModel user;

  const IdVerificationCard({super.key, required this.user});

  @override
  ConsumerState<IdVerificationCard> createState() => _IdVerificationCardState();
}

class _IdVerificationCardState extends ConsumerState<IdVerificationCard> {
  bool _isBusy = false;

  Future<void> _upload() async {
    final bytes = await pickIdPhoto(context);
    if (bytes == null) return;
    await _run(
      () => ref.read(currentUserProvider.notifier).submitIdPhoto(bytes),
      'Photo sent. An admin will review it soon.',
    );
  }

  Future<void> _withdraw() async {
    await _run(
      () => ref.read(currentUserProvider.notifier).withdrawIdPhoto(),
      'Photo withdrawn and deleted.',
    );
  }

  Future<void> _run(Future<void> Function() action, String successMessage) async {
    setState(() => _isBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(successMessage), backgroundColor: AppColors.success));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Something went wrong: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final (icon, color, title, message) = switch (user.verificationStatus) {
      AppConstants.verificationVerified => (
          Icons.verified_rounded,
          AppColors.success,
          'Verified',
          'Checked by ${user.verifiedBy ?? 'an admin'}'
              '${user.verifiedAt == null ? '' : ' on ${DateFormat('d MMM yyyy').format(user.verifiedAt!)}'}.',
        ),
      AppConstants.verificationPending => (
          Icons.hourglass_top_rounded,
          AppColors.warning,
          'Verification pending',
          'An admin will review your college ID photo. It is deleted after the review.',
        ),
      AppConstants.verificationRejected => (
          Icons.error_outline_rounded,
          AppColors.error,
          'Not verified',
          '${user.verificationNote ?? 'Your photo could not be verified.'} Please upload a clearer photo.',
        ),
      _ => (
          Icons.shield_outlined,
          AppColors.textMuted,
          'Not verified',
          idPhotoPrivacyNote,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          if (!user.isVerified) ...[
            const SizedBox(height: 12),
            if (user.verificationStatus == AppConstants.verificationPending)
              CustomButton(
                text: 'Withdraw Photo',
                type: CustomButtonType.text,
                isLoading: _isBusy,
                onPressed: _withdraw,
              )
            else
              CustomButton(
                text: user.verificationStatus == AppConstants.verificationRejected
                    ? 'Upload New Photo'
                    : 'Get Verified',
                icon: Icons.badge_outlined,
                isLoading: _isBusy,
                onPressed: _upload,
              ),
          ],
        ],
      ),
    );
  }
}
