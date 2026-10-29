import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_providers.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/services/firebase_service.dart';

/// One codebase, two apps: the iOS build (and the web build made with
/// `--dart-define=APP=user`) is for students and staff, and the default web
/// build is the admin dashboard (see the redirect in app_router.dart).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseService.initialize();

  final container = ProviderContainer();
  if (kIsWeb) {
    // Load a saved session before the router decides where to go.
    await container.read(repositoryProvider).checkCurrentUser();
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ReClaimApp(),
    ),
  );
}

class ReClaimApp extends StatelessWidget {
  const ReClaimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: kIsWeb && !isUserWebBuild ? '${AppStrings.appName} Admin' : AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
