import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ApiService {
  static String get apiKey => dotenv.env['API_KEY'] ?? 'API_KEY not found';

  // Add method to handle content extraction based on content type
  String extractTextFromContent(Content response) {
    String generatedText = '';
    if (response.parts.isNotEmpty) {
      for (var part in response.parts) {
        if (part is TextPart) {
          // Check if part is TextPart
          generatedText += part.text;
        }
        // Handle other part types if necessary
      }
    }
    return generatedText.isNotEmpty ? generatedText : 'No response generated';
  }

  // Modify sendMessage to utilize the new extract method
  Future<String> sendMessage({
    required String message,
    required List<Content> history,
    required bool isTextOnly,
  }) async {
    try {
      // Initialize the GenerativeModel with your API key
      final model = GenerativeModel(
        apiKey: apiKey,
        model: 'gemini-2.0-flash-exp', // Updated model name
      );

      // Prepare the prompt with history if available
      String fullPrompt = message;
      if (history.isNotEmpty) {
        for (var content in history) {
          if (content.parts.isNotEmpty && content.parts.first is TextPart) {
            final textPart = content.parts.first as TextPart;
            fullPrompt = "${textPart.text}\n$fullPrompt";
          }
        }
      }

      // Generate the response
      final response = await model.generateContent([Content.text(fullPrompt)]);

      // Extract text from response using the new method
      return extractTextFromContent(response.candidates.first.content);
    } catch (e) {
      throw Exception('Failed to get AI response: $e');
    }
  }
}
