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
    final dateText = DateFormat('dd MMMM').format(DateTime.now());
    final initial = profile.name.trim().isEmpty ? 'S' : profile.name.trim().characters.first.toUpperCase();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('আজ', style: AppTextStyles.caption.copyWith(letterSpacing: 0.2)),
              const SizedBox(height: 4),
              Text(profile.name, style: AppTextStyles.screenTitle.copyWith(fontSize: 30)),
              const SizedBox(height: 4),
              Text(dateText, style: AppTextStyles.caption),
            ],
          ),
        ),
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(27, 94, 59, 0.18),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: AppTextStyles.metricSmall.copyWith(
              color: AppColors.white,
              fontSize: 24,
            ),
          ),
        ),
      ],
    );
  }
}
