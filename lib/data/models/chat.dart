import 'package:flutter/foundation.dart';

/// Message type enum matching backend message types.
enum MessageType {
  text,
  image,
  file,
  audio,
  complaint, // Update message type
  order, // Update message type
}

/// Parse a raw message type string from backend into a MessageType enum.
MessageType parseMessageType(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'text':
      return MessageType.text;
    case 'image':
      return MessageType.image;
    case 'file':
      return MessageType.file;
    case 'audio':
      return MessageType.audio;
    case 'complaint':
      return MessageType.complaint;
    case 'order':
      return MessageType.order;
    default:
      return MessageType.text;
  }
}

/// Check if a message type is an update message (system message).
bool isUpdateMessage(MessageType type) {
  return type == MessageType.complaint || type == MessageType.order;
}

/// Extension to convert MessageType to API string value.
extension MessageTypeX on MessageType {
  String get apiValue => name;
}

/// Immutable representation of a chat message.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.body,
    required this.messageType,
    required this.sentAt,
    this.senderName,
  });

  final int messageId;
  final int chatId;
  final int senderId;
  final String body;
  final MessageType messageType;
  final String sentAt;
  final String? senderName;

  /// Build an instance from the backend payload.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: (json['message_id'] as int?) ?? 0,
      chatId: (json['chat_id'] as int?) ?? 0,
      senderId: (json['sender_id'] as int?) ?? 0,
      body: json['body'] as String? ?? '',
      messageType: parseMessageType(json['type'] as String? ?? json['message_type'] as String?),
      sentAt: json['sent_at'] as String? ?? '',
      senderName: json['sender_name'] as String?,
    );
  }

  /// Convert to API payload for sending messages.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'body': body,
      'type': messageType.apiValue,
    };
  }

  /// Create a copy with updated fields.
  ChatMessage copyWith({
    int? messageId,
    int? chatId,
    int? senderId,
    String? body,
    MessageType? messageType,
    String? sentAt,
    String? senderName,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      body: body ?? this.body,
      messageType: messageType ?? this.messageType,
      sentAt: sentAt ?? this.sentAt,
      senderName: senderName ?? this.senderName,
    );
  }
}

/// Response from GET /chat/messages/{linking_id} or /chat/messages/order/{order_id}
@immutable
class ChatMessagesResponse {
  const ChatMessagesResponse({
    required this.chatId,
    required this.messages,
    required this.limit,
    required this.offset,
    this.linkingId,
    this.orderId,
  });

  final int chatId;
  final List<ChatMessage> messages;
  final int limit;
  final int offset;
  final int? linkingId;
  final int? orderId;

  /// Build an instance from the backend payload.
  factory ChatMessagesResponse.fromJson(Map<String, dynamic> json) {
    List<ChatMessage> messagesList = [];
    if (json['messages'] != null && json['messages'] is List) {
      messagesList = (json['messages'] as List)
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(ChatMessage.fromJson)
          .toList();
    }

    return ChatMessagesResponse(
      chatId: (json['chat_id'] as int?) ?? 0,
      messages: messagesList,
      limit: (json['limit'] as num?)?.toInt() ?? 100,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      linkingId: (json['linking_id'] as int?),
      orderId: (json['order_id'] as int?),
    );
  }
}

/// WebSocket message types for chat communication.
enum WebSocketMessageType {
  connection,
  message,
  messageSent,
  error,
}

/// WebSocket message received from the server.
@immutable
class WebSocketChatMessage {
  const WebSocketChatMessage({
    required this.type,
    this.message,
    this.chatId,
    this.linkingId,
    this.orderId,
    this.messageId,
    this.senderId,
    this.senderName,
    this.body,
    this.messageType,
    this.sentAt,
  });

  final WebSocketMessageType type;
  final String? message;
  final int? chatId;
  final int? linkingId;
  final int? orderId;
  final int? messageId;
  final int? senderId;
  final String? senderName;
  final String? body;
  final String? messageType;
  final String? sentAt;

  /// Build an instance from WebSocket JSON payload.
  factory WebSocketChatMessage.fromJson(Map<String, dynamic> json) {
    final String typeStr = (json['type'] as String? ?? '').toLowerCase();
    WebSocketMessageType messageType;
    switch (typeStr) {
      case 'connection':
        messageType = WebSocketMessageType.connection;
        break;
      case 'message':
        messageType = WebSocketMessageType.message;
        break;
      case 'message_sent':
        messageType = WebSocketMessageType.messageSent;
        break;
      case 'error':
        messageType = WebSocketMessageType.error;
        break;
      default:
        messageType = WebSocketMessageType.message;
    }

    return WebSocketChatMessage(
      type: messageType,
      message: json['message'] as String?,
      chatId: (json['chat_id'] as num?)?.toInt(),
      linkingId: (json['linking_id'] as num?)?.toInt(),
      orderId: (json['order_id'] as num?)?.toInt(),
      messageId: (json['message_id'] as num?)?.toInt(),
      senderId: (json['sender_id'] as num?)?.toInt(),
      senderName: json['sender_name'] as String?,
      body: json['body'] as String?,
      messageType: json['message_type'] as String?,
      sentAt: json['sent_at'] as String?,
    );
  }

  /// Convert to ChatMessage if this is a message type.
  ChatMessage? toChatMessage() {
    if (type == WebSocketMessageType.message &&
        messageId != null &&
        chatId != null &&
        senderId != null &&
        body != null &&
        sentAt != null) {
      return ChatMessage(
        messageId: messageId!,
        chatId: chatId!,
        senderId: senderId!,
        body: body!,
        messageType: parseMessageType(messageType),
        sentAt: sentAt!,
        senderName: senderName,
      );
    }
    return null;
  }
}

