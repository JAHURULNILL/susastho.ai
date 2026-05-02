class BengaliFormatters {
  const BengaliFormatters._();

  static const List<String> _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

  static String toBengaliNumber(num value, {int fractionDigits = 0}) {
    final formatted = value.toStringAsFixed(fractionDigits);
    final buffer = StringBuffer();

    for (final char in formatted.split('')) {
      final digit = int.tryParse(char);
      if (digit == null) {
        buffer.write(char == '.' ? '.' : char);
      } else {
        buffer.write(_bnDigits[digit]);
      }
    }
    return buffer.toString();
  }
}
