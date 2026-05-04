import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/home/presentation/screens/home_shell.dart';
import '../features/onboarding/presentation/screens/onboarding_chat_screen.dart';
import '../shared/providers/app_state_provider.dart';
import '../data/models/app_settings.dart';

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
    final settings = ref.watch(appSettingsProvider).asData?.value ?? const AppSettings();

    return MaterialApp(
      title: 'Sushastho.ai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: switch (settings.themeMode) {
        AppThemeModePreference.system => ThemeMode.system,
        AppThemeModePreference.light => ThemeMode.light,
        AppThemeModePreference.dark => ThemeMode.dark,
      },
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF4FBF6),
              Color(0xFFF7FCF8),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            tween: Tween(begin: 0.94, end: 1),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFEAF8F0), Color(0xFFD8F3DC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(45, 106, 79, 0.14),
                        blurRadius: 24,
                        spreadRadius: -4,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 38,
                    color: Color(0xFF2D8A5B),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Sushastho.ai',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF163020),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ব্যক্তিগত স্বাস্থ্য সহচর',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6A8D78),
                  ),
                ),
                const SizedBox(height: 18),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
