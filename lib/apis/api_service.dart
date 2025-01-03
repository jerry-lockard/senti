import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart' as io;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  WebSocketChannel? _channel;
  final _responseController = StreamController<String>.broadcast();
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 3;

  // Replace hardcoded URLs with environment variables
  String get websocketUrlAndroid =>
      dotenv.env['WEBSOCKET_URL_ANDROID'] ?? 'ws://localhost:8765';
  String get websocketUrlIOS =>
      dotenv.env['WEBSOCKET_URL_IOS'] ?? 'ws://localhost:8765';
  String get websocketUrlWeb =>
      dotenv.env['WEBSOCKET_URL_WEB'] ?? 'ws://localhost:8765';
  String get websocketUrlDefault =>
      dotenv.env['WEBSOCKET_URL_DEFAULT'] ?? 'ws://localhost:8765';

  ApiService() {
    dev.log('Initializing ApiService');
    _initializeWebSocket();
    _setupReconnection();
    _setupPing();
  }

  void _setupPing() {
    dev.log('Setting up ping timer');
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        dev.log('Sending ping message');
        _channel?.sink.add(json.encode({'type': 'ping'}));
      } else {
        dev.log('Not sending ping - connection inactive');
      }
    });
  }

  void _setupReconnection() {
    dev.log('Setting up reconnection timer');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isConnected) {
        dev.log('Triggering reconnection attempt');
        _initializeWebSocket();
      } else {
        dev.log('Skipping reconnection - already connected');
      }
    });
  }

  String _getWebSocketUrl() {
    dev.log('Getting WebSocket URL for current platform');
    String url;
    if (kIsWeb) {
      url = websocketUrlWeb;
      dev.log('Using Web URL: $url');
    } else if (Platform.isAndroid) {
      url = websocketUrlAndroid;
      dev.log('Using Android URL: $url');
    } else if (Platform.isIOS) {
      url = websocketUrlIOS;
      dev.log('Using iOS URL: $url');
    } else {
      url = websocketUrlDefault;
      dev.log('Using default URL: $url');
    }
    return url;
  }

  String _getPlatformName() {
    dev.log('Getting platform name');
    String platform;
    if (kIsWeb) {
      platform = 'web';
    } else if (Platform.isAndroid) {
      platform = 'android';
    } else if (Platform.isIOS) {
      platform = 'ios';
    } else {
      platform = 'default';
    }
    dev.log('Platform identified as: $platform');
    return platform;
  }

  Future<void> _initializeWebSocket() async {
    dev.log('Starting WebSocket initialization');
    dev.log('Current connection status: $_isConnected');
    dev.log('Current reconnect attempts: $_reconnectAttempts');

    if (_isConnected) {
      dev.log('Already connected, skipping initialization');
      return;
    }

    if (_reconnectAttempts >= maxReconnectAttempts) {
      dev.log('Max reconnection attempts reached, aborting');
      return;
    }

    try {
      final url = _getWebSocketUrl();
      dev.log('Attempting WebSocket connection to: $url');

      if (kIsWeb) {
        dev.log('Creating Web WebSocket channel');
        _channel = WebSocketChannel.connect(Uri.parse(url));
      } else {
        dev.log('Creating IO WebSocket channel');
        _channel = io.IOWebSocketChannel.connect(
          url,
          pingInterval: const Duration(seconds: 10),
          connectTimeout: const Duration(seconds: 5),
        );
      }

      dev.log('WebSocket channel created successfully');

      _channel?.stream.listen(
        (message) {
          dev.log('Received WebSocket message: $message');
          _isConnected = true;
          _reconnectAttempts = 0;

          final data = json.decode(message);

          if (data.containsKey('response')) {
            dev.log('Processing response message');
            _responseController.add(data['response']);
          }
          if (data['type'] == 'pong') {
            dev.log('Received pong response');
            _isConnected = true;
          }
          if (data['type'] == 'broadcast') {
            dev.log('Received broadcast message');
            _responseController.add(data['content']);
          }
          if (data['type'] == 'stream') {
            dev.log('Processing streaming message');
            // Assuming the content is the message chunk
            _responseController.add(data['content']);
          }
        },
        onDone: () {
          dev.log('WebSocket connection closed normally');
          _isConnected = false;
          _handleReconnect();
        },
        onError: (error) {
          dev.log('WebSocket error occurred: $error');
          _isConnected = false;
          _handleReconnect();
        },
        cancelOnError: false,
      );

      dev.log('Sending initial connect message');
      _channel?.sink.add(
        json.encode({'type': 'connect', 'platform': _getPlatformName()}),
      );
    } catch (e, stackTrace) {
      dev.log('Error during WebSocket initialization: $e');
      dev.log('Stack trace: $stackTrace');
      _handleReconnect();
    }
  }

  void _handleReconnect() {
    _reconnectAttempts++;
    dev.log(
      'Handling reconnection attempt $_reconnectAttempts of $maxReconnectAttempts',
    );

    if (_reconnectAttempts < maxReconnectAttempts) {
      _reconnectTimer?.cancel();
      final delay = Duration(seconds: _reconnectAttempts * 2);
      dev.log('Scheduling reconnection attempt in ${delay.inSeconds} seconds');
      _reconnectTimer = Timer(delay, _initializeWebSocket);
    } else {
      dev.log('Max reconnection attempts reached');
    }
  }

  Stream<String> get responses => _responseController.stream;

  bool get isConnected => _isConnected;

  Future<String> sendMessage({
    required String message,
    List<dynamic>? history,
    String provider = 'gemini',
    String? model,
    bool isTextOnly = true,
    bool broadcast = false,
  }) async {
    dev.log('Attempting to send message');
    dev.log('Current connection status: $_isConnected');
    dev.log('Message provider: $provider');
    dev.log('Message model: $model');

    if (!_isConnected) {
      dev.log('Not connected, attempting to initialize WebSocket');
      await _initializeWebSocket();
      if (!_isConnected) {
        dev.log('Failed to establish connection after initialization attempt');
        return 'Connection not available. Please try again later.';
      }
    }

    dev.log('Processing message history');
    final processedHistory =
        history?.map((content) {
          if (content is Map) return content;
          return {'content': content['content'], 'role': 'user'};
        }).toList();

    final payload = json.encode({
      'message': message,
      'history': processedHistory ?? [],
      'provider': provider,
      'model': model,
      'is_text_only': isTextOnly,
      'platform': _getPlatformName(),
      'broadcast': broadcast,
    });

    dev.log('Sending payload: $payload');
    _channel?.sink.add(payload);

    dev.log('Waiting for response');
    return await _responseController.stream.first;
  }

  String extractTextFromContent(dynamic response) {
    dev.log('Extracting text from content');
    final result = response?.toString() ?? 'No response generated';
    dev.log('Extracted text: $result');
    return result;
  }

  void dispose() {
    dev.log('Disposing ApiService');
    dev.log('Canceling ping timer');
    _pingTimer?.cancel();
    dev.log('Canceling reconnect timer');
    _reconnectTimer?.cancel();
    dev.log('Closing WebSocket channel');
    _channel?.sink.close();
    dev.log('Closing response controller');
    _responseController.close();
    dev.log('ApiService disposed');
  }
}
