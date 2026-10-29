import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../services/firebase_service.dart';
import '../services/reclaim_repository.dart';
import '../../features/authentication/presentation/splash_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/register_screen.dart';
import '../../features/authentication/presentation/forgot_password_screen.dart';
import '../../features/home/presentation/main_navigation_screen.dart';
import '../../features/admin/presentation/admin_login_screen.dart';
import '../../features/admin/presentation/admin_shell_screen.dart';
import '../../features/admin/presentation/pages/admin_overview_page.dart';
import '../../features/admin/presentation/pages/admin_users_page.dart';
import '../../features/admin/presentation/pages/admin_reports_page.dart';
import '../../features/admin/presentation/pages/admin_analytics_page.dart';
import '../../features/admin/presentation/pages/admin_claims_page.dart';
import '../../features/admin/presentation/pages/admin_unclaimed_page.dart';
import '../../features/admin/presentation/pages/admin_verification_page.dart';

/// True for the web build of the student and staff app, made with
/// `--dart-define=APP=user` (see tool/build_web.sh).
const bool isUserWebBuild = String.fromEnvironment('APP') == 'user';

/// True for the admin dashboard (the default web build); false for the
/// student and staff app (iOS or the user web build). Each build only serves
/// its own screens.
@visibleForTesting
bool isAdminBuild = kIsWeb && !isUserWebBuild;

final GoRouter appRouter = GoRouter(
  initialLocation: isAdminBuild ? AppRoutes.adminLogin : AppRoutes.splash,
  redirect: (context, state) {
    final path = state.uri.toString();
    final isNavigatingToAdmin = path.startsWith('/admin');
    final isNavigatingToAdminLogin = path == AppRoutes.adminLogin;

    if (isAdminBuild && !isNavigatingToAdmin) return AppRoutes.adminLogin;
    if (!isAdminBuild && isNavigatingToAdmin) return AppRoutes.splash;

    if (isNavigatingToAdmin && !isNavigatingToAdminLogin) {
      final firebaseUser = FirebaseService.isInitialized ? FirebaseService.auth.currentUser : null;
      final cachedUser = ReClaimRepository.currentSharedUser;

      final isAuthenticated = firebaseUser != null || cachedUser != null;
      final isAdmin = cachedUser?.role.trim().toLowerCase() == 'admin';

      if (!isAuthenticated || !isAdmin) {
        return AppRoutes.adminLogin;
      }
    }

    if (isNavigatingToAdminLogin) {
      final cachedUser = ReClaimRepository.currentSharedUser;
      if (cachedUser != null && cachedUser.role.trim().toLowerCase() == 'admin') {
        return AppRoutes.adminOverview;
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const MainNavigationScreen(initialIndex: 0),
    ),
    GoRoute(
      path: AppRoutes.search,
      builder: (context, state) => const MainNavigationScreen(initialIndex: 1),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const MainNavigationScreen(initialIndex: 4),
    ),

    // Admin Authentication Route
    GoRoute(
      path: AppRoutes.adminLogin,
      builder: (context, state) => const AdminLoginScreen(),
    ),

    // Admin Dashboard Shell Route
    ShellRoute(
      builder: (context, state, child) => AdminShellScreen(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.adminDashboard,
          builder: (context, state) => const AdminOverviewPage(),
        ),
        GoRoute(
          path: AppRoutes.adminOverview,
          builder: (context, state) => const AdminOverviewPage(),
        ),
        GoRoute(
          path: AppRoutes.adminUsers,
          builder: (context, state) => const AdminUsersPage(),
        ),
        GoRoute(
          path: AppRoutes.adminLostReports,
          builder: (context, state) => const AdminReportsPage(initialTabIndex: 0),
        ),
        GoRoute(
          path: AppRoutes.adminFoundReports,
          builder: (context, state) => const AdminReportsPage(initialTabIndex: 1),
        ),
        GoRoute(
          path: AppRoutes.adminClaims,
          builder: (context, state) => const AdminClaimsPage(),
        ),
        GoRoute(
          path: AppRoutes.adminClaimed,
          builder: (context, state) => const AdminClaimsPage(),
        ),
        GoRoute(
          path: AppRoutes.adminUnclaimed,
          builder: (context, state) => const AdminUnclaimedPage(),
        ),
        GoRoute(
          path: AppRoutes.adminVerification,
          builder: (context, state) => const AdminVerificationPage(),
        ),
        GoRoute(
          path: AppRoutes.adminActivity,
          builder: (context, state) => const AdminOverviewPage(),
        ),
        GoRoute(
          path: AppRoutes.adminAnalytics,
          builder: (context, state) => const AdminAnalyticsPage(),
        ),
      ],
    ),
  ],
);
