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
}
