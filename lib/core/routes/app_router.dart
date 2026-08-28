import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../../features/authentication/presentation/splash_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/register_screen.dart';
import '../../features/authentication/presentation/forgot_password_screen.dart';
import '../../features/home/presentation/main_navigation_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
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
  ],
);
