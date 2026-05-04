import 'package:flutter/material.dart';

import '../../../../data/models/weekly_plan.dart';

class ExerciseSuggestionCard extends StatelessWidget {
  const ExerciseSuggestionCard({
    super.key,
    required this.item,
  });

  final WeeklyExerciseItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.dateKey, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Text(item.exerciseTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(item.durationText),
            const SizedBox(height: 6),
            Text(item.note),
          ],
        ),
      ),
    );
  }
}
