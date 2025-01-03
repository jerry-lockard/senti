import 'package:flutter/foundation.dart';

class SentimentProvider with ChangeNotifier {
  String _lastSentiment = 'neutral';

  String get lastSentiment => _lastSentiment;

  void analyzeSentiment(String text) {
    // Basic sentiment analysis logic
    if (text.contains(RegExp(r'happy|good|great|awesome|love'))) {
      _lastSentiment = 'positive';
    } else if (text.contains(RegExp(r'sad|bad|terrible|hate|angry'))) {
      _lastSentiment = 'negative';
    } else {
      _lastSentiment = 'neutral';
    }
    notifyListeners();
  }

  // More advanced sentiment analysis can be added later
  double calculateSentimentScore(String text) {
    // Placeholder for more complex sentiment scoring
    return 0.0;
  }
}
