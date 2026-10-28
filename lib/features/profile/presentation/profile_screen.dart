import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../verification/presentation/id_verification_card.dart';
import 'my_reports_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Pick up an admin's verification decision made since the app opened.
    Future.microtask(() => ref.read(currentUserProvider.notifier).refresh());
  }

  Future<void> _logout() async {
    await ref.read(currentUserProvider.notifier).logout();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final uid = user?.uid;
    final myLost = ref.watch(lostItemsProvider).value?.where((i) => i.ownerId == uid).toList() ?? const [];
    final myFound = ref.watch(foundItemsProvider).value?.where((i) => i.finderId == uid).toList() ?? const [];
    final returned = [
      ...myLost.map((i) => i.status),
      ...myFound.map((i) => i.status),
    ].where((s) => const {'RETURNED', 'CLAIMED'}.contains(s.toUpperCase())).length;

    final name = user?.name.trim().isNotEmpty == true ? user!.name : 'Student';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: const Text('Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: [
          // Header card
          FadeSlideIn(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: AppStyles.borderRadiusXl,
                boxShadow: AppStyles.floatingShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          child: Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (user?.isVerified ?? false) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                user?.role ?? 'Student',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _Stat(value: myLost.length, label: 'Lost'),
                      _divider(),
                      _Stat(value: myFound.length, label: 'Found'),
                      _divider(),
                      _Stat(value: returned, label: 'Returned'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          if (user != null) ...[
            FadeSlideIn(index: 1, child: IdVerificationCard(user: user)),
            const SizedBox(height: 18),
          ],

          FadeSlideIn(
            index: 2,
            child: _Section(
              children: [
                _InfoTile(icon: Icons.alternate_email_rounded, label: 'College email', value: user?.email ?? '—'),
                _InfoTile(icon: Icons.badge_rounded, label: 'Roll / Employee ID', value: user?.rollNumber ?? '—'),
                _InfoTile(icon: Icons.phone_rounded, label: 'Phone', value: user?.phone ?? '—'),
                _InfoTile(icon: Icons.school_rounded, label: 'Department', value: user?.department ?? '—'),
              ],
            ),
          ),
          const SizedBox(height: 18),

          FadeSlideIn(
            index: 3,
            child: _Section(
              children: [
                _MenuTile(
                  icon: Icons.inventory_2_rounded,
                  color: AppColors.primary,
                  title: 'My reports',
                  subtitle: 'Track, edit or close your reports',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyReportsScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          CustomButton(
            text: 'Log out',
            type: CustomButtonType.outlined,
            icon: Icons.logout_rounded,
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.3));
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 700),
            builder: (context, v, _) => Text(
              '$v',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final List<Widget> children;

  const _Section({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppStyles.borderRadiusLg,
        boxShadow: AppStyles.softShadow,
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 70, endIndent: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.statusActiveBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
