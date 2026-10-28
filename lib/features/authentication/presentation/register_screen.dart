import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../verification/presentation/id_photo_picker.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedDepartment = 'Computer Science & Applications';
  String _selectedRole = 'Student';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Uint8List? _idPhoto;

  final List<String> _departments = [
    'Computer Science & Applications',
    'Electronics & Communication',
    'Mechanical Engineering',
    'Civil Engineering',
    'Electrical & Electronics',
    'Business Administration',
    'Basic Sciences & Humanities',
  ];

  final List<String> _userTypes = [
    'Student',
    'Faculty',
    'Staff',
    'Admin',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _rollNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_selectedRole == 'Admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Admin accounts cannot be created through public signup. Please contact the system administrator to obtain an Admin account.',
          ),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(currentUserProvider.notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            phone: _phoneController.text.trim(),
            department: _selectedDepartment,
            rollNumber: _rollNumberController.text.trim(),
            role: _selectedRole,
          );

      // The account exists now; a failed photo upload can be retried from Profile.
      String message = 'Registration successful! Welcome to ReClaim.';
      if (_idPhoto != null) {
        try {
          await ref.read(currentUserProvider.notifier).submitIdPhoto(_idPhoto!);
          message = 'Welcome to ReClaim! Your college ID has been sent for verification.';
        } catch (e) {
          message = 'Welcome to ReClaim! Your ID photo could not be sent; '
              'you can upload it again from your Profile.';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildIdPhotoSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.badge_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Get verified (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(idPhotoPrivacyNote, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          if (_idPhoto != null)
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(_idPhoto!, width: 72, height: 48, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                const Expanded(child: Text('College ID photo added')),
                TextButton(
                  onPressed: _isLoading ? null : () => setState(() => _idPhoto = null),
                  child: const Text('Remove'),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () async {
                      final bytes = await pickIdPhoto(context);
                      if (bytes != null && mounted) setState(() => _idPhoto = bytes);
                    },
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Add college ID photo'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  AppStrings.registerTitle,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  AppStrings.registerSubtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Full Name
                CustomTextField(
                  label: 'Full Name',
                  hint: 'e.g. Ananya Verma',
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your full name' : null,
                ),
                const SizedBox(height: 16),

                // Institutional Email
                CustomTextField(
                  label: 'Institutional Email',
                  hint: 'student@psgtech.ac.in',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (val) {
                   final email = val?.trim().toLowerCase() ?? '';

                   if (email.isEmpty) {
                     return 'Please enter your email';
                   }

                   if (!email.endsWith('@psgtech.ac.in')) {
                     return 'Please use your PSG Tech email (@psgtech.ac.in)';
                   }

                   return null;
                    },
                ),
                const SizedBox(height: 16),

                // Phone Number
                CustomTextField(
                  label: 'Phone Number',
                  hint: '+91 9876543210',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter phone number' : null,
                ),
                const SizedBox(height: 16),

                // User Type Dropdown
                const Text(
                  'User Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: _userTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Text(type),
                                if (type == 'Admin') ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppColors.accentDark.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: const Text(
                                      'Restricted',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accentDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
                if (_selectedRole == 'Admin') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.accentDark.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.admin_panel_settings_outlined,
                          color: AppColors.accentDark,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Administrator Role',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Administrator — manages users, reports, claims, and the ReClaim system.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Admin accounts cannot be created through public signup. Please contact the system administrator to obtain an Admin account.',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.accentDark,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Department Dropdown
                const Text(
                  'Department',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDepartment,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: _departments
                      .map((dept) => DropdownMenuItem(
                            value: dept,
                            child: Text(dept, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDepartment = val);
                  },
                ),
                const SizedBox(height: 16),

                // Roll Number / Staff ID
                CustomTextField(
                  label: _selectedRole == 'Student' ? 'Roll / Register Number' : 'Employee ID',
                  hint: _selectedRole == 'Student' ? 'e.g. MCA-2026-042' : 'e.g. EMP-904',
                  controller: _rollNumberController,
                  prefixIcon: const Icon(Icons.numbers_rounded),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter Roll/ID number' : null,
                ),
                const SizedBox(height: 16),

                // Password
                CustomTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please enter password';
                    if (val.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                CustomTextField(
                  label: 'Confirm Password',
                  hint: '••••••••',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (val) {
                    if (val != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Optional college ID photo for account verification
                _buildIdPhotoSection(),
                const SizedBox(height: 24),

                // Submit Register
                CustomButton(
                  text: 'Register Account',
                  isLoading: _isLoading,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
