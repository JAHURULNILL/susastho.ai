import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import '../../../data/models/app_settings.dart';
import '../../../data/models/daily_summary.dart';
import '../../../data/models/user_profile.dart';
import '../../../shared/models/chat_message.dart';
import '../../../shared/providers/app_state_provider.dart';

enum OnboardingStep {
  name,
  gender,
  age,
  weight,
  height,
  goal,
  conditions,
  complete,
}

class OnboardingState {
  const OnboardingState({
    required this.messages,
    required this.step,
    this.name,
    this.gender,
    this.age,
    this.weightKg,
    this.heightCm,
    this.goal,
    this.conditions = const [],
    this.isSaving = false,
  });

  final List<ChatMessage> messages;
  final OnboardingStep step;
  final String? name;
  final UserGender? gender;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final UserGoal? goal;
  final List<HealthCondition> conditions;
  final bool isSaving;

  List<HealthCondition> get availableConditions {
    final gender = this.gender;
    if (gender == null) {
      return HealthCondition.values;
    }
    return HealthCondition.values.where((item) => item.isVisibleFor(gender)).toList();
  }

  OnboardingState copyWith({
    List<ChatMessage>? messages,
    OnboardingStep? step,
    String? name,
    UserGender? gender,
    int? age,
    double? weightKg,
    double? heightCm,
    UserGoal? goal,
    List<HealthCondition>? conditions,
    bool? isSaving,
  }) {
    return OnboardingState(
      messages: messages ?? this.messages,
      step: step ?? this.step,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      goal: goal ?? this.goal,
      conditions: conditions ?? this.conditions,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  factory OnboardingState.initial() {
    return const OnboardingState(
      messages: [
        ChatMessage(
          text: 'আসসালামু আলাইকুম। আমি Sushastho.ai। প্রথমে আপনার নামটা বলুন।',
          sender: ChatSender.ai,
        ),
      ],
      step: OnboardingStep.name,
    );
  }
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => OnboardingState.initial();

  void submitText(String value) {
    final input = value.trim();
    if (input.isEmpty || state.isSaving) {
      return;
    }

    final nextMessages = [...state.messages, ChatMessage(text: input, sender: ChatSender.user)];

    switch (state.step) {
      case OnboardingStep.name:
        state = state.copyWith(
          name: input,
          step: OnboardingStep.gender,
          messages: [
            ...nextMessages,
            ChatMessage(
              text: 'ধন্যবাদ $input। এখন আপনার লিঙ্গ নির্বাচন করুন।',
              sender: ChatSender.ai,
            ),
          ],
        );
        return;
      case OnboardingStep.age:
        final age = int.tryParse(input);
        if (age == null) {
          _appendAiMessage(nextMessages, 'বয়স শুধু সংখ্যায় লিখুন, যেমন ২৬।');
          return;
        }
        state = state.copyWith(
          age: age,
          step: OnboardingStep.weight,
          messages: [
            ...nextMessages,
            const ChatMessage(
              text: 'আপনার বর্তমান ওজন কত কেজি?',
              sender: ChatSender.ai,
            ),
          ],
        );
        return;
      case OnboardingStep.weight:
        final weight = double.tryParse(input);
        if (weight == null) {
          _appendAiMessage(nextMessages, 'ওজন সংখ্যায় লিখুন, যেমন ৬৫।');
          return;
        }
        state = state.copyWith(
          weightKg: weight,
          step: OnboardingStep.height,
          messages: [
            ...nextMessages,
            const ChatMessage(
              text: 'আপনার উচ্চতা কত সেন্টিমিটার?',
              sender: ChatSender.ai,
            ),
          ],
        );
        return;
      case OnboardingStep.height:
        final height = double.tryParse(input);
        if (height == null) {
          _appendAiMessage(nextMessages, 'উচ্চতা সংখ্যায় লিখুন, যেমন ১৭৭।');
          return;
        }
        state = state.copyWith(
          heightCm: height,
          step: OnboardingStep.goal,
          messages: [
            ...nextMessages,
            const ChatMessage(
              text: 'এখন আপনার প্রধান লক্ষ্যটি বেছে নিন।',
              sender: ChatSender.ai,
            ),
          ],
        );
        return;
      case OnboardingStep.gender:
      case OnboardingStep.goal:
      case OnboardingStep.conditions:
      case OnboardingStep.complete:
        return;
    }
  }

  void selectGender(UserGender gender) {
    if (state.step != OnboardingStep.gender) {
      return;
    }

    final nextMessages = [
      ...state.messages,
      ChatMessage(text: gender.labelBn, sender: ChatSender.user),
      const ChatMessage(
        text: 'এখন আপনার বয়স কত?',
        sender: ChatSender.ai,
      ),
    ];

    state = state.copyWith(
      gender: gender,
      conditions: state.conditions.where((item) => item.isVisibleFor(gender)).toList(),
      step: OnboardingStep.age,
      messages: nextMessages,
    );
  }

  void selectGoal(UserGoal goal) {
    if (state.step != OnboardingStep.goal) {
      return;
    }

    final nextMessages = [
      ...state.messages,
      ChatMessage(text: goal.labelBn, sender: ChatSender.user),
      const ChatMessage(
        text: 'আপনার কোনো স্বাস্থ্য সমস্যা থাকলে সেগুলো বেছে নিন। একাধিক নির্বাচন করতে পারেন।',
        sender: ChatSender.ai,
      ),
    ];

    state = state.copyWith(
      goal: goal,
      step: OnboardingStep.conditions,
      messages: nextMessages,
    );
  }

  void toggleCondition(HealthCondition condition) {
    if (state.step != OnboardingStep.conditions) {
      return;
    }

    final updated = [...state.conditions];
    if (updated.contains(condition)) {
      updated.remove(condition);
    } else {
      updated.add(condition);
    }

    state = state.copyWith(conditions: updated);
  }

  Future<void> finish(WidgetRef ref) async {
    if (state.isSaving ||
        state.name == null ||
        state.gender == null ||
        state.age == null ||
        state.weightKg == null ||
        state.heightCm == null ||
        state.goal == null) {
      return;
    }

    state = state.copyWith(isSaving: true);

    final profile = UserProfile(
      name: state.name!,
      gender: state.gender!,
      age: state.age!,
      weightKg: state.weightKg!,
      heightCm: state.heightCm!,
      goal: state.goal!,
      conditions: state.conditions,
    );

    await ref.read(userProfileProvider.notifier).save(profile);
    final settings = ref.read(appSettingsProvider).asData?.value;
    if (settings?.notificationsEnabled ?? true) {
      unawaited(
        ref.read(notificationServiceProvider).scheduleContextualReminders(
              profile: profile,
              settings: settings ?? const AppSettings(),
              summary: const DailySummary(dateKey: '', meals: [], waterGlasses: 0),
            ),
      );
    }
    unawaited(
      ref.read(doctorNoteRepositoryProvider).getOrGenerate(
            profile: profile,
            summary: const DailySummary(dateKey: '', meals: [], waterGlasses: 0),
            exercises: const [],
          ),
    );
    unawaited(ref.read(plannerRepositoryProvider).ensureTodayExercises(profile));
    unawaited(ref.read(plannerRepositoryProvider).ensureCurrentWeekMealPlan(profile));

    state = state.copyWith(
      isSaving: false,
      step: OnboardingStep.complete,
      messages: [
        ...state.messages,
        const ChatMessage(
          text: 'দারুণ। আপনার প্রোফাইল সংরক্ষণ করা হয়েছে। এখন থেকে আমি আপনার খাবার, ব্যায়াম আর দৈনিক পরামর্শ ব্যক্তিগতভাবে সাজিয়ে দেব।',
          sender: ChatSender.ai,
        ),
      ],
    );
  }

  void _appendAiMessage(List<ChatMessage> currentMessages, String text) {
    state = state.copyWith(
      messages: [...currentMessages, ChatMessage(text: text, sender: ChatSender.ai)],
    );
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);
