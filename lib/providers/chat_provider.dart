import 'dart:async';
import 'dart:developer';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:senti/apis/api_service.dart';
import 'package:senti/constants/constants.dart';
import 'package:senti/hive/boxes.dart';
import 'package:senti/hive/chat_history.dart';
import 'package:senti/hive/settings.dart';
import 'package:senti/hive/user_model.dart';
import 'package:senti/models/message.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class ChatProvider extends ChangeNotifier {
  // Existing properties
  bool _navigationLocked = false;
  final List<Message> _inChatMessages = [];
  PageController _pageController = PageController(initialPage: 0);
  List<XFile>? _imagesFileList = [];
  int _currentIndex = 0;
  String _currentChatId = '';
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  // New WebSocket and AI-related properties
  WebSocketChannel? _webSocketChannel;
  String _connectionStatus = 'disconnected';
  String _selectedModel = 'gemini';
  final List<String> _availableModels = ['gemini', 'openai', 'ollama', 'llama'];
  String _lastSentiment = 'neutral';
  bool _isTyping = false;

  // Getters for new properties
  String get connectionStatus => _connectionStatus;
  String get selectedModel => _selectedModel;
  List<String> get availableModels => _availableModels;
  String get lastSentiment => _lastSentiment;
  bool get isTyping => _isTyping;

  // Existing getters
  bool get navigationLocked => _navigationLocked;
  List<Message> get inChatMessages => _inChatMessages;
  PageController get pageController => _pageController;
  List<XFile>? get imagesFileList => _imagesFileList;
  int get currentIndex => _currentIndex;
  String get currentChatId => _currentChatId;
  bool get isLoading => _isLoading;

  ChatProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await dotenv.load();
    initializeWebSocket();
  }

  // WebSocket initialization method
  void initializeWebSocket() {
    try {
      final wsUrl =
          dotenv
              .env['WEBSOCKET_URL_${defaultTargetPlatform.name.toUpperCase()}'] ??
          dotenv.env['WEBSOCKET_URL_WEB'] ??
          dotenv.env['WEBSOCKET_URL_IOS'] ??
          dotenv.env['WEBSOCKET_URL_ANDROID'] ??
          dotenv.env['WEBSOCKET_URL_DEFAULT'];
      _webSocketChannel = IOWebSocketChannel.connect(wsUrl!);
      _connectionStatus = 'connecting';
      _listenToWebSocket();
    } catch (e) {
      _connectionStatus = 'error';
      log('WebSocket connection error: $e');
    }
  }

  void _listenToWebSocket() {
    _webSocketChannel?.stream.listen(
      (message) {
        final data = json.decode(message);
        _handleWebSocketMessage(data);
      },
      onDone: () {
        _connectionStatus = 'disconnected';
        log('WebSocket connection closed');
      },
      onError: (error) {
        _connectionStatus = 'error';
        log('WebSocket error: $error');
      },
    );
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    print('Handling WebSocket message: $data'); // Debug log

    if (data['type'] == 'chat_response') {
      print('Processing chat response'); // Debug log

      final responseText = data['response'];
      print('Response text: $responseText'); // Debug log

      final assistantMessage = Message(
        messageId: const Uuid().v4(),
        chatId: _currentChatId,
        role: Role.assistant,
        message: StringBuffer(responseText),
        timeSent: DateTime.now(),
        isRead: false,
        imagesUrls: [],
      );

      // Add to messages list and persist
      _inChatMessages.add(assistantMessage);

      // Save to Hive DB
      Hive.openBox('${Constants.chatMessagesBox}$_currentChatId').then((box) {
        box.add(assistantMessage.toMap());
      });

      setLoading(value: false);
      notifyListeners();
    } else if (data['type'] == 'error') {
      print('Error from server: ${data['error']}');
      setLoading(value: false);
    } else {
      switch (data['type']) {
        case 'text_response':
          final assistantMessage = Message(
            messageId: const Uuid().v4(),
            chatId: _currentChatId,
            role: Role.assistant,
            message: StringBuffer(data['text']),
            timeSent: DateTime.now(),
            isRead: false,
            imagesUrls: [],
          );
          _inChatMessages.add(assistantMessage);
          break;
        case 'sentiment_analysis':
          _lastSentiment = data['sentiment'];
          break;
        case 'model_changed':
          _selectedModel = data['model'];
          break;
      }
      notifyListeners();
    }
  }

  // Model switching method
  void changeModel(String model) {
    if (_availableModels.contains(model)) {
      _selectedModel = model;

      _webSocketChannel?.sink.add(
        json.encode({'type': 'change_model', 'model': model}),
      );

      notifyListeners();
    }
  }

  // Sentiment analysis method
  void analyzeSentiment(String text) {
    String sentiment;
    if (text.contains(RegExp(r'happy|good|great|awesome|love'))) {
      sentiment = 'positive';
    } else if (text.contains(RegExp(r'sad|bad|terrible|hate|angry'))) {
      sentiment = 'negative';
    } else {
      sentiment = 'neutral';
    }

    _webSocketChannel?.sink.add(
      json.encode({
        'type': 'sentiment_analysis',
        'text': text,
        'sentiment': sentiment,
      }),
    );

    _lastSentiment = sentiment;
    notifyListeners();
  }

  // Typing status method
  void setTypingStatus(bool status) {
    _isTyping = status;
    notifyListeners();
  }

  // Existing method: removeImageAt
  void removeImageAt(int index) {
    imagesFileList?.removeAt(index);
    notifyListeners();
  }

  // Existing method: setInChatMessages
  Future<void> setInChatMessages({required String chatId}) async {
    final messagesFromDB = await loadMessagesFromDB(chatId: chatId);

    for (var message in messagesFromDB) {
      if (_inChatMessages.contains(message)) {
        log('message already exists');
        continue;
      }

      _inChatMessages.add(message);
    }
    notifyListeners();
  }

  // Existing method: loadMessagesFromDB
  Future<List<Message>> loadMessagesFromDB({required String chatId}) async {
    await Hive.openBox('${Constants.chatMessagesBox}$chatId');

    final messageBox = Hive.box('${Constants.chatMessagesBox}$chatId');

    final newData =
        messageBox.keys.map((e) {
          final message = messageBox.get(e);
          final messageData = Message.fromMap(
            Map<String, dynamic>.from(message),
          );

          return messageData;
        }).toList();

    notifyListeners();
    return newData;
  }

  // Existing method: setImagesFileList
  void setImagesFileList({required List<XFile> listValue}) {
    _imagesFileList = listValue;
    notifyListeners();
  }

  // Existing method: _setCurrentIndex
  void _setCurrentIndex({required int newIndex}) {
    if (!_navigationLocked && newIndex >= 0 && newIndex < 2) {
      _currentIndex = newIndex;
      log('Navigating to index: $newIndex');

      if (_pageController.hasClients) {
        _pageController.jumpToPage(newIndex);
      }

      notifyListeners();
    }
  }

  // Existing method: navigateToChat
  void navigateToChat() {
    log('Navigating to Chat Screen');
    _setCurrentIndex(newIndex: 0);
  }

  // Existing method: navigateToProfile
  void navigateToProfile() {
    log('Navigating to Profile Screen');
    _setCurrentIndex(newIndex: 1);
  }

  // Existing method: setCurrentChatId
  void setCurrentChatId({required String newChatId}) {
    _currentChatId = newChatId;
    notifyListeners();
  }

  // Existing method: setLoading
  void setLoading({required bool value}) {
    _isLoading = value;
    notifyListeners();
  }

  // Existing method: deleteChatMessages
  Future<void> deleteChatMessages({required String chatId}) async {
    if (!Hive.isBoxOpen('${Constants.chatMessagesBox}$chatId')) {
      await Hive.openBox('${Constants.chatMessagesBox}$chatId');
      await Hive.box('${Constants.chatMessagesBox}$chatId').clear();
      await Hive.box('${Constants.chatMessagesBox}$chatId').close();
    } else {
      await Hive.box('${Constants.chatMessagesBox}$chatId').clear();
      await Hive.box('${Constants.chatMessagesBox}$chatId').close();
    }

    if (currentChatId.isNotEmpty) {
      if (currentChatId == chatId) {
        setCurrentChatId(newChatId: '');
        _inChatMessages.clear();
        notifyListeners();
      }
    }
  }

  // Existing method: prepareChatRoom
  Future<void> prepareChatRoom({
    required bool isNewChat,
    String? chatID,
  }) async {
    if (isNewChat) {
      String newChatId = getChatId(isNewChat: true);
      print('Generated new chatId: $newChatId');

      _inChatMessages.clear();
      setCurrentChatId(newChatId: newChatId);
    } else {
      if (chatID == null) {
        print('prepareChatRoom called with isNewChat=false but chatID is null');
        return;
      }

      final chatHistory = await loadMessagesFromDB(chatId: chatID);
      _inChatMessages.clear();

      for (var message in chatHistory) {
        _inChatMessages.add(message);
      }

      setCurrentChatId(newChatId: chatID);
    }

    notifyListeners();
    print('prepareChatRoom completed for isNewChat: $isNewChat');
  }

  // Existing method: sentMessage (modified to include WebSocket)
  late WebSocketChannel? channel;

  Future<void> sentMessage({
    required String message,
    required bool isTextOnly,
  }) async {
    try {
      setLoading(value: true);
      final chatId = getChatId();
      print('Preparing to send message...');

      // Create and add user message first
      final userMessage = Message(
        messageId: const Uuid().v4(),
        chatId: chatId,
        role: Role.user,
        message: StringBuffer(message),
        imagesUrls: getImagesUrls(isTextOnly: isTextOnly),
        timeSent: DateTime.now(),
        isRead: false,
      );

      // Add to messages list and persist
      _inChatMessages.add(userMessage);
      notifyListeners();

      // Save to Hive DB
      final messagesBox = await Hive.openBox(
        '${Constants.chatMessagesBox}$chatId',
      );
      await messagesBox.add(userMessage.toMap());

      // Send via WebSocket
      if (_webSocketChannel != null) {
        final payload = {
          'type': 'chat_message',
          'message': message,
          'model': _selectedModel,
          'chatId': chatId,
          'isTextOnly': isTextOnly,
        };

        print('Sending WebSocket payload: $payload');
        _webSocketChannel!.sink.add(json.encode(payload));
        print('Message sent successfully, awaiting response...');
      } else {
        print('WebSocket not connected, attempting reconnection...');
        initializeWebSocket();
        setLoading(value: false);
      }
    } catch (e) {
      print('Error in sentMessage: $e');
      setLoading(value: false);
    }
  }

  // send message to the model and wait for the response
  Future<void> sendMessageAndWaitForResponse({
    required String message,
    required String chatId,
    required bool isTextOnly,
    required List<Content> history,
    required Message userMessage,
    required String modelMessageId,
    required Box messagesBox,
  }) async {
    try {
      // Use ApiService to send the message and get response
      final response = await _apiService.sendMessage(
        message: message,
        history: history,
        isTextOnly: isTextOnly,
      );

      // Create assistant message with the response
      final assistantMessage = userMessage.copyWith(
        messageId: modelMessageId,
        role: Role.assistant,
        message: StringBuffer(response),
        timeSent: DateTime.now(),
        isRead: false,
      );

      // Add assistant message to inChatMessages
      _inChatMessages.add(assistantMessage);
      notifyListeners();

      // Save messages to Hive DB
      await saveMessagesToDB(
        chatID: chatId,
        userMessage: userMessage,
        assistantMessage: assistantMessage,
        messagesBox: messagesBox,
      );

      // Set loading to false
      setLoading(value: false);
    } catch (error) {
      log('ApiService error: $error');
      // Handle error, set loading to false
      setLoading(value: false);
    }
  }

  // save messages to hive db
  Future<void> saveMessagesToDB({
    required String chatID,
    required Message userMessage,
    required Message assistantMessage,
    required Box messagesBox,
  }) async {
    // save the user messages
    await messagesBox.add(userMessage.toMap());

    // save the assistant messages
    await messagesBox.add(assistantMessage.toMap());

    // save chat history with the same chatId
    final chatHistoryBox = Boxes.getChatHistory();

    final chatHistory = ChatHistory(
      chatId: chatID,
      prompt: userMessage.message.toString(),
      response: assistantMessage.message.toString(),
      imagesUrls: userMessage.imagesUrls,
      timestamp: DateTime.now(),
    );
    await chatHistoryBox.put(chatID, chatHistory);

    // close the box
    await messagesBox.close();
  }

  // get the imagesUrls
  List<String> getImagesUrls({required bool isTextOnly}) {
    List<String> imagesUrls = [];
    if (!isTextOnly && imagesFileList != null) {
      for (var image in imagesFileList!) {
        imagesUrls.add(image.path);
      }
    }
    return imagesUrls;
  }

  // Existing method: getHistory
  Future<List<Content>> getHistory({required String chatId}) async {
    List<Content> history = [];

    if (currentChatId.isNotEmpty) {
      await setInChatMessages(chatId: chatId);

      for (var message in inChatMessages) {
        if (message.role == Role.user) {
          history.add(Content.text(message.message.toString()));
        } else {
          history.add(Content.model([TextPart(message.message.toString())]));
        }
      }
    }

    return history;
  }

  // Existing method: getChatId
  String getChatId({bool isNewChat = false}) {
    if (isNewChat || currentChatId.isEmpty) {
      return const Uuid().v4();
    } else {
      return currentChatId;
    }
  }

  // Existing static method: initHive
  static Future<void> initHive() async {
    final dir = await path.getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    await Hive.initFlutter(Constants.geminiDB);

    // register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ChatHistoryAdapter());

      // open the chat history box
      await Hive.openBox<ChatHistory>(Constants.chatHistoryBox);
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserModelAdapter());
      await Hive.openBox<UserModel>(Constants.userBox);
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SettingsAdapter());
      await Hive.openBox<Settings>(Constants.settingsBox);
    }
  }

  void addMessage(String text, {bool isUser = true}) {
    final message = Message(
      message: StringBuffer(text),
      isRead: false,
      messageId: const Uuid().v4(),
      chatId: getChatId(),
      role: isUser ? Role.user : Role.admin,
      imagesUrls: [],
      timeSent: DateTime.now(),
    );
    inChatMessages.add(message);
    notifyListeners();
  }

  void markMessageAsRead(int index) {
    final message = inChatMessages[index];
    inChatMessages[index] = Message(
      message: message.message,
      isRead: true,
      messageId: message.messageId,
      chatId: message.chatId,
      role: message.role,
      imagesUrls: message.imagesUrls,
      timeSent: message.timeSent,
    );
    notifyListeners();
  }

  void resetPageController() {
    _pageController = PageController(initialPage: 0);
    notifyListeners();
  }

  void clearMessages() {
    _inChatMessages.clear();
    notifyListeners();
  }

  Future<void> loadAndShowChat({required String chatId}) async {
    // Make sure we're on chat screen
    _currentIndex = 0;
    notifyListeners();

    // Load the chat
    await prepareChatRoom(isNewChat: false, chatID: chatId);

    // Force UI update
    notifyListeners();
  }

  // Lock navigation to prevent unintended page changes
  void lockNavigation() {
    _navigationLocked = true;
    notifyListeners();
    // Removed invalid log statement
  }

  // Force navigation to Chat Screen
  void forceToChat() {
    _navigationLocked = true;
    navigateToChat();
    _navigationLocked = false;
  }

  @override
  void dispose() {
    _webSocketChannel?.sink.close();
    super.dispose();
  }
}
