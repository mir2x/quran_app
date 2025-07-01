extension BengaliDigit on int {
  String toBengaliDigit() {
    const Map<String, String> englishToBengali = {
      '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
      '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯',
    };

    // Convert the integer to a string first, then map each character.
    return toString().split('').map((char) => englishToBengali[char] ?? char).join();
  }
}