import 'package:flutter/material.dart';

class AnalysisLoadingSheet extends StatelessWidget {
  const AnalysisLoadingSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'খাবার শনাক্ত করা হচ্ছে...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'আপনার লক্ষ্য, খাবারের ধরন আর স্বাস্থ্য অবস্থার সাথে মিলিয়ে ফলাফল তৈরি হচ্ছে।',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
