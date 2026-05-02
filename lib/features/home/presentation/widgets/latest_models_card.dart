import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../data/models/latest_model_info.dart';

class LatestModelsCard extends StatelessWidget {
  const LatestModelsCard({
    super.key,
    required this.models,
  });

  final List<LatestModelInfo> models;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'এআই মডেল আপডেট',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          ...models.map(
            (model) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 6,
                    backgroundColor: model.available ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _providerLabel(model.provider),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          model.available
                              ? '${model.name ?? model.id ?? 'উপলভ্য'}${model.version != null ? ' • ${model.version}' : ''}'
                              : (model.reason ?? 'এই provider এখন উপলভ্য নয়।'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: model.available ? AppColors.textPrimary : AppColors.warning,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _providerLabel(String provider) {
    return switch (provider) {
      'openai' => 'GPT',
      'anthropic' => 'Claude',
      'google' => 'Gemini',
      _ => provider,
    };
  }
}
