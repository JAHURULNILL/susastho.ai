import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_design.dart';
import '../../../../core/utils/bengali_formatters.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../data/models/app_settings.dart';
import '../../../../data/models/doctor_note.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.onOpenScan,
  });

  final VoidCallback onOpenScan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).asData?.value;
    final dashboard = ref.watch(homeDashboardProvider);
    final settings = ref.watch(appSettingsProvider).asData?.value ?? const AppSettings();

    if (profile == null || dashboard == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final consumed = dashboard.consumedMacros.calories.round();
    final net = dashboard.netCalories;
    final target = dashboard.targetMacros.calories.round();
    final remaining = dashboard.remainingCalories;
    final meals = dashboard.summary.meals;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
        children: [
          Text('Today', style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(profile.name, style: AppTextStyles.screenTitle.copyWith(fontSize: 30)),
          const SizedBox(height: 18),
          _DoctorNoteCard(note: dashboard.doctorNote),
          const SizedBox(height: 14),
          _SafeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('আজকের ক্যালরি', style: AppTextStyles.cardTitle),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricBox(
                        label: 'লক্ষ্য',
                        value: target > 0 ? '$target kcal' : '—',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricBox(
                        label: 'খাবার',
                        value: consumed > 0 ? '$consumed kcal' : '—',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricBox(
                        label: 'নেট',
                        value: meals.isEmpty ? '—' : '$net kcal',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  meals.isEmpty
                      ? 'লক্ষ্য: ${BengaliFormatters.toBengaliNumber(target)} kcal — এখনো কোনো খাবার লগ হয়নি'
                      : 'বাকি: ${BengaliFormatters.toBengaliNumber(remaining)} kcal',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SafeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('আজকের ডায়েরি', style: AppTextStyles.cardTitle),
                const SizedBox(height: 12),
                if (meals.isEmpty)
                  Text(
                    'এখনো কোনো খাবার লগ করা হয়নি।',
                    style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                  )
                else
                  ...meals.take(4).map(
                    (meal) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${meal.foodName} • ${meal.macros.calories.round()} kcal',
                        style: AppTextStyles.body,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: 'খাবার স্ক্যান করুন',
                  onPressed: onOpenScan,
                  icon: Icons.add_a_photo_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SafeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('পানি ও এনার্জি', style: AppTextStyles.cardTitle),
                const SizedBox(height: 10),
                Text(
                  dashboard.summary.waterGlasses == 0
                      ? 'পানি পান শুরু করুন 💧'
                      : 'আজ ${BengaliFormatters.toBengaliNumber(dashboard.summary.waterGlasses)} গ্লাস পানি পান হয়েছে',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 6),
                Text(
                  settings.morningEnergy == 0 && settings.eveningEnergy == 0
                      ? 'এনার্জি ট্র্যাকিং এখনো শুরু হয়নি'
                      : 'সকাল এনার্জি: ${settings.morningEnergy}/3 • বিকাল এনার্জি: ${settings.eveningEnergy}/3',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorNoteCard extends StatelessWidget {
  const _DoctorNoteCard({required this.note});

  final DoctorNoteRecord? note;

  @override
  Widget build(BuildContext context) {
    return _SafeCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF184A32), Color(0xFF2D6A4F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note == null ? 'আপনার জন্য পরামর্শ তৈরি হচ্ছে...' : (doctorNoteCategoryLabels[note!.category] ?? 'ডাক্তারের নোট'),
            style: AppTextStyles.cardTitle.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 10),
          Text(
            note?.content ?? 'AI আপনার বাস্তব ডেটা দেখে ব্যক্তিগত নোট তৈরি করছে।',
            style: AppTextStyles.body.copyWith(color: AppColors.white, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _SafeCard extends StatelessWidget {
  const _SafeCard({
    required this.child,
    this.gradient,
  });

  final Widget child;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: gradient == null ? AppColors.white : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gradient == null ? AppColors.border : Colors.transparent,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(45, 106, 79, 0.08),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
