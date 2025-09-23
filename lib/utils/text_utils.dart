/// Utility functions for safe text handling
class TextUtils {
  /// Sanitizes a string to ensure it's valid UTF-16
  static String sanitizeText(String? text) {
    if (text == null) return '';
    
    try {
      // First, try to validate the string
      if (!isValidUtf16(text)) {
        // If invalid, try to fix it by removing problematic characters
        final fixed = text
            .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '') // Remove control characters
            .replaceAll(RegExp(r'[\uFFFE\uFFFF]'), '') // Remove invalid Unicode characters
            .replaceAll(RegExp(r'[\uD800-\uDFFF]'), '') // Remove surrogate pairs that might be malformed
            .trim();
        
        // If still invalid, return a safe fallback
        return isValidUtf16(fixed) ? fixed : 'Invalid text';
      }
      
      // If valid, just clean up control characters
      return text
          .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '') // Remove control characters
          .replaceAll(RegExp(r'[\uFFFE\uFFFF]'), '') // Remove invalid Unicode characters
          .trim();
    } catch (e) {
      // If there's any error, return a safe fallback
      return 'Invalid text';
    }
  }
  
  /// Safely converts a string to display text, handling null and invalid characters
  static String safeDisplayText(String? text, {String fallback = ''}) {
    if (text == null || text.isEmpty) return fallback;
    
    final sanitized = sanitizeText(text);
    return sanitized.isEmpty ? fallback : sanitized;
  }
  
  /// Validates if a string is valid UTF-16
  static bool isValidUtf16(String text) {
    try {
      // Try to encode and decode to check validity
      final bytes = text.codeUnits;
      String.fromCharCodes(bytes);
      return true;
    } catch (e) {
      return false;
    }
  }
}
