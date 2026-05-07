import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/bengali_formatters.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../data/models/user_profile.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/option_chip.dart';
import '../widgets/typing_indicator.dart';

class OnboardingChatScreen extends ConsumerStatefulWidget {
  const OnboardingChatScreen({super.key});

  @override
  ConsumerState<OnboardingChatScreen> createState() => _OnboardingChatScreenState();
}

class _OnboardingChatScreenState extends ConsumerState<OnboardingChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(onboardingProvider.notifier).submitText(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 160,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final isConditionStep = state.step == OnboardingStep.conditions;
    final isGenderStep = state.step == OnboardingStep.gender;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF7),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Breathtaking decorative soft blobs for worldclass aesthetics
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: const Color(0xFFE2F3E7).withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -140,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F3F5).withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Premium glassmorphic progress card
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFF2FAF4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.8), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryPale,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.spa_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'সুস্বাস্থ্য শুরু হোক নিজের ভাষায়',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'কয়েকটি ছোট উত্তর দিলেই আমি আপনার খাবার, স্ক্যান আর পরামর্শ ব্যক্তিগতভাবে সাজিয়ে দেব।',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                                fontSize: 13,
                              ),
                        ),
                        const SizedBox(height: 16),
                        // Glow and sleek progress bar
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: _progressFor(state.step),
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE4EDE7),
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: isConditionStep
                      ? _buildConditionStep(context, state)
                      : _buildChatArea(state),
                ),
                if (!isConditionStep)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.25),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                        ),
                        child: child,
                      );
                    },
                    child: isGenderStep ? _buildGenderSelector(context) : _buildInputArea(context, state),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(OnboardingState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: state.messages.length + (state.isSaving ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.messages.length) {
          return const TypingIndicator();
        }
        return ChatBubble(message: state.messages[index]);
      },
    );
  }

  Widget _buildConditionStep(BuildContext context, OnboardingState state) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.viewPaddingOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFF7FAF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.8), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'আপনার কোন কোন শারীরিক সমস্যা আছে?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'একাধিক নির্বাচন করতে পারেন। কিছু না থাকলে কিছু না বেছে সরাসরি এগিয়ে যান।',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                        fontSize: 13,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...state.availableConditions.map((condition) {
            final isSelected = state.conditions.contains(condition);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryPale : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? AppColors.primaryLight : AppColors.border.withValues(alpha: 0.8),
                  width: isSelected ? 2.0 : 1.5,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ref.read(onboardingProvider.notifier).toggleCondition(condition);
                    _scrollToBottom();
                  },
                  borderRadius: BorderRadius.circular(22),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.pageBg,
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
                                  color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                condition.descriptionBn,
                                style: TextStyle(
                                  color: isSelected ? AppColors.primary.withValues(alpha: 0.8) : AppColors.textSecondary,
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
                            color: isSelected ? AppColors.primaryLight : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.primaryLight : AppColors.textMuted.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: isSelected
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
          const SizedBox(height: 24),
          _ProfilePreviewCard(state: state),
          const SizedBox(height: 24),
          PrimaryButton(
            label: state.isSaving ? 'প্রোফাইল সংরক্ষণ হচ্ছে...' : 'ড্যাশবোর্ডে চলুন',
            onPressed: state.isSaving ? null : () => ref.read(onboardingProvider.notifier).finish(ref),
            icon: Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );
  }

  double _progressFor(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.name => 0.16,
      OnboardingStep.gender => 0.28,
      OnboardingStep.age => 0.40,
      OnboardingStep.weight => 0.56,
      OnboardingStep.height => 0.70,
      OnboardingStep.goal => 0.84,
      OnboardingStep.conditions => 0.96,
      OnboardingStep.complete => 1.0,
    };
  }

  Widget _buildGenderSelector(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + MediaQuery.viewPaddingOf(context).bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 14),
            child: Text(
              'আপনি ছেলে নাকি মেয়ে?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: UserGender.values
                .map(
                  (gender) => OptionChip(
                    label: gender.labelBn,
                    isSelected: false,
                    onTap: () {
                      ref.read(onboardingProvider.notifier).selectGender(gender);
                      _scrollToBottom();
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, OnboardingState state) {
    switch (state.step) {
      case OnboardingStep.gender:
        return const SizedBox.shrink();
      case OnboardingStep.goal:
        return _GoalSelector(
          onSelect: (goal) {
            ref.read(onboardingProvider.notifier).selectGoal(goal);
            _scrollToBottom();
          },
        );
      case OnboardingStep.conditions:
      case OnboardingStep.complete:
        return const SizedBox.shrink();
      case OnboardingStep.name:
      case OnboardingStep.age:
      case OnboardingStep.weight:
      case OnboardingStep.height:
        return Container(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  _questionFor(state.step, state.name),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryFaint,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        keyboardType: state.step == OnboardingStep.name
                            ? TextInputType.name
                            : const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: _hintFor(state.step),
                          border: InputBorder.none,
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500),
                        ),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _submit,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, Color(0xFF2D6A4F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
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

  String _questionFor(OnboardingStep step, String? name) {
    return switch (step) {
      OnboardingStep.name => 'আপনার নাম কী?',
      OnboardingStep.gender => 'আপনি ছেলে নাকি মেয়ে?',
      OnboardingStep.age => '${name ?? 'আপনার'} বয়স কত?',
      OnboardingStep.weight => 'আপনার वर्तमान ওজন কত কেজি?',
      OnboardingStep.height => 'আপনার উচ্চতা কত সেন্টিমিটার?',
      _ => 'এখানে লিখুন',
    };
  }

  String _hintFor(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.name => 'যেমন Zahurul',
      OnboardingStep.gender => 'ছেলে বা মেয়ে',
      OnboardingStep.age => 'যেমন ২৪',
      OnboardingStep.weight => 'যেমন ৬৫',
      OnboardingStep.height => 'যেমন ১৭৭',
      _ => 'এখানে লিখুন',
    };
  }
}

class _GoalSelector extends StatelessWidget {
  const _GoalSelector({required this.onSelect});

  final ValueChanged<UserGoal> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + MediaQuery.viewPaddingOf(context).bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 14),
            child: Text(
              'আপনার প্রধান লক্ষ্য বেছে নিন',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: UserGoal.values
                .map(
                  (goal) => OptionChip(
                    label: goal.labelBn,
                    isSelected: false,
                    onTap: () => onSelect(goal),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ProfilePreviewCard extends StatelessWidget {
  const _ProfilePreviewCard({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    if (state.name == null ||
        state.age == null ||
        state.weightKg == null ||
        state.heightCm == null ||
        state.goal == null) {
      return const SizedBox.shrink();
    }

    final bmi = state.weightKg! / ((state.heightCm! / 100) * (state.heightCm! / 100));
    final target = _dailyTarget();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.analytics_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                'আপনার স্বাস্থ্য প্রোফাইল রিভিও',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User header card
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEBF7F0), Color(0xFFD4EFE1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
                    ),
                    child: const Center(
                      child: Text(
                        '👤',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.name ?? '',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                          ),
                        ),
                        Text(
                          state.gender?.labelBn ?? 'লিঙ্গ নির্ধারণ করা হয়নি',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Goal badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFaint,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
                    ),
                    child: Text(
                      state.goal!.labelBn,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: AppColors.border),
              const SizedBox(height: 12),

              // Visual Grid for physical metrics
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.15,
                children: [
                  _buildMetricCell(
                    icon: '🎂',
                    title: 'বয়স',
                    value: '${BengaliFormatters.toBengaliNumber(state.age!)} বছর',
                    color: const Color(0xFFFEF5EC),
                    valueColor: Colors.orange.shade800,
                  ),
                  _buildMetricCell(
                    icon: '⚖️',
                    title: 'ওজন',
                    value: '${BengaliFormatters.toBengaliNumber(state.weightKg!, fractionDigits: 0)} kg',
                    color: const Color(0xFFEEF5FC),
                    valueColor: Colors.blue.shade800,
                  ),
                  _buildMetricCell(
                    icon: '📏',
                    title: 'উচ্চতা',
                    value: '${BengaliFormatters.toBengaliNumber(state.heightCm!, fractionDigits: 0)} cm',
                    color: const Color(0xFFF0FAF3),
                    valueColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // BMI Section with visual meter
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.pageBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'বডি মাস ইনডেক্স (BMI)',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${BengaliFormatters.toBengaliNumber(bmi, fractionDigits: 1)} (${_bmiLabel(bmi)})',
                          style: TextStyle(
                            color: _bmiColor(bmi),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Visual slide indicator
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: SizedBox(
                        height: 8,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Row(
                              children: [
                                Expanded(child: Container(color: Colors.blue.shade300)),
                                Expanded(child: Container(color: Colors.green.shade400)),
                                Expanded(child: Container(color: Colors.orange.shade300)),
                                Expanded(child: Container(color: Colors.red.shade300)),
                              ],
                            ),
                            // Pointer alignment based on BMI value (15 to 35 range mapping)
                            Align(
                              alignment: Alignment(
                                ((bmi.clamp(15.0, 35.0) - 15.0) / (35.0 - 15.0)) * 2 - 1.0,
                                0.0,
                              ),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('কম ওজন', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('স্বাভাবিক', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('অতিরিক্ত', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('স্থুলতা', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Daily Calorie Target Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFECFDF3), Color(0xFFD4F9E2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'দৈনিক ক্যালরি বাজেট লক্ষ্য',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${BengaliFormatters.toBengaliNumber(target)} কিলোক্যালরি (kcal)',
                            style: const TextStyle(
                              color: AppColors.primaryDark,
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCell({
    required String icon,
    required String title,
    required String value,
    required Color color,
    required Color valueColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 5),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  int _dailyTarget() {
    final genderAdjustment = state.gender == UserGender.female ? -161 : 5;
    final base = (10 * state.weightKg!) + (6.25 * state.heightCm!) - (5 * state.age!) + genderAdjustment;
    return switch (state.goal!) {
      UserGoal.weightLoss => (base - 250).round(),
      UserGoal.weightGain => (base + 250).round(),
      UserGoal.maintenance => base.round(),
    };
  }

  String _bmiLabel(double bmi) {
    if (bmi < 18.5) return 'কম ওজন';
    if (bmi < 25) return 'স্বাভাবিক';
    return 'অতিরিক্ত ওজন';
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue.shade700;
    if (bmi < 25) return AppColors.primary;
    return Colors.orange.shade800;
  }
}
