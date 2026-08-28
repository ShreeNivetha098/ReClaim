import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';
import 'my_reports_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Institutional Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(currentUserProvider.notifier).logout();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Profile Avatar & Name Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Student User',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${user?.role ?? 'Student'} • ${user?.department ?? 'Computer Science'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Profile Info List Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _buildProfileTile(
                    icon: Icons.email_outlined,
                    label: 'Institutional Email',
                    value: user?.email ?? 'N/A',
                  ),
                  const Divider(height: 1),
                  _buildProfileTile(
                    icon: Icons.badge_outlined,
                    label: 'Roll / Employee ID',
                    value: user?.rollNumber ?? 'N/A',
                  ),
                  const Divider(height: 1),
                  _buildProfileTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone Number',
                    value: user?.phone ?? 'N/A',
                  ),
                  const Divider(height: 1),
                  _buildProfileTile(
                    icon: Icons.school_outlined,
                    label: 'Department',
                    value: user?.department ?? 'N/A',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Navigation Actions Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.assignment_outlined, color: AppColors.primary),
                    title: const Text('My Reported Items', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('View status of your lost and found reports'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyReportsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            CustomButton(
              text: 'Log Out of ReClaim',
              type: CustomButtonType.outlined,
              icon: Icons.logout_rounded,
              onPressed: () async {
                await ref.read(currentUserProvider.notifier).logout();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textMuted),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
    );
  }
}
