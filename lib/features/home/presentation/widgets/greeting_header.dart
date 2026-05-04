import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_design.dart';
import '../../../../data/models/user_profile.dart';

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.profile,
  });

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateText = DateFormat('dd MMMM').format(now);
    final greeting = switch (now.hour) {
      < 6 => 'শুভ রাত',
      < 12 => 'শুভ সকাল',
      < 17 => 'শুভ দুপুর',
      < 21 => 'শুভ সন্ধ্যা',
      _ => 'শুভ রাত',
    };

    final shortName = profile.name.trim().split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateText,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$greeting, ',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: shortName,
                style: AppTextStyles.screenTitle.copyWith(fontSize: 28),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
