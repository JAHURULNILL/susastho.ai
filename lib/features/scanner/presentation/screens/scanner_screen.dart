import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_design.dart';
import '../../../../core/widgets/fade_up_item.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../home/providers/home_provider.dart';
import '../../providers/scanner_provider.dart';
import '../widgets/analysis_loading_sheet.dart';
import '../widgets/food_result_bottom_sheet.dart';
import '../widgets/scan_preview_card.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scannerProvider, (previous, next) {
      if (next.result != null && previous?.result != next.result) {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => FoodResultBottomSheet(
            result: next.result!,
            imagePath: next.image?.path,
          ),
        );
      }

      if (next.errorMessage != null && previous?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    final state = ref.watch(scannerProvider);
    final summary = ref.watch(dailySummaryProvider).asData?.value;

    if (_controller.text != state.description) {
      _controller.value = _controller.value.copyWith(
        text: state.description,
        selection: TextSelection.collapsed(offset: state.description.length),
      );
    }

    final widgets = <Widget>[
      InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('পুষ্টি-দৃষ্টি', style: AppTextStyles.screenTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'খাবারের ছবি তুলুন অথবা লিখে জানান। AI আপনার বাস্তব প্রোফাইল আর আজকের লগ অনুযায়ী বিশ্লেষণ করবে।',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'ছবি তুলুন',
                    onPressed: state.isAnalyzing ? null : () => ref.read(scannerProvider.notifier).pickAndAnalyze(ref),
                    icon: Icons.camera_alt_rounded,
                    height: 52,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: state.isAnalyzing ? null : () => ref.read(scannerProvider.notifier).analyzeText(ref),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('লিখে জানান'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                TextField(
                  controller: _controller,
                  minLines: 4,
                  maxLines: 5,
                  onChanged: (value) => ref.read(scannerProvider.notifier).updateDescription(value),
                  decoration: const InputDecoration(
                    hintText: 'যেমন: এক প্লেট ভাত আর ডাল খেয়েছি',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: InkWell(
                    onTap: state.isAnalyzing ? null : () => ref.read(scannerProvider.notifier).analyzeText(ref),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: AppColors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      if (state.image != null) ScanPreviewCard(image: state.image!),
      if (state.isAnalyzing) const AnalysisLoadingSheet(),
      InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('আজ আগে যা স্ক্যান করেছেন', style: AppTextStyles.cardTitle),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 96,
              child: summary == null || summary.meals.isEmpty
                  ? Center(
                      child: Text(
                        'আজ এখনো কোনো স্ক্যান লগ নেই।',
                        style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: summary.meals.length.clamp(0, 6),
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                      itemBuilder: (context, index) => _RecentScanCard(meal: summary.meals[index]),
                    ),
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('পুষ্টি-দৃষ্টি')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          12,
          AppSpacing.screenPadding,
          120,
        ),
        itemCount: widgets.length,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: index == widgets.length - 1 ? 0 : AppSpacing.cardGap),
          child: FadeUpItem(index: index, child: widgets[index]),
        ),
      ),
    );
  }
}

class _RecentScanCard extends StatelessWidget {
  const _RecentScanCard({required this.meal});

  final dynamic meal;

  @override
  Widget build(BuildContext context) {
    final ago = _timeAgo(meal.loggedAt as DateTime);
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.6,
      constraints: const BoxConstraints(minHeight: 80),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryFaint,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(meal.slot.icon as String, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.foodName as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPale,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${meal.macros.calories.round()} kcal',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ago,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'এইমাত্র';
    if (diff.inHours < 1) return '${diff.inMinutes} মিনিট আগে';
    return '${diff.inHours} ঘণ্টা আগে';
  }
}
