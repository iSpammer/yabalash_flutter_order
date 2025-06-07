class SkuUtils {
  /// Parses a SKU to extract and format the product name
  /// Expected SKU format: com.yabalash.{restaurantName}.{productName}
  /// Example: com.yabalash.BaytAlMouskhan.Fareekahwithchickennn
  /// Returns: "Fareekah With Chicken"
  static String parseSkuToDisplayName(String? sku) {
    if (sku == null || sku.isEmpty) {
      return '';
    }

    try {
      // Handle the standard SKU format: com.yabalash.{restaurant}.{product}
      if (sku.startsWith('com.yabalash.')) {
        final parts = sku.split('.');
        if (parts.length >= 4) {
          // Get the product name part (last segment)
          final productName = parts.last;
          return _formatProductName(productName);
        }
      }

      // If it doesn't match the expected format, try to format it anyway
      return _formatProductName(sku);
    } catch (e) {
      // If parsing fails, return the original SKU
      return sku;
    }
  }

  /// Formats a product name by adding spaces between words
  /// Handles camelCase, PascalCase, and concatenated words
  static String _formatProductName(String productName) {
    if (productName.isEmpty) return '';

    // Remove common suffixes and prefixes if any
    String cleanName = productName;
    
    // Remove trailing numbers that might be duplicates (like "nnn" in "chickennn")
    cleanName = cleanName.replaceAll(RegExp(r'(.)\1{2,}$'), r'$1');
    
    // Add spaces before uppercase letters (for camelCase/PascalCase)
    String spaced = cleanName.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    
    // Add spaces before numbers
    spaced = spaced.replaceAllMapped(
      RegExp(r'([a-zA-Z])(\d)'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    
    // Handle common word patterns that might be concatenated
    spaced = _handleCommonWordPatterns(spaced);
    
    // Clean up multiple spaces and trim
    spaced = spaced.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Capitalize first letter of each word
    return _capitalizeWords(spaced);
  }

  /// Handles common word patterns that might be concatenated
  static String _handleCommonWordPatterns(String text) {
    String result = text.toLowerCase();
    
    // First handle specific food combinations that are commonly concatenated
    final specificPatterns = <String, String>{
      'withchicken': 'with chicken',
      'withbeef': 'with beef',
      'withrice': 'with rice',
      'withmeat': 'with meat',
      'withfish': 'with fish',
      'withsauce': 'with sauce',
      'andchicken': 'and chicken',
      'andbeef': 'and beef',
      'andrice': 'and rice',
      'friedchicken': 'fried chicken',
      'grilledchicken': 'grilled chicken',
      'chickenburger': 'chicken burger',
      'beefburger': 'beef burger',
      'chickenmeal': 'chicken meal',
      'beefmeal': 'beef meal',
      'meatmeal': 'meat meal',
      'chickensandwich': 'chicken sandwich',
      'beefsandwich': 'beef sandwich',
      'fishsandwich': 'fish sandwich',
    };
    
    // Apply specific pattern replacements first
    specificPatterns.forEach((pattern, replacement) {
      result = result.replaceAll(pattern, replacement);
    });
    
    // Then handle individual words that might be concatenated
    final patterns = <String, String>{
      'with': ' with ',
      'and': ' and ',
      'or': ' or ',
      'chicken': ' chicken',
      'beef': ' beef',
      'fish': ' fish',
      'meat': ' meat',
      'rice': ' rice',
      'bread': ' bread',
      'cheese': ' cheese',
      'sauce': ' sauce',
      'salad': ' salad',
      'soup': ' soup',
      'pizza': ' pizza',
      'pasta': ' pasta',
      'burger': ' burger',
      'sandwich': ' sandwich',
      'wrap': ' wrap',
      'meal': ' meal',
      'combo': ' combo',
      'special': ' special',
      'deluxe': ' deluxe',
      'classic': ' classic',
      'fresh': ' fresh',
      'grilled': ' grilled',
      'fried': ' fried',
      'baked': ' baked',
      'spicy': ' spicy',
      'mild': ' mild',
      'hot': ' hot',
      'cold': ' cold',
      'large': ' large',
      'medium': ' medium',
      'small': ' small',
      'regular': ' regular',
    };

    // Apply word pattern replacements for words that don't already have spaces
    patterns.forEach((pattern, replacement) {
      // Look for the pattern that's not already surrounded by spaces
      final regex = RegExp(r'(?<!\s)' + pattern + r'(?!\s)', caseSensitive: false);
      result = result.replaceAll(regex, replacement);
    });
    
    return result;
  }

  /// Capitalizes the first letter of each word
  static String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Example usage and test cases for debugging
  /// Usage: SkuUtils.testParser() - call this in debug mode to verify parsing
  static void testParser() {
    final testCases = [
      'com.yabalash.BaytAlMouskhan.Fareekahwithchickennn',
      'com.yabalash.ElPrince.FriedMeatMeal',
      'com.yabalash.Restaurant.ChickenBurgerCombo',
      'com.yabalash.FastFood.PizzaMargherita',
      'ChickenSandwich',
      'BeefWithRice',
      'friedchickenspecial',
      'GRILLEDFISH',
    ];

    for (final sku in testCases) {
      final parsed = parseSkuToDisplayName(sku);
      // Use debugPrint instead of print for production safety
      assert(() {
        // This only runs in debug mode
        // ignore: avoid_print
        print('SKU: $sku -> Display: $parsed');
        return true;
      }());
    }
  }
}