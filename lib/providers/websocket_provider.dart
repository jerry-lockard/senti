import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class WebSocketProvider with ChangeNotifier {
  WebSocketChannel? _channel;
  final List<Map<String, dynamic>> _messages = [];
  String _connectionStatus = 'disconnected';
  String _selectedModel = 'gemini';
  final List<String> _availableModels = ['gemini', 'openai', 'ollama', 'llama'];
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const int maxReconnectDelay = 30;

  // Getters remain the same
  WebSocketChannel? get channel => _channel;
  List<Map<String, dynamic>> get messages => _messages;
  String get connectionStatus => _connectionStatus;
  String get selectedModel => _selectedModel;
  List<String> get availableModels => _availableModels;

  WebSocketProvider() {
    _initializeWebSocket();
  }

  void _initializeWebSocket() {
    if (_isConnecting) return;
    _isConnecting = true;

    try {
      // Use environment variable with a fallback value
      final wsUrl = dotenv.env['WEBSOCKET_URL'] ?? 'ws://localhost:8765';
      print('Attempting to connect to WebSocket at: $wsUrl');

      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        pingInterval: const Duration(seconds: 30),
      );

      _connectionStatus = 'connecting';
      _listenToWebSocket();
    } catch (e) {
      print('Failed to initialize WebSocket: $e');
      _handleConnectionError();
    } finally {
      _isConnecting = false;
    }
  }

  // Listen for messages and handle connection lifecycle
  void _listenToWebSocket() {
    _channel?.stream.listen(
      (message) {
        print('Received message: $message');
        try {
          final data = json.decode(message);
          _handleServerResponse(data);
          _connectionStatus = 'connected';
          _reconnectAttempts = 0;
          notifyListeners();
        } catch (e) {
          print('Error processing message: $e');
        }
      },
      onDone: () {
        print('WebSocket connection closed');
        _handleConnectionError();
      },
      onError: (error) {
        print('WebSocket error: $error');
        _handleConnectionError();
      },
      cancelOnError: false,
    );
  }

  // Handle connection error and attempt to reconnect
  void _handleConnectionError() {
    _connectionStatus = 'disconnected';
    _channel?.sink.close();
    _channel = null;

    if (_reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      print(
        'Attempting to reconnect (${_reconnectAttempts}/$maxReconnectAttempts)',
      );

      // Exponential backoff for reconnect attempts
      final delay = Duration(
        seconds:
            _reconnectAttempts < maxReconnectDelay
                ? _reconnectAttempts * 2
                : maxReconnectDelay,
      );
      Future.delayed(delay, _initializeWebSocket);
    } else {
      print('Max reconnect attempts reached');
    }

    notifyListeners();
  }

  // Change the model on the server
  void changeModel(String model) {
    if (_availableModels.contains(model)) {
      _selectedModel = model;
      if (_channel != null) {
        _channel?.sink.add(
          json.encode({'type': 'change_model', 'model': model}),
        );
      }
      notifyListeners();
    }
  }

  // Send a message to the WebSocket server
  void sendMessage(String message) {
    if (_connectionStatus != 'connected') {
      print('WebSocket not connected, attempting to reconnect...');
      _initializeWebSocket();
      return;
    }

    try {
      _channel?.sink.add(
        json.encode({
          'type': 'chat_message',
          'message': message,
          'model': _selectedModel,
        }),
      );

      _messages.add({
        'text': message,
        'isUser': true,
        'timestamp': DateTime.now().toIso8601String(),
      });

      notifyListeners();
    } catch (e) {
      print('Error sending message: $e');
      _handleConnectionError();
    }
  }

  // Handle server responses and process incoming messages
  void _handleServerResponse(Map<String, dynamic> data) {
    if (data['type'] == 'chat_response') {
      _messages.add({
        'text': data['response'],
        'isUser': false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
    notifyListeners();
  }

  // Dispose the WebSocket connection when the provider is disposed
  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
