import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('পুষ্টি-দৃষ্টি')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ছবি বা লেখা, দুটোই চলবে', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'খাবারের ছবি তুলুন অথবা লিখে জানান কী খেয়েছেন। AI আপনার প্রোফাইল অনুযায়ী বিশ্লেষণ করবে।',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'ছবি তুলুন',
                        onPressed: state.isAnalyzing ? null : () => ref.read(scannerProvider.notifier).pickAndAnalyze(ref),
                        icon: Icons.camera_alt_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: state.isAnalyzing ? null : () => ref.read(scannerProvider.notifier).analyzeText(ref),
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('লিখে জানান'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  minLines: 3,
                  maxLines: 4,
                  onChanged: (value) => ref.read(scannerProvider.notifier).updateDescription(value),
                  decoration: const InputDecoration(
                    hintText: 'যেমন: এক প্লেট ভাত আর ডাল খেয়েছি',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (state.image != null) ...[
            ScanPreviewCard(image: state.image!),
            const SizedBox(height: 12),
          ],
          if (state.isAnalyzing) ...[
            const AnalysisLoadingSheet(),
            const SizedBox(height: 12),
          ],
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('আজ আগে যা স্ক্যান করেছেন', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                SizedBox(
                  height: 110,
                  child: summary == null || summary.meals.isEmpty
                      ? ListView(
                          scrollDirection: Axis.horizontal,
                          children: const [
                            _TipCard(text: 'পরিষ্কার আলোতে পুরো প্লেট নিন'),
                            SizedBox(width: 10),
                            _TipCard(text: 'দেশীয় খাবারের নাম লিখলেও বিশ্লেষণ হবে'),
                            SizedBox(width: 10),
                            _TipCard(text: 'স্ক্যানের পর লগে যোগ করলে dashboard update হবে'),
                          ],
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) => _RecentScanCard(
                            title: summary.meals[index].foodName,
                            subtitle: '${summary.meals[index].macros.calories.round()} kcal',
                          ),
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemCount: summary.meals.length.clamp(0, 6),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _RecentScanCard extends StatelessWidget {
  const _RecentScanCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
