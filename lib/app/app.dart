import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/home/presentation/screens/home_shell.dart';
import '../features/onboarding/presentation/screens/onboarding_chat_screen.dart';
import '../shared/providers/app_state_provider.dart';

class SushasthoApp extends ConsumerWidget {
  const SushasthoApp({
    super.key,
    this.startupError,
  });

  final Object? startupError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (startupError != null) {
      return MaterialApp(
        title: 'Sushastho.ai',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: _ConfigurationErrorScreen(message: startupError.toString()),
      );
    }

    final profileState = ref.watch(userProfileProvider);

    return MaterialApp(
      title: 'Sushastho.ai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: profileState.when(
        data: (profile) => profile == null ? const OnboardingChatScreen() : const HomeShell(),
        loading: () => const _SplashScreen(),
        error: (error, stackTrace) => const OnboardingChatScreen(),
      ),
    );
  }
}

class _ConfigurationErrorScreen extends StatelessWidget {
  const _ConfigurationErrorScreen({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: Color(0xFFFFEFEF),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 34,
                  color: Color(0xFFD83A3A),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Firebase setup complete na',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'App চালাতে Firebase setup দরকার। Android-এ google-services.json আর Gradle Firebase plugin ঠিকমতো থাকতে হবে।',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFD83A3A),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF4FBF6),
              Colors.white,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Color(0xFFEAF8F0),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 34,
                  color: Color(0xFF3D9B67),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Sushastho.ai',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF163020),
                ),
              ),
              SizedBox(height: 12),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
