import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
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
  @override
  Widget build(BuildContext context) {
    ref.listen(scannerProvider, (previous, next) {
      if (next.result != null && previous?.result != next.result) {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => FoodResultBottomSheet(result: next.result!),
        );
      }

      if (next.errorMessage != null && previous?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    final state = ref.watch(scannerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('পুষ্টি-দৃষ্টি'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF0FAF3), Color(0xFFE4F5EA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'একটি ছবি, অনেক তথ্য',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'আপনার খাবারের ছবি তুলুন। আমি সম্ভাব্য দেশীয় খাবার শনাক্ত করে ক্যালরি, ম্যাক্রো, ভালো দিক আর রোগভিত্তিক সতর্কতা দেখাব।',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (state.image != null) ...[
            ScanPreviewCard(image: state.image!),
            const SizedBox(height: 16),
          ],
          PrimaryButton(
            label: state.isAnalyzing ? 'বিশ্লেষণ চলছে...' : 'খাবারের ছবি তুলুন',
            onPressed: state.isAnalyzing
                ? null
                : () => ref.read(scannerProvider.notifier).pickAndAnalyze(ref),
            icon: Icons.camera_alt_rounded,
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.info),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'পরিষ্কার আলোতে পুরো প্লেট বা বাটি যেন ছবিতে আসে, সেদিকে খেয়াল রাখুন।',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (state.isAnalyzing) const AnalysisLoadingSheet(),
        ],
      ),
    );
  }
}
