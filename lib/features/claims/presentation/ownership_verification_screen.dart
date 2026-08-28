import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/models/found_item_model.dart';
import '../../../shared/models/lost_item_model.dart';
import '../../../shared/models/claim_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class OwnershipVerificationScreen extends ConsumerStatefulWidget {
  final FoundItemModel foundItem;
  final LostItemModel? lostItem;

  const OwnershipVerificationScreen({
    super.key,
    required this.foundItem,
    this.lostItem,
  });

  @override
  ConsumerState<OwnershipVerificationScreen> createState() => _OwnershipVerificationScreenState();
}

class _OwnershipVerificationScreenState extends ConsumerState<OwnershipVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _uniqueMarksController = TextEditingController();
  final _contentsController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _uniqueMarksController.dispose();
    _contentsController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitClaim() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(currentUserProvider);

      final newClaim = ClaimModel(
        id: '',
        itemId: widget.foundItem.id,
        lostItemId: widget.lostItem?.id ?? '',
        foundItemId: widget.foundItem.id,
        claimantId: user?.uid ?? 'guest',
        verificationAnswer: _reasonController.text.trim(),
        uniqueMarks: _uniqueMarksController.text.trim(),
        contentsInside: _contentsController.text.trim(),
        additionalInfo: _additionalInfoController.text.trim(),
        status: 'PENDING',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(claimsProvider.notifier).submitClaim(newClaim);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 54),
            title: const Text('Claim Submitted Successfully'),
            content: const Text(
              'Your ownership verification details have been submitted securely. The campus administrator and security office will review your claim and notify you once approved.',
              textAlign: TextAlign.center,
            ),
            actions: [
              CustomButton(
                text: 'Done',
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Pop claim screen
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting claim: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ownership Verification'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Claim Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.secondary),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security_rounded, color: AppColors.secondary, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Claiming Item:',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            Text(
                              widget.foundItem.itemName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Found at ${widget.foundItem.locationFound}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Verification Questions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Please answer these questions carefully to prove your ownership to campus security.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),

                // Question 1: Reason / Why
                CustomTextField(
                  label: '1. Why do you believe this is your item? *',
                  hint: 'e.g. I lost my wallet on Tuesday at Central Library reading room...',
                  controller: _reasonController,
                  maxLines: 2,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please answer this verification question' : null,
                ),
                const SizedBox(height: 16),

                // Question 2: Unique Marks / Serials
                CustomTextField(
                  label: '2. Unique identifying marks or serial numbers',
                  hint: 'e.g. Small scratch on bottom right, serial #991EX, initial "AV" written...',
                  controller: _uniqueMarksController,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Question 3: Contents Inside
                CustomTextField(
                  label: '3. What was inside or attached to the item?',
                  hint: 'e.g. Student ID card with Roll No MCA-2026-042, metro pass, key chain...',
                  controller: _contentsController,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Question 4: Additional Info
                CustomTextField(
                  label: '4. Any additional supporting information',
                  hint: 'e.g. Purchase receipt available, lock combination code, etc.',
                  controller: _additionalInfoController,
                  maxLines: 2,
                ),
                const SizedBox(height: 28),

                // Submit Claim Button
                CustomButton(
                  text: 'Submit Ownership Claim',
                  type: CustomButtonType.secondary,
                  isLoading: _isSubmitting,
                  onPressed: _handleSubmitClaim,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
