import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_design.dart';
import '../../../../core/widgets/fade_up_item.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../data/models/daily_summary.dart';
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
  late final TextEditingController _controller;
  late final stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) {
          return;
        }
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );

    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ভয়েস ইনপুট চালু করা যাচ্ছে না।')),
        );
      }
      return;
    }

    HapticFeedback.selectionClick();
    setState(() => _isListening = true);
    await _speech.listen(
      localeId: 'bn_BD',
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
      ),
      onResult: (result) {
        final words = result.recognizedWords.trim();
        if (words.isEmpty) {
          return;
        }
        _controller.text = words;
        _controller.selection = TextSelection.collapsed(offset: words.length);
        ref.read(scannerProvider.notifier).updateDescription(words);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scannerProvider, (previous, next) {
      if (next.result != null && previous?.result != next.result) {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => FoodResultBottomSheet(
            result: next.result!,
            imagePath: next.image?.path,
          ),
        );
      }

      if (next.errorMessage != null && previous?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    final state = ref.watch(scannerProvider);

    if (_controller.text != state.description) {
      _controller.value = _controller.value.copyWith(
        text: state.description,
        selection: TextSelection.collapsed(offset: state.description.length),
      );
    }

    final widgets = <Widget>[
      InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ModeChip(
                  label: 'খাবার',
                  selected: state.mode == ScanInputMode.meal,
                  onTap: () => ref.read(scannerProvider.notifier).setMode(ScanInputMode.meal),
                ),
                _ModeChip(
                  label: 'মেনু',
                  selected: state.mode == ScanInputMode.menu,
                  onTap: () => ref.read(scannerProvider.notifier).setMode(ScanInputMode.menu),
                ),
                _ModeChip(
                  label: 'রসিদ',
                  selected: state.mode == ScanInputMode.receipt,
                  onTap: () => ref.read(scannerProvider.notifier).setMode(ScanInputMode.receipt),
                ),
              ],
            ),
            if (state.mode == ScanInputMode.meal) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ModeChip(
                    label: 'সকাল',
                    selected: state.mealSlot == MealSlot.morning,
                    onTap: () => ref.read(scannerProvider.notifier).setMealSlot(MealSlot.morning),
                  ),
                  _ModeChip(
                    label: 'দুপুর',
                    selected: state.mealSlot == MealSlot.lunch,
                    onTap: () => ref.read(scannerProvider.notifier).setMealSlot(MealSlot.lunch),
                  ),
                  _ModeChip(
                    label: 'রাত',
                    selected: state.mealSlot == MealSlot.dinner,
                    onTap: () => ref.read(scannerProvider.notifier).setMealSlot(MealSlot.dinner),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'ছবি',
                    onPressed: state.isAnalyzing
                        ? null
                        : () => ref.read(scannerProvider.notifier).pickAndAnalyze(ref),
                    icon: Icons.camera_alt_rounded,
                    height: 52,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: state.isAnalyzing
                          ? null
                          : () => ref.read(scannerProvider.notifier).analyzeText(ref),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('লিখে'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: state.isAnalyzing ? null : _toggleVoiceInput,
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _isListening ? AppColors.redPale : AppColors.primaryFaint,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isListening ? AppColors.red : AppColors.primaryLight,
                      ),
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening ? AppColors.red : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                TextField(
                  controller: _controller,
                  minLines: 4,
                  maxLines: 5,
                  onChanged: (value) => ref.read(scannerProvider.notifier).updateDescription(value),
                  decoration: InputDecoration(
                    hintText: switch (state.mode) {
                      ScanInputMode.meal => 'যেমন: দুপুরে ভাত, নয়না মাছের ঝোল আর ডাল খেয়েছি',
                      ScanInputMode.menu => 'যেমন: এই মেনু থেকে আমার জন্য ভালো ২টা খাবার বলুন',
                      ScanInputMode.receipt => 'যেমন: এই সপ্তাহের বাজার কতটা স্বাস্থ্যকর?',
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: InkWell(
                    onTap: state.isAnalyzing
                        ? null
                        : () => ref.read(scannerProvider.notifier).analyzeText(ref),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: AppColors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      if (state.image != null) ScanPreviewCard(image: state.image!),
      if (state.isAnalyzing) const AnalysisLoadingSheet(),
      InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('কম দামে ভালো বিকল্প', style: AppTextStyles.cardTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'বাংলাদেশে সহজে পাওয়া যায়, পুষ্টিতে ভালো, আর দামে সাশ্রয়ী এমন খাবারের তুলনা।',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 188,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _affordableAlternatives.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _AffordableAlternativeCard(
                  item: _affordableAlternatives[index],
                ),
              ),
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('পুষ্টি-দৃষ্টি')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          12,
          AppSpacing.screenPadding,
          120,
        ),
        itemCount: widgets.length,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: index == widgets.length - 1 ? 0 : AppSpacing.cardGap),
          child: FadeUpItem(index: index, child: widgets[index]),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryPale : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AffordableAlternativeCard extends StatelessWidget {
  const _AffordableAlternativeCard({required this.item});

  final _AffordableAlternative item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.74,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(13, 44, 28, 0.04),
            offset: Offset(0, 2),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Color.fromRGBO(45, 106, 79, 0.12),
            offset: Offset(0, 18),
            blurRadius: 34,
            spreadRadius: -14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.expensiveFood} বনাম ${item.affordableFood}',
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.keyNutrient,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CompareRow(
            label: item.expensiveFood,
            value: item.expensiveValue,
            icon: 'দামি',
            valueColor: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          _CompareRow(
            label: item.affordableFood,
            value: item.affordableValue,
            icon: 'ভালো',
            valueColor: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            item.reason,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryFaint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              item.verdict,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.valueColor,
  });

  final String label;
  final String value;
  final String icon;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryFaint,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            icon,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AffordableAlternative {
  const _AffordableAlternative({
    required this.expensiveFood,
    required this.affordableFood,
    required this.keyNutrient,
    required this.expensiveValue,
    required this.affordableValue,
    required this.reason,
    required this.verdict,
  });

  final String expensiveFood;
  final String affordableFood;
  final String keyNutrient;
  final String expensiveValue;
  final String affordableValue;
  final String reason;
  final String verdict;
}

const List<_AffordableAlternative> _affordableAlternatives = [
  _AffordableAlternative(
    expensiveFood: 'কমলা',
    affordableFood: 'পেয়ারা',
    keyNutrient: 'ভিটামিন C',
    expensiveValue: 'কম',
    affordableValue: 'বেশি',
    reason: 'পেয়ারায় ভিটামিন C অনেক বেশি, আবার দামও কম ও সহজলভ্য।',
    verdict: 'কমলার থেকে পেয়ারা খান।',
  ),
  _AffordableAlternative(
    expensiveFood: 'মাল্টা',
    affordableFood: 'আমড়া',
    keyNutrient: 'ভিটামিন C',
    expensiveValue: 'মাঝারি',
    affordableValue: 'ভালো',
    reason: 'আমড়ায় টক-ঝাল স্বাদসহ ভিটামিন C ভালো পাওয়া যায়, দামও কম।',
    verdict: 'মাল্টার বদলে আমড়া রাখুন।',
  ),
  _AffordableAlternative(
    expensiveFood: 'আপেল',
    affordableFood: 'পেঁপে',
    keyNutrient: 'ফাইবার',
    expensiveValue: 'মাঝারি',
    affordableValue: 'ভালো',
    reason: 'পেঁপে হজমে সাহায্য করে, ফাইবার দেয়, আর আপেলের চেয়ে সস্তা।',
    verdict: 'আপেলের বদলে পেঁপে খান।',
  ),
  _AffordableAlternative(
    expensiveFood: 'আঙুর',
    affordableFood: 'কুল',
    keyNutrient: 'অ্যান্টিঅক্সিডেন্ট',
    expensiveValue: 'মাঝারি',
    affordableValue: 'ভালো',
    reason: 'মৌসুমি কুলে অ্যান্টিঅক্সিডেন্ট ও ভিটামিন C দুটোই পাওয়া যায়।',
    verdict: 'আঙুরের বদলে কুল বেছে নিন।',
  ),
  _AffordableAlternative(
    expensiveFood: 'কিউই',
    affordableFood: 'লেবু',
    keyNutrient: 'ভিটামিন C',
    expensiveValue: 'ভালো',
    affordableValue: 'খুব ভালো',
    reason: 'লেবু সস্তা, সহজলভ্য, আর প্রতিদিনের ভিটামিন C-র জন্য খুব কার্যকর।',
    verdict: 'কিউইয়ের বদলে লেবু বেশি বাস্তবসম্মত।',
  ),
  _AffordableAlternative(
    expensiveFood: 'কাজু বাদাম',
    affordableFood: 'চিনা বাদাম',
    keyNutrient: 'প্রোটিন',
    expensiveValue: 'ভালো',
    affordableValue: 'ভালো',
    reason: 'চিনা বাদাম সস্তা হয়েও ভালো ফ্যাট ও প্রোটিন দেয়।',
    verdict: 'কাজুর বদলে চিনা বাদাম রাখুন।',
  ),
  _AffordableAlternative(
    expensiveFood: 'আলমন্ড',
    affordableFood: 'ভাজা ছোলা',
    keyNutrient: 'প্রোটিন',
    expensiveValue: 'মাঝারি',
    affordableValue: 'ভালো',
    reason: 'ভাজা ছোলা পেট ভরায়, প্রোটিন দেয়, আর অনেক কম খরচে পাওয়া যায়।',
    verdict: 'আলমন্ডের বদলে ভাজা ছোলা খান।',
  ),
  _AffordableAlternative(
    expensiveFood: 'গ্র্যানোলা',
    affordableFood: 'চিড়া',
    keyNutrient: 'কার্ব',
    expensiveValue: 'ভালো',
    affordableValue: 'ভালো',
    reason: 'চিড়া হালকা, সস্তা, সহজে দুধ বা দইয়ের সাথে খাওয়া যায়।',
    verdict: 'গ্র্যানোলার বদলে চিড়া রাখুন।',
  ),
  _AffordableAlternative(
    expensiveFood: 'ওটস',
    affordableFood: 'লাল চিড়া',
    keyNutrient: 'ফাইবার',
    expensiveValue: 'ভালো',
    affordableValue: 'মাঝারি-ভালো',
    reason: 'লাল চিড়া তুলনামূলক সাশ্রয়ী, দেশি ও দ্রুত খাওয়ার উপযোগী।',
    verdict: 'ওটসের সস্তা বিকল্প লাল চিড়া।',
  ),
  _AffordableAlternative(
    expensiveFood: 'সালমন',
    affordableFood: 'ইলিশ',
    keyNutrient: 'ওমেগা-৩',
    expensiveValue: 'ভালো',
    affordableValue: 'ভালো',
    reason: 'দেশি তেলওয়ালা মাছেও ভালো ফ্যাট পাওয়া যায়, বিদেশি মাছের দরকার পড়ে না।',
    verdict: 'সালমনের বদলে ইলিশ বা দেশি তেলওয়ালা মাছ নিন।',
  ),
  _AffordableAlternative(
    expensiveFood: 'টুনা ক্যান',
    affordableFood: 'রুই মাছ',
    keyNutrient: 'প্রোটিন',
    expensiveValue: 'ভালো',
    affordableValue: 'ভালো',
    reason: 'রুই মাছ তুলনামূলক কম খরচে প্রতিদিনের প্রোটিন জোগায়।',
    verdict: 'টুনার বদলে রুই মাছ খান।',
  ),
  _AffordableAlternative(
    expensiveFood: 'চিকেন সসেজ',
    affordableFood: 'ডিম',
    keyNutrient: 'প্রোটিন',
    expensiveValue: 'মাঝারি',
    affordableValue: 'ভালো',
      reason: 'ডিম কম প্রক্রিয়াজাত, বেশি ব্যবহারিক, আর প্রোটিনও নির্ভরযোগ্য।',
    verdict: 'সসেজের বদলে ডিম ভালো।',
  ),
  _AffordableAlternative(
    expensiveFood: 'প্রোটিন বার',
    affordableFood: 'ডিম + কলা',
    keyNutrient: 'প্রোটিন+এনার্জি',
    expensiveValue: 'মাঝারি',
    affordableValue: 'ভালো',
      reason: 'ডিম আর কলা সহজ, সস্তা, আর প্রকৃত খাবার হিসেবে বেশি উপকারী।',
    verdict: 'প্রোটিন বারের বদলে ডিম-কলা নিন।',
  ),
  _AffordableAlternative(
    expensiveFood: 'ইয়োগার্ট কাপ',
    affordableFood: 'টক দই',
    keyNutrient: 'প্রোবায়োটিক',
    expensiveValue: 'ভালো',
    affordableValue: 'ভালো',
    reason: 'দেশি টক দই হজমের জন্য ভালো, আবার অনেক সস্তা।',
    verdict: 'ইয়োগার্ট কাপের বদলে টক দই খান।',
  ),
  _AffordableAlternative(
    expensiveFood: 'চকলেট সিরিয়াল',
    affordableFood: 'মুড়ি + দুধ',
    keyNutrient: 'হালকা এনার্জি',
    expensiveValue: 'মাঝারি',
    affordableValue: 'ভালো',
      reason: 'মুড়ি সহজপাচ্য ও সস্তা, দুধ দিলে সুষম নাস্তা হয়।',
    verdict: 'সিরিয়ালের বদলে মুড়ি-দুধ রাখুন।',
  ),
  _AffordableAlternative(
    expensiveFood: 'বটলড জুস',
    affordableFood: 'ডাবের পানি',
    keyNutrient: 'হাইড্রেশন',
    expensiveValue: 'কম',
    affordableValue: 'ভালো',
      reason: 'ডাবের পানিতে প্রাকৃতিক ইলেকট্রোলাইট থাকে, অতিরিক্ত চিনি কম।',
    verdict: 'জুসের বদলে ডাবের পানি নিন।',
  ),
  _AffordableAlternative(
    expensiveFood: 'এনার্জি ড্রিংক',
    affordableFood: 'লেবুর শরবত',
    keyNutrient: 'হাইড্রেশন',
    expensiveValue: 'কম',
    affordableValue: 'মাঝারি-ভালো',
      reason: 'লেবুর শরবত কম খরচে সতেজ রাখে, অতিরিক্ত উত্তেজক লাগে না।',
    verdict: 'এনার্জি ড্রিংকের বদলে লেবুর শরবত।',
  ),
  _AffordableAlternative(
    expensiveFood: 'মেয়োনিজ স্যান্ডউইচ',
    affordableFood: 'সবজি ডালখিচুড়ি',
    keyNutrient: 'ফাইবার',
    expensiveValue: 'কম',
    affordableValue: 'ভালো',
    reason: 'খিচুড়িতে ডাল, ভাত, সবজি একসাথে পাওয়া যায়।',
    verdict: 'স্যান্ডউইচের বদলে খিচুড়ি ভালো।',
  ),
  _AffordableAlternative(
    expensiveFood: 'ফ্রেঞ্চ ফ্রাই',
    affordableFood: 'সিদ্ধ আলু ভর্তা',
    keyNutrient: 'কম তেল',
    expensiveValue: 'কম',
    affordableValue: 'ভালো',
    reason: 'সিদ্ধ আলু ভর্তায় তেল কম লাগে, পেটও ভরে।',
    verdict: 'ফ্রেঞ্চ ফ্রাইয়ের বদলে আলু ভর্তা।',
  ),
  _AffordableAlternative(
    expensiveFood: 'বিফ বার্গার',
    affordableFood: 'ডাল + ডিম',
    keyNutrient: 'প্রোটিন',
    expensiveValue: 'ভালো',
    affordableValue: 'ভালো',
    reason: 'ডাল আর ডিম মিলে কম খরচে ভালো প্রোটিন দেয়।',
    verdict: 'বার্গারের বদলে ডাল-ডিম নিন।',
  ),
  _AffordableAlternative(
    expensiveFood: 'চিজ পাস্তা',
    affordableFood: 'সবজি সেমাই',
    keyNutrient: 'হালকা কার্ব',
    expensiveValue: 'মাঝারি',
    affordableValue: 'মাঝারি-ভালো',
    reason: 'সবজি সেমাই কম তেলেও করা যায়, হজমেও হালকা।',
    verdict: 'পাস্তার বদলে সবজি সেমাই ভালো।',
  ),
  _AffordableAlternative(
    expensiveFood: 'প্যাকেটেড স্যুপ',
    affordableFood: 'ডাল স্যুপ',
    keyNutrient: 'প্রোটিন',
    expensiveValue: 'কম',
    affordableValue: 'ভালো',
      reason: 'ডাল স্যুপে লবণ কম রেখে ঘরে ভালো পুষ্টি পাওয়া যায়।',
    verdict: 'প্যাকেট স্যুপের বদলে ডাল স্যুপ।',
  ),
  _AffordableAlternative(
    expensiveFood: 'চিপস',
    affordableFood: 'চিনা বাদাম',
    keyNutrient: 'স্ন্যাক',
    expensiveValue: 'কম',
    affordableValue: 'ভালো',
      reason: 'চিনা বাদাম বেশি পেট ভরায়, ফ্যাট-প্রোটিনও দেয়।',
    verdict: 'চিপসের বদলে বাদাম বেছে নিন।',
  ),
  _AffordableAlternative(
    expensiveFood: 'বিস্কুট',
    affordableFood: 'চিড়া-মুড়ি মিক্স',
    keyNutrient: 'কম চিনি',
    expensiveValue: 'কম',
    affordableValue: 'মাঝারি-ভালো',
      reason: 'চিড়া-মুড়ি মিশিয়ে প্রক্রিয়াজাত চিনি কমিয়ে নাস্তা করা যায়।',
    verdict: 'বিস্কুটের বদলে চিড়া-মুড়ি।',
  ),
  _AffordableAlternative(
    expensiveFood: 'আইসক্রিম',
    affordableFood: 'টক দই + ফল',
    keyNutrient: 'কম চিনি',
    expensiveValue: 'কম',
    affordableValue: 'ভালো',
      reason: 'টক দই ও ফল মিলে হালকা মিষ্টি খাবার হয়, রক্তে শর্করার ওঠানামাও তুলনামূলক কম।',
    verdict: 'আইসক্রিমের বদলে টক দই-ফল খান।',
  ),
  _AffordableAlternative(
    expensiveFood: 'রেডিমেড শেক',
    affordableFood: 'কলা-দুধ-চিনাবাদাম',
    keyNutrient: 'এনার্জি',
    expensiveValue: 'মাঝারি',
    affordableValue: 'ভালো',
      reason: 'ঘরের শরবত বা শেক কম খরচে বেশি পুষ্টি দেয়।',
    verdict: 'রেডিমেড শেকের বদলে ঘরের শেক নিন।',
  ),
];
