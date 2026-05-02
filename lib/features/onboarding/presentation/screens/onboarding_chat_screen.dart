import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
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
    final text = _controller.text;
    _controller.clear();
    ref.read(onboardingProvider.notifier).submitText(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF1FAF4), Color(0xFFE4F5EA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryDark),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'স্বাস্থ্য শুরু হোক নিজের ভাষায়',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'কয়েকটি ছোট উত্তর দিলেই আমি আপনার খাবার, স্ক্যান আর পরামর্শ ব্যক্তিগতভাবে সাজিয়ে দেব।',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: _progressFor(state.step),
                        minHeight: 10,
                        backgroundColor: Colors.white,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: state.messages.length + (state.isSaving ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.messages.length) {
                    return const TypingIndicator();
                  }
                  return ChatBubble(message: state.messages[index]);
                },
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildInputArea(context, state),
            ),
          ],
        ),
      ),
    );
  }

  double _progressFor(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.name => 0.16,
      OnboardingStep.age => 0.32,
      OnboardingStep.weight => 0.48,
      OnboardingStep.height => 0.64,
      OnboardingStep.goal => 0.82,
      OnboardingStep.conditions => 0.96,
      OnboardingStep.complete => 1.0,
    };
  }

  Widget _buildInputArea(BuildContext context, OnboardingState state) {
    switch (state.step) {
      case OnboardingStep.goal:
        return _GoalSelector(
          onSelect: (goal) {
            ref.read(onboardingProvider.notifier).selectGoal(goal);
            _scrollToBottom();
          },
        );
      case OnboardingStep.conditions:
        return _ConditionSelector(
          state: state,
          onToggle: (condition) {
            ref.read(onboardingProvider.notifier).toggleCondition(condition);
          },
          onContinue: () async {
            await ref.read(onboardingProvider.notifier).finish(ref);
          },
        );
      case OnboardingStep.complete:
        return const SizedBox(height: 16);
      case OnboardingStep.name:
      case OnboardingStep.age:
      case OnboardingStep.weight:
      case OnboardingStep.height:
        return Container(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
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
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _submit,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        );
    }
  }

  String _hintFor(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.name => 'আপনার নাম লিখুন',
      OnboardingStep.age => 'যেমন ২৬',
      OnboardingStep.weight => 'যেমন ৬৫',
      OnboardingStep.height => 'যেমন ১৬৮',
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
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
    );
  }
}

class _ConditionSelector extends StatelessWidget {
  const _ConditionSelector({
    required this.state,
    required this.onToggle,
    required this.onContinue,
  });

  final OnboardingState state;
  final ValueChanged<HealthCondition> onToggle;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: HealthCondition.values
                .map(
                  (condition) => OptionChip(
                    label: condition.labelBn,
                    isSelected: state.conditions.contains(condition),
                    onTap: () => onToggle(condition),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: state.isSaving ? 'প্রোফাইল সংরক্ষণ হচ্ছে...' : 'ড্যাশবোর্ডে চলুন',
            onPressed: state.isSaving ? null : () => onContinue(),
            icon: Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );
  }
}
