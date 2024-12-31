import 'dart:async';
import 'dart:developer';
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
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier {
  // Add new field and getter
  bool _navigationLocked = false;
  bool get navigationLocked => _navigationLocked;

  // list of messages
  final List<Message> _inChatMessages = [];

  // page controller - update initial page count to match new navigation
  PageController _pageController = PageController(initialPage: 0);

  // images file list
  List<XFile>? _imagesFileList = [];

  // index of the current screen
  int _currentIndex = 0;

  // current chatId
  String _currentChatId = '';

  // loading bool
  bool _isLoading = false;

  // Re-add ApiService instance
  final ApiService _apiService = ApiService();

  // getters
  List<Message> get inChatMessages => _inChatMessages;

  PageController get pageController => _pageController;

  List<XFile>? get imagesFileList => _imagesFileList;

  int get currentIndex => _currentIndex;

  String get currentChatId => _currentChatId;

  bool get isLoading => _isLoading;

  void removeImageAt(int index) {
    imagesFileList?.removeAt(index);
    notifyListeners();
  }

  // setters

  // set inChatMessages
  Future<void> setInChatMessages({required String chatId}) async {
    // get messages from hive database
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

  // load the messages from db
  Future<List<Message>> loadMessagesFromDB({required String chatId}) async {
    // open the box of this chatID
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

  // set file list
  void setImagesFileList({required List<XFile> listValue}) {
    _imagesFileList = listValue;
    notifyListeners();
  }

  // Make setCurrentIndex private
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

  // Add specific navigation methods
  void navigateToChat() {
    log('Navigating to Chat Screen');
    _setCurrentIndex(newIndex: 0);
  }

  void navigateToProfile() {
    log('Navigating to Profile Screen');
    _setCurrentIndex(newIndex: 1);
  }

  // set current chat id
  void setCurrentChatId({required String newChatId}) {
    _currentChatId = newChatId;
    notifyListeners();
  }

  // set loading
  void setLoading({required bool value}) {
    _isLoading = value;
    notifyListeners();
  }

  // delete chat
  Future<void> deleteChatMessages({required String chatId}) async {
    // 1. check if the box is open
    if (!Hive.isBoxOpen('${Constants.chatMessagesBox}$chatId')) {
      // open the box
      await Hive.openBox('${Constants.chatMessagesBox}$chatId');

      // delete all messages in the box
      await Hive.box('${Constants.chatMessagesBox}$chatId').clear();

      // close the box
      await Hive.box('${Constants.chatMessagesBox}$chatId').close();
    } else {
      // delete all messages in the box
      await Hive.box('${Constants.chatMessagesBox}$chatId').clear();

      // close the box
      await Hive.box('${Constants.chatMessagesBox}$chatId').close();
    }

    // get the current chatId, if it's not empty
    if (currentChatId.isNotEmpty) {
      if (currentChatId == chatId) {
        setCurrentChatId(newChatId: '');
        _inChatMessages.clear();
        notifyListeners();
      }
    }
  }

  // prepare chat room
  Future<void> prepareChatRoom({
    required bool isNewChat,
    String? chatID,
  }) async {
    if (isNewChat) {
      // Generate a new chatId
      String newChatId = getChatId(isNewChat: true);
      print('Generated new chatId: $newChatId'); // Debug log

      // Clear existing messages and set new chatId
      _inChatMessages.clear();
      setCurrentChatId(newChatId: newChatId);
    } else {
      if (chatID == null) {
        print('prepareChatRoom called with isNewChat=false but chatID is null');
        return;
      }
      // Load chat history
      final chatHistory = await loadMessagesFromDB(chatId: chatID);
      _inChatMessages.clear();
      for (var message in chatHistory) {
        _inChatMessages.add(message);
      }
      setCurrentChatId(newChatId: chatID);
    }
    notifyListeners();
    print('prepareChatRoom completed for isNewChat: $isNewChat'); // Debug log
  }

  // send message to gemini and get the streamed response
  Future<void> sentMessage({
    required String message,
    required bool isTextOnly,
  }) async {
    // set loading
    setLoading(value: true);

    // get the chatId
    String chatId = getChatId();

    // list of history messages
    List<Content> history = [];

    // get the chat history
    history = await getHistory(chatId: chatId);

    // get the imagesUrls
    List<String> imagesUrls = getImagesUrls(isTextOnly: isTextOnly);

    // open the messages box
    final messagesBox = await Hive.openBox(
      '${Constants.chatMessagesBox}$chatId',
    );

    // get the last user message id
    final userMessageId = messagesBox.keys.length;

    // assistant messageId
    final assistantMessageId = messagesBox.keys.length + 1;

    // user message
    final userMessage = Message(
      messageId: userMessageId.toString(),
      chatId: chatId,
      role: Role.user,
      message: StringBuffer(message),
      imagesUrls: imagesUrls,
      timeSent: DateTime.now(),
      isRead: false, // Initialize isRead
    );

    // add this message to the list on inChatMessages
    _inChatMessages.add(userMessage);
    notifyListeners();

    if (currentChatId.isEmpty) {
      setCurrentChatId(newChatId: chatId);
    }

    // send the message to the model and wait for the response
    await sendMessageAndWaitForResponse(
      message: message,
      chatId: chatId,
      isTextOnly: isTextOnly,
      history: history,
      userMessage: userMessage,
      modelMessageId: assistantMessageId.toString(),
      messagesBox: messagesBox,
    );
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

  String getChatId({bool isNewChat = false}) {
    if (isNewChat || currentChatId.isEmpty) {
      return const Uuid().v4();
    } else {
      return currentChatId;
    }
  }

  // init Hive box
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
}
