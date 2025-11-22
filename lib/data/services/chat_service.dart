import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/config/app_config.dart';
import '../models/chat.dart';

/// Service handling chat operations including REST API calls and WebSocket connections.
class ChatService {
  ChatService({required this.config, Dio? dioClient})
      : _dio = dioClient ??
            Dio(
              BaseOptions(
                baseUrl: config.apiRoot,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: const <String, Object?>{
                  Headers.acceptHeader: 'application/json',
                  Headers.contentTypeHeader: 'application/json',
                },
              ),
            );

  final AppConfig config;
  final Dio _dio;

  static const String _chatPath = 'chat/';
  static const String _messagesPath = '${_chatPath}messages/';

  /// Get chat messages for a linking.
  Future<ChatMessagesResponse> getLinkingMessages({
    required int linkingId,
    int limit = 100,
    int offset = 0,
  }) async {
    final String path = '${_messagesPath}$linkingId';
    log('ChatService -> GET $path?limit=$limit&offset=$offset');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        path,
        queryParameters: <String, dynamic>{
          'limit': limit,
          'offset': offset,
        },
      );

      final dynamic body = response.data;
      if (body is Map<String, dynamic>) {
        return ChatMessagesResponse.fromJson(body);
      }
      if (body is Map<dynamic, dynamic>) {
        return ChatMessagesResponse.fromJson(Map<String, dynamic>.from(body));
      }

      throw const FormatException('Unexpected chat messages payload format.');
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Get chat messages for an order.
  Future<ChatMessagesResponse> getOrderMessages({
    required int orderId,
    int limit = 100,
    int offset = 0,
  }) async {
    final String path = '${_messagesPath}order/$orderId';
    log('ChatService -> GET $path?limit=$limit&offset=$offset');

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        path,
        queryParameters: <String, dynamic>{
          'limit': limit,
          'offset': offset,
        },
      );

      final dynamic body = response.data;
      if (body is Map<String, dynamic>) {
        return ChatMessagesResponse.fromJson(body);
      }
      if (body is Map<dynamic, dynamic>) {
        return ChatMessagesResponse.fromJson(Map<String, dynamic>.from(body));
      }

      throw const FormatException('Unexpected chat messages payload format.');
    } on DioException catch (error, stackTrace) {
      _logAndRethrow(error, stackTrace);
    }
  }

  /// Create a WebSocket connection for linking chat.
  /// Returns the WebSocketChannel for both sending and receiving messages.
  WebSocketChannel connectLinkingChat({
    required int linkingId,
    required String accessToken,
  }) {
    final String wsUrl = _buildWebSocketUrl(
      path: '${_chatPath}ws/$linkingId',
      token: accessToken,
    );

    log('ChatService -> WebSocket connecting to linking chat: $linkingId');

    return WebSocketChannel.connect(Uri.parse(wsUrl));
  }

  /// Create a WebSocket connection for order chat.
  /// Returns the WebSocketChannel for both sending and receiving messages.
  WebSocketChannel connectOrderChat({
    required int orderId,
    required String accessToken,
  }) {
    final String wsUrl = _buildWebSocketUrl(
      path: '${_chatPath}ws/order/$orderId',
      token: accessToken,
    );

    log('ChatService -> WebSocket connecting to order chat: $orderId');

    return WebSocketChannel.connect(Uri.parse(wsUrl));
  }

  /// Parse WebSocket stream data into WebSocketChatMessage objects.
  Stream<WebSocketChatMessage> parseWebSocketStream(Stream<dynamic> stream) {
    return stream
        .map((dynamic data) {
          try {
            final String jsonString = data is String ? data : utf8.decode(data);
            final Map<String, dynamic> json = jsonDecode(jsonString) as Map<String, dynamic>;
            return WebSocketChatMessage.fromJson(json);
          } catch (e) {
            log('ChatService -> Error parsing WebSocket message: $e');
            return null;
          }
        })
        .where((WebSocketChatMessage? msg) => msg != null)
        .cast<WebSocketChatMessage>();
  }

  /// Build WebSocket URL with token query parameter.
  String _buildWebSocketUrl({required String path, required String token}) {
    final String baseUrl = config.apiRoot.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
    final Uri uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}/$path?token=$token';
  }

  Never _logAndRethrow(DioException error, StackTrace stackTrace) {
    log(
      'ChatService DioException: ${error.type} - ${error.message}',
      error: error,
      stackTrace: stackTrace,
    );

    Error.throwWithStackTrace(
      Exception(error.message ?? 'Network error while processing chat request'),
      stackTrace,
    );
  }
}

