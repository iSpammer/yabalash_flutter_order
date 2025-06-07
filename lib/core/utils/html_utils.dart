import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

class HtmlUtils {
  /// Strips HTML tags from a string and returns plain text
  /// Provides fallback for malformed HTML
  static String stripHtmlTags(String? htmlString) {
    if (htmlString == null || htmlString.isEmpty) {
      return '';
    }

    try {
      // Parse the HTML
      html_dom.Document document = html_parser.parse(htmlString);
      
      // Extract text content
      String textContent = document.body?.text ?? document.documentElement?.text ?? '';
      
      // Clean up extra whitespace
      return textContent.trim().replaceAll(RegExp(r'\s+'), ' ');
    } catch (e) {
      // Fallback: Simple regex-based HTML tag removal
      try {
        String fallbackText = htmlString
            .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
            .replaceAll('&nbsp;', ' ') // Replace non-breaking spaces
            .replaceAll('&amp;', '&') // Replace HTML entities
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'")
            .replaceAll(RegExp(r'\s+'), ' ') // Clean up whitespace
            .trim();
        
        return fallbackText;
      } catch (e2) {
        // Last resort: return original string
        return htmlString;
      }
    }
  }

  /// Checks if a string contains HTML tags
  static bool containsHtml(String? text) {
    if (text == null || text.isEmpty) {
      return false;
    }
    
    return RegExp(r'<[^>]*>').hasMatch(text);
  }

  /// Safely extracts text from potentially HTML content
  /// Returns the cleaned text or original if no HTML detected
  static String safeExtractText(String? content) {
    if (content == null || content.isEmpty) {
      return '';
    }
    
    if (containsHtml(content)) {
      return stripHtmlTags(content);
    }
    
    return content;
  }

  /// Truncates text to specified length with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    
    return '${text.substring(0, maxLength)}...';
  }

  /// Combines HTML stripping and truncation
  static String safeExtractAndTruncate(String? content, int maxLength) {
    String cleanText = safeExtractText(content);
    return truncateText(cleanText, maxLength);
  }
}