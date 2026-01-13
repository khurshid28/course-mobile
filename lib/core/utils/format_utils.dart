class FormatUtils {
  /// Format price with space separator
  /// Example: 200000 -> "200 000"
  static String formatPrice(dynamic price) {
    if (price == null) return '0';

    int priceInt;
    if (price is String) {
      priceInt = int.tryParse(price) ?? 0;
    } else if (price is num) {
      priceInt = price.toInt();
    } else {
      return '0';
    }

    // Convert to string and add space separator
    String priceStr = priceInt.toString();
    String result = '';

    int count = 0;
    for (int i = priceStr.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = ' $result';
        count = 0;
      }
      result = priceStr[i] + result;
      count++;
    }

    return result;
  }

  /// Format phone number
  /// Example: 998901234567 -> "+998 90 123 45 67"
  static String formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '';

    // Remove all non-digit characters
    String digits = phone.replaceAll(RegExp(r'\D'), '');

    // If starts with 998, format it
    if (digits.startsWith('998') && digits.length == 12) {
      return '+${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 8)} ${digits.substring(8, 10)} ${digits.substring(10, 12)}';
    }

    // Otherwise return with + prefix
    return digits.isNotEmpty ? '+$digits' : phone;
  }
}
