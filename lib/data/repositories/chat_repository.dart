import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/config/app_config.dart';
import '../../core/network/authorized_dio_provider.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';

/// Repository that exposes chat operations to the app.
class ChatRepository {
  ChatRepository(this._service);

  final ChatService _service;

  /// Get chat messages for a linking.
  Future<ChatMessagesResponse> getLinkingMessages({
    required int linkingId,
    int limit = 100,
    int offset = 0,
  }) {
    return _service.getLinkingMessages(
      linkingId: linkingId,
      limit: limit,
      offset: offset,
    );
  }

  /// Get chat messages for an order.
  Future<ChatMessagesResponse> getOrderMessages({
    required int orderId,
    int limit = 100,
    int offset = 0,
  }) {
    return _service.getOrderMessages(
      orderId: orderId,
      limit: limit,
      offset: offset,
    );
  }

  /// Create a WebSocket connection for linking chat.
  /// Returns the WebSocketChannel for both sending and receiving messages.
  WebSocketChannel connectLinkingChat({
    required int linkingId,
    required String accessToken,
  }) {
    return _service.connectLinkingChat(
      linkingId: linkingId,
      accessToken: accessToken,
    );
  }

  /// Create a WebSocket connection for order chat.
  /// Returns the WebSocketChannel for both sending and receiving messages.
  WebSocketChannel connectOrderChat({
    required int orderId,
    required String accessToken,
  }) {
    return _service.connectOrderChat(
      orderId: orderId,
      accessToken: accessToken,
    );
  }

  /// Parse WebSocket stream data into WebSocketChatMessage objects.
  Stream<WebSocketChatMessage> parseWebSocketStream(Stream<dynamic> stream) {
    return _service.parseWebSocketStream(stream);
  }
}

/// Provider wiring ChatService with authorized Dio instance.
final chatServiceProvider = Provider<ChatService>((ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  final Dio dio = ref.watch(authorizedDioProvider);

  return ChatService(config: config, dioClient: dio);
});

/// Provider that exposes ChatRepository.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final ChatService service = ref.watch(chatServiceProvider);
  return ChatRepository(service);
});

