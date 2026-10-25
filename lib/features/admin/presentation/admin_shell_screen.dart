import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/routes/app_routes.dart';

/// The navigation item definition for the admin sidebar.
class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

const _navItems = [
  _NavItem(
    label: 'Overview',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
    route: AppRoutes.adminOverview,
  ),
  _NavItem(
    label: 'Users',
    icon: Icons.people_outline_rounded,
    activeIcon: Icons.people_rounded,
    route: AppRoutes.adminUsers,
  ),
  _NavItem(
    label: 'Reports',
    icon: Icons.assignment_outlined,
    activeIcon: Icons.assignment_rounded,
    route: AppRoutes.adminReports,
  ),
  _NavItem(
    label: 'Claims',
    icon: Icons.verified_outlined,
    activeIcon: Icons.verified_rounded,
    route: AppRoutes.adminClaims,
  ),
  _NavItem(
    label: 'Activity',
    icon: Icons.history_outlined,
    activeIcon: Icons.history_rounded,
    route: AppRoutes.adminActivity,
  ),
  _NavItem(
    label: 'Analytics',
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart_rounded,
    route: AppRoutes.adminAnalytics,
  ),
];

/// Responsive admin dashboard shell with sidebar navigation.
/// The [child] parameter is provided by the go_router ShellRoute.
class AdminShellScreen extends ConsumerStatefulWidget {
  final Widget child;

  const AdminShellScreen({super.key, required this.child});

  @override
  ConsumerState<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends ConsumerState<AdminShellScreen> {
  bool _isSidebarCollapsed = false;

  int _selectedIndex(String location) {
    if (location.startsWith(AppRoutes.adminOverview) || location == AppRoutes.adminDashboard) {
      return 0;
    }
    if (location.startsWith(AppRoutes.adminUsers)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.adminLostReports) ||
        location.startsWith(AppRoutes.adminFoundReports) ||
        location.startsWith(AppRoutes.adminUnclaimed) ||
        location.contains('reports')) {
      return 2;
    }
    if (location.startsWith(AppRoutes.adminClaims) || location.startsWith(AppRoutes.adminClaimed)) {
      return 3;
    }
    if (location.startsWith(AppRoutes.adminActivity)) {
      return 4;
    }
    if (location.startsWith(AppRoutes.adminAnalytics)) {
      return 5;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768 && screenWidth < 1100;
    final isMobile = screenWidth < 768;
    final currentLocation = GoRouterState.of(context).uri.toString();
    final selectedIdx = _selectedIndex(currentLocation);

    // On mobile, use a drawer instead of permanent sidebar
    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildTopBar(user, isMobile: true),
        drawer: _buildDrawer(user, selectedIdx),
        body: widget.child,
      );
    }

    // Desktop/Tablet: permanent sidebar
    final sidebarWidth = _isSidebarCollapsed
        ? 72.0
        : (isTablet ? 220.0 : 260.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: sidebarWidth,
            child: _buildSidebar(user, selectedIdx, isCollapsed: _isSidebarCollapsed),
          ),
          // Main content area
          Expanded(
            child: Scaffold(
              backgroundColor: AppColors.background,
              appBar: _buildTopBar(user, isMobile: false),
              body: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTopBar(dynamic user, {required bool isMobile}) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      toolbarHeight: 64,
      automaticallyImplyLeading: isMobile,
      title: Row(
        children: [
          if (!isMobile)
            IconButton(
              icon: Icon(
                _isSidebarCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
              },
            ),
          if (!isMobile) const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getPageTitle(GoRouterState.of(context).uri.toString()),
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
          tooltip: 'Refresh data',
          onPressed: () {
            ref.read(lostItemsProvider.notifier).loadLostItems();
            ref.read(foundItemsProvider.notifier).loadFoundItems();
            ref.read(claimsProvider.notifier).loadClaims();
          },
        ),
        const SizedBox(width: 8),
        // Admin user chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary,
                child: Text(
                  user?.name.isNotEmpty == true ? user.name[0].toUpperCase() : 'A',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                user?.name ?? 'Admin',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
    );
  }

  Widget _buildSidebar(dynamic user, int selectedIdx, {required bool isCollapsed}) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(right: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        children: [
          // Brand header
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 20),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.find_in_page_rounded, color: Colors.white, size: 20),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Text(
                    'ReClaim',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFF1E293B)),

          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = index == selectedIdx;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        context.go(item.route);
                        // Close drawer on mobile
                        if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
                          Navigator.pop(context);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: EdgeInsets.symmetric(
                          horizontal: isCollapsed ? 12 : 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? item.activeIcon : item.icon,
                              color: isSelected ? AppColors.primaryLight : const Color(0xFF94A3B8),
                              size: 22,
                            ),
                            if (!isCollapsed) ...[
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Logout
          Container(height: 1, color: const Color(0xFF1E293B)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  await ref.read(currentUserProvider.notifier).logout();
                  if (mounted) context.go(AppRoutes.adminLogin);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCollapsed ? 12 : 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
                      if (!isCollapsed) ...[
                        const SizedBox(width: 14),
                        Text(
                          'Logout',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Drawer _buildDrawer(dynamic user, int selectedIdx) {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: _buildSidebar(user, selectedIdx, isCollapsed: false),
    );
  }

  String _getPageTitle(String location) {
    if (location.contains('overview')) return 'Dashboard Overview';
    if (location.contains('users')) return 'User Management';
    if (location.contains('reports')) return 'Report Management';
    if (location.contains('unclaimed')) return 'Unclaimed Items';
    if (location.contains('claim')) return 'Claims & History';
    if (location.contains('activity')) return 'Activity Logs';
    if (location.contains('analytics')) return 'Analytics & Insights';
    return 'Admin Dashboard';
  }
}
