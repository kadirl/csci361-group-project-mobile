import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/providers/auth_provider.dart';
import '../../data/models/chat.dart';
import '../../data/repositories/chat_repository.dart';

/// State for a chat session (either linking or order chat).
class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isConnected = false,
    this.error,
    this.chatId,
    this.linkingId,
    this.orderId,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isConnected;
  final String? error;
  final int? chatId;
  final int? linkingId;
  final int? orderId;

  /// Check if this is a linking chat.
  bool get isLinkingChat => linkingId != null;

  /// Check if this is an order chat.
  bool get isOrderChat => orderId != null;

  /// CopyWith method for immutability.
  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isConnected,
    String? error,
    int? chatId,
    int? linkingId,
    int? orderId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      error: error,
      chatId: chatId ?? this.chatId,
      linkingId: linkingId ?? this.linkingId,
      orderId: orderId ?? this.orderId,
    );
  }

  /// Add a new message to the list.
  ChatState addMessage(ChatMessage message) {
    final List<ChatMessage> updatedMessages = List<ChatMessage>.from(messages)..add(message);
    return copyWith(messages: updatedMessages);
  }

  /// Update an existing message.
  ChatState updateMessage(int messageId, ChatMessage updatedMessage) {
    final List<ChatMessage> updatedMessages = messages.map((msg) {
      return msg.messageId == messageId ? updatedMessage : msg;
    }).toList();
    return copyWith(messages: updatedMessages);
  }
}

/// Notifier for managing chat state and WebSocket connections.
class ChatNotifier extends Notifier<ChatState> {
  StreamSubscription<WebSocketChatMessage>? _wsSubscription;
  WebSocketChannel? _wsChannel;
  ChatRepository? _repository;

  @override
  ChatState build() {
    _repository = ref.read(chatRepositoryProvider);
    
    // Clean up WebSocket connection when provider is disposed
    ref.onDispose(() {
      disconnect();
    });
    
    return const ChatState();
  }

  /// Load initial messages and connect WebSocket for a linking chat.
  Future<void> connectLinkingChat({required int linkingId}) async {
    // Disconnect any existing connection
    await disconnect();

    state = state.copyWith(
      isLoading: true,
      error: null,
      linkingId: linkingId,
      orderId: null,
    );

    try {
      final String? accessToken = ref.read(authProvider).accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('No access token available');
      }

      // Load initial messages
      final ChatMessagesResponse response = await _repository!.getLinkingMessages(
        linkingId: linkingId,
        limit: 100,
        offset: 0,
      );

      // Connect WebSocket
      _wsChannel = _repository!.connectLinkingChat(
        linkingId: linkingId,
        accessToken: accessToken,
      );

      final Stream<WebSocketChatMessage> wsStream = _repository!.parseWebSocketStream(_wsChannel!.stream);

      _wsSubscription = wsStream.listen(
        _handleWebSocketMessage,
        onError: (error) {
          log('ChatNotifier -> WebSocket error: $error');
          state = state.copyWith(
            error: 'WebSocket connection error: $error',
            isConnected: false,
          );
        },
        onDone: () {
          log('ChatNotifier -> WebSocket connection closed');
          state = state.copyWith(isConnected: false);
        },
        cancelOnError: false,
      );

      state = state.copyWith(
        messages: response.messages,
        chatId: response.chatId,
        isLoading: false,
        isConnected: true,
      );
    } catch (e, stackTrace) {
      log('ChatNotifier -> Error connecting to linking chat: $e', error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isConnected: false,
      );
    }
  }

  /// Load initial messages and connect WebSocket for an order chat.
  Future<void> connectOrderChat({required int orderId}) async {
    // Disconnect any existing connection
    await disconnect();

    state = state.copyWith(
      isLoading: true,
      error: null,
      orderId: orderId,
      linkingId: null,
    );

    try {
      final String? accessToken = ref.read(authProvider).accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('No access token available');
      }

      // Load initial messages
      final ChatMessagesResponse response = await _repository!.getOrderMessages(
        orderId: orderId,
        limit: 100,
        offset: 0,
      );

      // Connect WebSocket
      _wsChannel = _repository!.connectOrderChat(
        orderId: orderId,
        accessToken: accessToken,
      );

      final Stream<WebSocketChatMessage> wsStream = _repository!.parseWebSocketStream(_wsChannel!.stream);

      _wsSubscription = wsStream.listen(
        _handleWebSocketMessage,
        onError: (error) {
          log('ChatNotifier -> WebSocket error: $error');
          state = state.copyWith(
            error: 'WebSocket connection error: $error',
            isConnected: false,
          );
        },
        onDone: () {
          log('ChatNotifier -> WebSocket connection closed');
          state = state.copyWith(isConnected: false);
        },
        cancelOnError: false,
      );

      state = state.copyWith(
        messages: response.messages,
        chatId: response.chatId,
        isLoading: false,
        isConnected: true,
      );
    } catch (e, stackTrace) {
      log('ChatNotifier -> Error connecting to order chat: $e', error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isConnected: false,
      );
    }
  }

  /// Send a message through the WebSocket connection.
  Future<void> sendMessage({required String body, MessageType type = MessageType.text}) async {
    if (_wsChannel == null || !state.isConnected) {
      throw Exception('WebSocket is not connected');
    }

    try {
      final ChatMessage messageToSend = ChatMessage(
        messageId: 0, // Will be set by server
        chatId: state.chatId ?? 0,
        senderId: 0, // Will be set by server
        body: body,
        messageType: type,
        sentAt: DateTime.now().toIso8601String(),
      );

      final String jsonMessage = jsonEncode(messageToSend.toJson());
      _wsChannel!.sink.add(jsonMessage);
    } catch (e) {
      log('ChatNotifier -> Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Handle incoming WebSocket messages.
  void _handleWebSocketMessage(WebSocketChatMessage wsMessage) {
    switch (wsMessage.type) {
      case WebSocketMessageType.connection:
        log('ChatNotifier -> WebSocket connected: ${wsMessage.message}');
        if (wsMessage.chatId != null) {
          state = state.copyWith(
            chatId: wsMessage.chatId,
            isConnected: true,
          );
        }
        break;

      case WebSocketMessageType.message:
        final ChatMessage? chatMessage = wsMessage.toChatMessage();
        if (chatMessage != null) {
          // Check if message already exists (avoid duplicates)
          final bool messageExists = state.messages.any((msg) => msg.messageId == chatMessage.messageId);
          if (!messageExists) {
            state = state.addMessage(chatMessage);
          }
        }
        break;

      case WebSocketMessageType.messageSent:
        log('ChatNotifier -> Message sent confirmation: ${wsMessage.messageId}');
        // Server confirms message was sent, message should already be in the list
        // from the broadcast, but we can update the sent_at timestamp if needed
        break;

      case WebSocketMessageType.error:
        log('ChatNotifier -> WebSocket error message: ${wsMessage.message}');
        state = state.copyWith(error: wsMessage.message ?? 'Unknown error');
        break;
    }
  }

  /// Disconnect from the current chat.
  Future<void> disconnect() async {
    await _wsSubscription?.cancel();
    _wsSubscription = null;

    await _wsChannel?.sink.close();
    _wsChannel = null;

    state = const ChatState();
  }
}

/// Provider for linking chat state.
/// Use this provider for linking-based chats.
final linkingChatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);

/// Provider for order chat state.
/// Use this provider for order-based chats.
final orderChatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);

