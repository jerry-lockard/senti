import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String get apiKey => dotenv.env['API_KEY'] ?? 'API_KEY not found';
}
