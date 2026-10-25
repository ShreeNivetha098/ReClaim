import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/services/firebase_service.dart';
import 'core/services/push_notification_service.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseService.initialize();

  runApp(
    const ProviderScope(
      child: ReClaimApp(),
    ),
  );

  // Initialize notifications asynchronously so startup and UI are never blocked.
  if (FirebaseService.isInitialized) {
    PushNotificationService.initialize().catchError((Object error, StackTrace stackTrace) {
      debugPrint('PushNotificationService initialization error: $error');
    });
  }
}

class ReClaimApp extends StatelessWidget {
  const ReClaimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}