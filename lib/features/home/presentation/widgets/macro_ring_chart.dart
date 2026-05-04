import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_design.dart';
import '../../../../core/utils/bengali_formatters.dart';
import '../../../../core/widgets/animated_count_text.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../data/models/food_analysis_result.dart';

class MacroRingChart extends StatelessWidget {
  const MacroRingChart({
    super.key,
    required this.target,
    required this.consumed,
  });

  final NutritionMacro target;
  final NutritionMacro consumed;

  @override
  Widget build(BuildContext context) {
    final progress = target.calories == 0 ? 0.0 : (consumed.calories / target.calories).clamp(0.0, 1.0);
    final remaining = (target.calories - consumed.calories).clamp(0, target.calories).round();

    return InfoCard(
      backgroundColor: AppColors.white,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('আজকের ক্যালরি ব্যালেন্স', style: AppTextStyles.cardTitle),
                    const SizedBox(height: 4),
                    Text('Goal • Food • Remaining', style: AppTextStyles.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryFaint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Premium',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: SizedBox(
                  width: 170,
                  height: 170,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeInOut,
                    builder: (context, animatedProgress, _) {
                      return CustomPaint(
                        painter: _RingPainter(progress: animatedProgress),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedCountText(
                                value: consumed.calories,
                                builder: (value) => Text(
                                  BengaliFormatters.toBengaliNumber(value.round()),
                                  style: AppTextStyles.metric.copyWith(fontSize: 40),
                                ),
                              ),
                              Text('খাওয়া হয়েছে', style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _MiniMetric(
                      label: 'Goal',
                      value: BengaliFormatters.toBengaliNumber(target.calories.round()),
                      suffix: 'kcal',
                      icon: Icons.flag_rounded,
                    ),
                    const SizedBox(height: 10),
                    _MiniMetric(
                      label: 'Food',
                      value: BengaliFormatters.toBengaliNumber(consumed.calories.round()),
                      suffix: 'kcal',
                      icon: Icons.restaurant_rounded,
                    ),
                    const SizedBox(height: 10),
                    _MiniMetric(
                      label: 'Remaining',
                      value: BengaliFormatters.toBengaliNumber(remaining),
                      suffix: 'kcal',
                      icon: Icons.auto_graph_rounded,
                      accent: AppColors.primaryLight,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${BengaliFormatters.toBengaliNumber(remaining)} kcal বাকি',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _MacroMiniBar(
            label: 'প্রোটিন',
            current: consumed.protein,
            target: target.protein,
            color: AppColors.blue,
          ),
          const SizedBox(height: 10),
          _MacroMiniBar(
            label: 'কার্বস',
            current: consumed.carbs,
            target: target.carbs,
            color: AppColors.primaryLight,
          ),
          const SizedBox(height: 10),
          _MacroMiniBar(
            label: 'ফ্যাট',
            current: consumed.fat,
            target: target.fat,
            color: AppColors.amber,
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.suffix,
    required this.icon,
    this.accent = AppColors.primary,
  });

  final String label;
  final String value;
  final String suffix;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTextStyles.metricSmall.copyWith(fontSize: 20, color: AppColors.textPrimary),
                ),
                TextSpan(
                  text: ' $suffix',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroMiniBar extends StatelessWidget {
  const _MacroMiniBar({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  final String label;
  final double current;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 54,
          child: Text(label, style: AppTextStyles.caption),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.border,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${BengaliFormatters.toBengaliNumber(current.round())}/${BengaliFormatters.toBengaliNumber(target.round())}',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    final trackPaint = Paint()
      ..color = const Color(0xFFE8F5E9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    if (progress == 0) {
      final dashPaint = Paint()
        ..color = const Color(0xFFC9DED0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 36; i++) {
        final start = -math.pi / 2 + (i * 2 * math.pi / 36);
        canvas.drawArc(rect, start, 0.1, false, dashPaint);
      }
      return;
    }

    canvas.drawCircle(center, radius, trackPaint);

    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: const [AppColors.primaryLight, AppColors.primary],
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}
