extension ArabicDigit on int {
  /// Converts an integer to its Eastern Arabic numeral representation.
  String toArabicDigit() {
    String numberStr = toString();
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    for (int i = 0; i < english.length; i++) {
      numberStr = numberStr.replaceAll(english[i], arabic[i]);
    }
    return numberStr;
  }
}