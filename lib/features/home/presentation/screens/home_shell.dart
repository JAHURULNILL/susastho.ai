import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_design.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../providers/home_provider.dart';
import '../../../planner/presentation/screens/journey_screen.dart';
import '../../../planner/presentation/screens/weekly_planner_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../scanner/presentation/screens/scanner_screen.dart';
import 'home_screen.dart';

class NavigationTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

final navigationTabProvider = NotifierProvider<NavigationTabNotifier, int>(
  NavigationTabNotifier.new,
);

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationTabProvider);
    final profile = ref.watch(userProfileProvider).asData?.value;
    final settings = ref.watch(appSettingsProvider).asData?.value;
    if (profile != null) {
      ref.watch(_activityTrackingBootstrapProvider);
      if (settings?.wearableSyncEnabled ?? true) {
        ref.watch(_healthSyncBootstrapProvider);
      }
      ref.watch(_offlineSyncBootstrapProvider);
      if (settings?.notificationsEnabled ?? true) {
        ref.watch(_smartNotificationBootstrapProvider);
      }
    }

    return Scaffold(
      body: _buildPage(currentIndex, ref),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.92)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(18, 48, 31, 0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Color.fromRGBO(45, 106, 79, 0.16),
                      blurRadius: 28,
                      spreadRadius: -8,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 88,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                    child: Row(
                  children: [
                    Expanded(
                      child: _NavItem(
                        label: 'হোম',
                        icon: Icons.grid_view_rounded,
                        selected: currentIndex == 0,
                        onTap: () => ref.read(navigationTabProvider.notifier).setTab(0),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        label: 'প্ল্যান',
                        icon: Icons.menu_book_rounded,
                        selected: currentIndex == 1,
                        onTap: () => ref.read(navigationTabProvider.notifier).setTab(1),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: GestureDetector(
                          onTap: () => ref.read(navigationTabProvider.notifier).setTab(2),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryLight],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromRGBO(27, 94, 59, 0.22),
                                  blurRadius: 16,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_a_photo_rounded,
                              color: AppColors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        label: 'জার্নি',
                        icon: Icons.bar_chart_rounded,
                        selected: currentIndex == 3,
                        onTap: () => ref.read(navigationTabProvider.notifier).setTab(3),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        label: 'প্রোফাইল',
                        icon: Icons.person_rounded,
                        selected: currentIndex == 4,
                        onTap: () => ref.read(navigationTabProvider.notifier).setTab(4),
                      ),
                    ),
                  ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(int index, WidgetRef ref) {
    switch (index) {
      case 0:
        return HomeScreen(
          onOpenScan: () => ref.read(navigationTabProvider.notifier).setTab(2),
        );
      case 1:
        return const WeeklyPlannerScreen();
      case 2:
        return const ScannerScreen();
      case 3:
        return const JourneyScreen();
      case 4:
        return const ProfileScreen();
      default:
        return HomeScreen(
          onOpenScan: () => ref.read(navigationTabProvider.notifier).setTab(2),
        );
    }
  }
}

final _activityTrackingBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(activityTrackingServiceProvider).start();
});

final _healthSyncBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(healthSyncServiceProvider).syncToday();
});

final _offlineSyncBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(offlineSyncServiceProvider).processQueue();
});

final _smartNotificationBootstrapProvider = FutureProvider<void>((ref) async {
  final profile = ref.watch(userProfileProvider).asData?.value;
  final summary = ref.watch(dailySummaryProvider).asData?.value;
  final settings = ref.watch(appSettingsProvider).asData?.value;
  final steps = ref.watch(todayStepsProvider).asData?.value;
  final sleep = ref.watch(todaySleepProvider).asData?.value;
  if (profile == null || summary == null || settings == null || !settings.notificationsEnabled) {
    return;
  }
  await ref.read(notificationServiceProvider).scheduleContextualReminders(
        profile: profile,
        settings: settings,
        summary: summary,
        steps: steps,
        sleep: sleep,
      );
});

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: selected ? 1 : 0,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
