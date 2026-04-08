

import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ChatRepository {
  Future<List<types.Message>> fetchMessages({
    required int channelId,
    required String currentUserId,
    required int pageSize,
    required int pageNum,
  });

  Future<void> sendTextMessage({
    required String text,
    required int channelId,
    required String userId,
    types.Message? repliedMessage,
  });

  Future<void> sendFileMessage({
    required String uri,
    required String name,
    required int size,
    required int channelId,
    required String userId,
    required String type, // 'image', 'file', 'audio'
    Map<String, dynamic>? additionalMetadata,
  });

  Future<void> sendVoiceNote({
    required String uri,
    required Duration duration,
    required List<double> waveform,
    required int channelId,
    required String userId,
  });

  Future<bool> markMessageAsSeen(String messageId, String userId);

  Future<void> deleteMessage(types.Message message);

  Future<types.User> resolveUser(String id);

  RealtimeChannel subscribeToChannel({
    required int channelId,
    required void Function(types.Message message) onInsert,
    required void Function(types.Message message) onUpdate,
    void Function(types.Message message)? onDelete,
  });
}
