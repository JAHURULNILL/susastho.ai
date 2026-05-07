import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_design.dart';
import '../../../../core/utils/bengali_formatters.dart';
import '../../../../core/widgets/fade_up_item.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../data/models/app_settings.dart';
import '../../../../data/models/health_metrics.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../shared/providers/app_state_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController();
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).asData?.value;
    final settings = ref.watch(appSettingsProvider).asData?.value ?? const AppSettings();
    final sleep = ref.watch(todaySleepProvider).asData?.value;
    final steps = ref.watch(todayStepsProvider).asData?.value;
    final weightHistory = ref.watch(weightHistoryProvider).asData?.value ?? const <WeightHistoryEntry>[];

    if (profile == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 3,
        ),
      );
    }

    if (_goalController.text != (settings.customCalorieGoal?.toString() ?? '')) {
      _goalController.text = settings.customCalorieGoal?.toString() ?? '';
    }

    final initial = profile.name.trim().isEmpty ? 'S' : profile.name.trim().characters.first.toUpperCase();
    final bmiMeta = _bmiMeta(profile.bmi);

    final List<Widget> widgets = [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF173926), Color(0xFF225E3E), Color(0xFF2D8A53)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF173926).withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primaryMid],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: GoogleFonts.notoSansBengali(
                    color: AppColors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              profile.name,
              style: GoogleFonts.notoSansBengali(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: bmiMeta.$2,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'BMI ${profile.bmi.toStringAsFixed(1)} • ${bmiMeta.$1}',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      _buildSectionHeader('📊 শারীরিক বিবরণ', 'আপনার স্বাস্থ্য প্রোফাইলের মূল পরিমাপসমূহ'),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: [
          _buildVitalTile(
            title: 'ওজন (Weight)',
            value: '${profile.weightKg.toStringAsFixed(1)} kg',
            icon: Icons.scale_rounded,
            color: Colors.teal,
            onTap: () => _editProfileValue(context, profile, field: _EditableField.weight),
          ),
          _buildVitalTile(
            title: 'উচ্চতা (Height)',
            value: '${profile.heightCm.toStringAsFixed(0)} cm',
            icon: Icons.straighten_rounded,
            color: Colors.blueAccent,
            onTap: () => _editProfileValue(context, profile, field: _EditableField.height),
          ),
          _buildVitalTile(
            title: 'বয়স (Age)',
            value: '${BengaliFormatters.toBengaliNumber(profile.age)} বছর',
            icon: Icons.cake_rounded,
            color: Colors.orange,
            onTap: () => _editProfileValue(context, profile, field: _EditableField.age),
          ),
          _buildVitalTile(
            title: 'লিঙ্গ (Gender)',
            value: profile.gender.labelBn,
            icon: Icons.transgender_rounded,
            color: Colors.purple,
            onTap: () => _editGender(context, profile),
          ),
          _buildVitalTile(
            title: 'লক্ষ্য (Health Goal)',
            value: profile.goal.labelBn,
            icon: Icons.track_changes_rounded,
            color: Colors.redAccent,
            onTap: () => _editGoal(context, profile),
          ),
          _buildVitalTile(
            title: 'স্টেপ লক্ষ্য',
            value: '${BengaliFormatters.toBengaliNumber(profile.dailyStepTarget)}',
            icon: Icons.directions_run_rounded,
            color: Colors.green,
            onTap: () {},
          ),
        ],
      ),
      const SizedBox(height: 10),
      _EditableConditionsCard(profile: profile),
      const SizedBox(height: 10),
      _buildSectionHeader('🔄 ওয়্যারেবল ও অ্যাক্টিভিটি সিঙ্ক', 'ডিভাইস কানেকশন ও মেজারমেন্ট লাইভ ফিড'),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: settings.wearableSyncEnabled 
                        ? Colors.emerald.withValues(alpha: 0.1) 
                        : Colors.amber.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bluetooth_connected_rounded,
                    color: settings.wearableSyncEnabled ? Colors.emerald : Colors.amber,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Connect সিঙ্ক',
                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        settings.wearableSyncEnabled ? 'অটোমেটিক সিঙ্ক সচল আছে' : 'অটোমেটিক সিঙ্ক বন্ধ',
                        style: AppTextStyles.caption.copyWith(
                          color: settings.wearableSyncEnabled ? Colors.emerald : Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.wearableSyncEnabled,
                  activeColor: Colors.emerald,
                  onChanged: (value) async {
                    await ref.read(appSettingsProvider.notifier).save(
                          settings.copyWith(wearableSyncEnabled: value),
                        );
                    if (value) {
                      await ref.read(healthSyncServiceProvider).syncToday();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSyncVitalsBox(
                    title: 'আজকের ঘুম',
                    value: sleep == null || sleep.hours == 0 
                        ? '—' 
                        : '${BengaliFormatters.toBengaliNumber(double.parse(sleep.hours.toStringAsFixed(1)))} ঘণ্টা',
                    icon: Icons.nights_stay_rounded,
                    color: Colors.indigoAccent,
                    onTap: () => _editSleep(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSyncVitalsBox(
                    title: 'আজকের স্টেপস',
                    value: steps == null || steps.steps == 0 
                        ? '—' 
                        : '${BengaliFormatters.toBengaliNumber(steps.steps)}',
                    icon: Icons.directions_walk_rounded,
                    color: Colors.green,
                    onTap: () => _editSteps(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      _buildSectionHeader('🕒 ইন্টারমিটেন্ট ফাস্টিং', 'আপনার দৈনিক ফাস্টিং সিডিউল ও রুটিন সেটিংস'),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: settings.fastingEnabled 
                        ? Colors.orange.withValues(alpha: 0.1) 
                        : Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.timer_outlined,
                    color: settings.fastingEnabled ? Colors.orange : Colors.grey,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ফাস্টিং টাইমার উইজেট',
                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        settings.fastingEnabled ? 'আপনার হোম স্ক্রিনে সক্রিয় আছে' : 'নিষ্ক্রিয় আছে',
                        style: AppTextStyles.caption.copyWith(
                          color: settings.fastingEnabled ? Colors.orange : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.fastingEnabled,
                  activeColor: Colors.orange,
                  onChanged: (value) async {
                    await ref.read(appSettingsProvider.notifier).save(
                          settings.copyWith(fastingEnabled: value),
                        );
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (settings.fastingEnabled) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.amberPale.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'আপনি দৈনিক ${BengaliFormatters.toBengaliNumber(settings.fastingWindowHours)} ঘণ্টার উইন্ডোতে ফাস্টিং করছেন।',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.brown[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: _MiniSettingBox(
                    title: 'শুরু হওয়ার সময়',
                    value: '${BengaliFormatters.toBengaliNumber(settings.fastingStartHour)}:০০',
                    onTap: () => _pickFastingHour(context, settings),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniSettingBox(
                    title: 'ফাস্টিং সময়',
                    value: '${BengaliFormatters.toBengaliNumber(settings.fastingWindowHours)} ঘণ্টা',
                    onTap: () => _pickFastingWindow(context, settings),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      _buildSectionHeader('⚙️ সেটিংস ও অ্যাপ এক্সপেরিয়েন্স', 'থিম, একক এবং লক্ষ্যমাত্রার পার্সোনালাইজেশন'),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            DropdownButtonFormField<AppThemeModePreference>(
              value: settings.themeMode,
              items: const [
                DropdownMenuItem(value: AppThemeModePreference.system, child: Text('সিস্টেম থিম')),
                DropdownMenuItem(value: AppThemeModePreference.light, child: Text('লাইট মোড (Light Mode)')),
                DropdownMenuItem(value: AppThemeModePreference.dark, child: Text('ডার্ক মোড (Dark Mode)')),
              ],
              onChanged: (value) async {
                if (value == null) return;
                await ref.read(appSettingsProvider.notifier).save(settings.copyWith(themeMode: value));
              },
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                labelText: 'থিম মোড',
                labelStyle: const TextStyle(color: AppColors.primaryMid, fontWeight: FontWeight.bold),
                prefixIcon: const Icon(Icons.palette_rounded, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.primaryFaint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: settings.units,
              items: const [
                DropdownMenuItem(value: 'মেট্রিক', child: Text('মেট্রিক একক (kg, cm)')),
                DropdownMenuItem(value: 'ইম্পেরিয়াল', child: Text('ইম্পেরিয়াল একক (lbs, inches)')),
              ],
              onChanged: (value) async {
                if (value == null) return;
                await ref.read(appSettingsProvider.notifier).save(settings.copyWith(units: value));
              },
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                labelText: 'পরিমাপ একক',
                labelStyle: const TextStyle(color: AppColors.primaryMid, fontWeight: FontWeight.bold),
                prefixIcon: const Icon(Icons.straighten_rounded, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.primaryFaint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('কাস্টম ক্যালরি লক্ষ্য', style: AppTextStyles.cardTitle),
            const SizedBox(height: 6),
            Text(
              'আপনার কাস্টম ক্যালরি লক্ষ্য সেট করলে অ্যাপ স্বয়ংক্রিয় লক্ষ্য পরিবর্তন করে এটি ব্যবহার করবে।',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _goalController,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'যেমন ২০০০ kcal',
                prefixIcon: const Icon(Icons.local_fire_department_rounded, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.primaryFaint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'ক্যালরি লক্ষ্য সংরক্ষণ করুন',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final goal = int.tryParse(_goalController.text.trim());
                final updated = settings.copyWith(customCalorieGoal: goal, clearCustomGoal: goal == null);
                await ref.read(appSettingsProvider.notifier).save(updated);
                if (mounted) {
                  messenger.showSnackBar(const SnackBar(content: Text('পরিবর্তন সংরক্ষিত হয়েছে ✓')));
                }
              },
              icon: Icons.flag_rounded,
            ),
            const SizedBox(height: 8),
            const Divider(color: AppColors.border, height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('দৈনিক স্মার্ট নোটিফিকেশন', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text(
                'রুটিন ফিনিশ, খাবারের সময় রিমাইন্ডার এবং AI হেলথ নোটিশ পেতে সাহায্য করবে।',
                style: AppTextStyles.caption,
              ),
              activeColor: AppColors.primary,
              value: settings.notificationsEnabled,
              onChanged: (value) async {
                await ref.read(appSettingsProvider.notifier).save(
                      settings.copyWith(notificationsEnabled: value),
                    );
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      _buildSectionHeader('📈 প্রগতি ট্র্যাকিং', 'আপনার সময়ের সাথে ওজনের পরিবর্তনের লগ সমূহ'),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('ওজন পরিবর্তনের ইতিহাস', style: AppTextStyles.cardTitle),
              ],
            ),
            const SizedBox(height: 18),
            if (weightHistory.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.monitor_weight_outlined, color: Colors.grey.withValues(alpha: 0.3), size: 48),
                      const SizedBox(height: 8),
                      Text('এখনো কোনো ওজন পরিবর্তনের রেকর্ড যোগ করা হয়নি।', style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: List.generate(weightHistory.take(5).length, (index) {
                  final entry = weightHistory[index];
                  final isLast = index == weightHistory.take(5).length - 1;
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryLight.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: AppColors.border,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${BengaliFormatters.toBengaliNumber(double.parse(entry.weightKg.toStringAsFixed(1)))} kg',
                                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      entry.dateKey,
                                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryFaint,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Text(
                                    'লগ সংরক্ষিত',
                                    style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'আজকের ওজন যোগ করুন',
              onPressed: () => _addWeight(context),
            ),
          ],
        ),
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        20,
        AppSpacing.screenPadding,
        120,
      ),
      itemCount: widgets.length,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: index == widgets.length - 1 ? 0 : AppSpacing.cardGap),
        child: FadeUpItem(index: index, child: widgets[index]),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10, left: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.notoSansBengali(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 2,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_rounded, color: AppColors.textMuted, size: 14),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncVitalsBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryPale),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String, Color) _bmiMeta(double bmi) {
    if (bmi < 18.5) {
      return ('আন্ডারওয়েট', AppColors.blue);
    }
    if (bmi < 25) {
      return ('স্বাভাবিক ✓', AppColors.primaryLight);
    }
    if (bmi < 30) {
      return ('ওভারওয়েট', AppColors.amber);
    }
    return ('স্থূলতা', AppColors.red);
  }

  Future<void> _editProfileValue(
    BuildContext context,
    UserProfile profile, {
    required _EditableField field,
  }) async {
    final controller = TextEditingController(
      text: switch (field) {
        _EditableField.weight => profile.weightKg.toStringAsFixed(1),
        _EditableField.height => profile.heightCm.toStringAsFixed(0),
        _EditableField.age => profile.age.toString(),
      },
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${field.label} পরিবর্তন',
              style: AppTextStyles.cardTitle.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primaryLight),
                ),
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'সংরক্ষণ করুন',
              onPressed: () async {
                final raw = controller.text.trim();
                if (raw.isEmpty) return;
                final notifier = ref.read(userProfileProvider.notifier);
                final updated = switch (field) {
                  _EditableField.weight => profile.copyWith(weightKg: double.tryParse(raw) ?? profile.weightKg),
                  _EditableField.height => profile.copyWith(heightCm: double.tryParse(raw) ?? profile.heightCm),
                  _EditableField.age => profile.copyWith(age: int.tryParse(raw) ?? profile.age),
                };
                await notifier.save(updated);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editGoal(BuildContext context, UserProfile profile) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'আপনার স্বাস্থ্য লক্ষ্য নির্ধারণ করুন',
              style: AppTextStyles.cardTitle.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...UserGoal.values.map(
              (goal) {
                final isSelected = profile.goal == goal;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryLight : Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        goal.labelBn,
                        style: TextStyle(
                          color: isSelected ? AppColors.primaryLight : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primaryLight) : null,
                      onTap: () async {
                        await ref.read(userProfileProvider.notifier).save(profile.copyWith(goal: goal));
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editGender(BuildContext context, UserProfile profile) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'লিঙ্গ পরিবর্তন করুন',
              style: AppTextStyles.cardTitle.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...UserGender.values.map(
              (gender) {
                final isSelected = profile.gender == gender;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryLight : Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        gender.labelBn,
                        style: TextStyle(
                          color: isSelected ? AppColors.primaryLight : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primaryLight) : null,
                      onTap: () async {
                        final filtered = profile.conditions.where((item) => item.isVisibleFor(gender)).toList();
                        await ref.read(userProfileProvider.notifier).save(
                              profile.copyWith(gender: gender, conditions: filtered),
                            );
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editSleep(BuildContext context) async {
    final hoursController = TextEditingController();
    String selectedQuality = 'good';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'আজকের ঘুমের তথ্য',
                style: AppTextStyles.cardTitle.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: hoursController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'যেমন ৭.৫ ঘণ্টা',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedQuality,
                style: const TextStyle(color: Colors.white),
                dropdownColor: const Color(0xFF1E293B),
                items: const [
                  DropdownMenuItem(value: 'poor', child: Text('ঘুম কম হয়েছে (Poor)', style: TextStyle(color: Colors.white70))),
                  DropdownMenuItem(value: 'fair', child: Text('মোটামুটি হয়েছে (Fair)', style: TextStyle(color: Colors.white70))),
                  DropdownMenuItem(value: 'good', child: Text('ভালো হয়েছে (Good)', style: TextStyle(color: Colors.white70))),
                  DropdownMenuItem(value: 'excellent', child: Text('চমৎকার হয়েছে (Excellent)', style: TextStyle(color: Colors.white70))),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setModalState(() => selectedQuality = value);
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'সংরক্ষণ করুন',
                onPressed: () async {
                  final hours = double.tryParse(hoursController.text.trim());
                  if (hours == null) return;
                  await ref.read(healthMetricsRepositoryProvider).saveSleep(
                        hours: hours,
                        quality: selectedQuality,
                      );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editSteps(BuildContext context) async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'আজকের স্টেপ সংখ্যা',
              style: AppTextStyles.cardTitle.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'যেমন ৫০০০ স্টেপ',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'সংরক্ষণ করুন',
              onPressed: () async {
                final steps = int.tryParse(controller.text.trim());
                if (steps == null) return;
                await ref.read(healthMetricsRepositoryProvider).saveSteps(steps);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFastingHour(BuildContext context, AppSettings settings) async {
    final controller = TextEditingController(text: '${settings.fastingStartHour}');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ফাস্টিং শুরু হওয়ার সময়',
              style: AppTextStyles.cardTitle.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'যেমন ২০ (রাত ৮টার জন্য)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'সংরক্ষণ করুন',
              onPressed: () async {
                final value = int.tryParse(controller.text.trim());
                if (value == null) return;
                await ref.read(appSettingsProvider.notifier).save(
                      settings.copyWith(fastingStartHour: value.clamp(0, 23)),
                    );
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFastingWindow(BuildContext context, AppSettings settings) async {
    final controller = TextEditingController(text: '${settings.fastingWindowHours}');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ফাস্টিং উইন্ডো (ঘণ্টা)',
              style: AppTextStyles.cardTitle.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'যেমন ১৬ (১৬:৮ রুটিনের জন্য)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'সংরক্ষণ করুন',
              onPressed: () async {
                final value = int.tryParse(controller.text.trim());
                if (value == null) return;
                await ref.read(appSettingsProvider.notifier).save(
                      settings.copyWith(fastingWindowHours: value.clamp(8, 23)),
                    );
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addWeight(BuildContext context) async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'আজকের ওজন রেকর্ড করুন',
              style: AppTextStyles.cardTitle.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'যেমন ৭২.৫ kg',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'ওজন যোগ করুন',
              onPressed: () async {
                final value = double.tryParse(controller.text.trim());
                if (value == null) return;
                await ref.read(healthMetricsRepositoryProvider).addWeightEntry(value);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum _EditableField {
  weight('ওজন'),
  height('উচ্চতা'),
  age('বয়স');

  const _EditableField(this.label);

  final String label;
}

class _EditableConditionsCard extends ConsumerWidget {
  const _EditableConditionsCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded, color: AppColors.red, size: 20),
              const SizedBox(width: 8),
              Text('ক্রনিক স্বাস্থ্য সমস্যা', style: AppTextStyles.cardTitle),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'সিলেক্ট করা থাকলে অ্যাপের AI ডায়েট ও এক্সারসাইজ প্ল্যান তৈরি করার সময় এগুলোকে অগ্রাধিকার দিবে।',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 14),
          ...HealthCondition.values.where((condition) => condition.isVisibleFor(profile.gender)).map((condition) {
            final selected = profile.conditions.contains(condition);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryPale : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.primaryLight : AppColors.border,
                  width: selected ? 2.0 : 1.5,
                ),
                boxShadow: [
                  if (selected)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.01),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    final updated = [...profile.conditions];
                    if (!selected) {
                      if (!updated.contains(condition)) updated.add(condition);
                    } else {
                      updated.remove(condition);
                    }
                    await ref.read(userProfileProvider.notifier).save(profile.copyWith(conditions: updated));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ক্রনিক স্বাস্থ্য সমস্যা আপডেট করা হয়েছে ✓'),
                          duration: Duration(milliseconds: 1200),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.pageBg,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            condition.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                condition.labelBn,
                                style: TextStyle(
                                  color: selected ? AppColors.primaryDark : AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                condition.descriptionBn,
                                style: TextStyle(
                                  color: selected ? AppColors.primary.withValues(alpha: 0.8) : AppColors.textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primaryLight : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? AppColors.primaryLight : AppColors.textMuted.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: selected
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 15,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}


