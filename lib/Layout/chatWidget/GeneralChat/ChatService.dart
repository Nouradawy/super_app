// lib/chat/services/chat_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ntp/ntp.dart';
import 'package:uuid/uuid.dart';

import 'chat_mapper.dart';


class ChatService {
  final SupabaseClient _supabase;

  ChatService(this._supabase);

  /// Fetches a paginated list of messages from the database.
  Future<List<types.Message>> fetchMessages({
    required int channelId,
    required String currentUserId,
    required int pageSize,
    required int pageNum,
  }) async {
    final response = await _supabase.rpc('get_messages_with_pagnation', params: {
      'p_channel_id': channelId,
      'p_current_user_id': currentUserId,
      'page_size': pageSize,
      'page_num': pageNum,
    });

    final List<types.Message> messages = (response as List)
        .map((map) => mapToMessage(map as Map<String, dynamic>))
        .toList();
    return messages;
  }

  /// Sends a text message.
  Future<void> sendTextMessage({
    required String text,
    required int channelId,
    required String userId,
    types.Message? repliedMessage,
  }) async {
    final id = const Uuid().v4();
    final now = (await NTP.now()).toUtc();
    await _supabase.from('messages').insert({
      'id': id,
      'author_id': userId,
      'text': text,
      'channel_id': channelId,
      'created_at': now.toIso8601String(),
      'sent_at': now.toIso8601String(),
      'metadata': {
        'type': 'text',
        'createdAtMs': now.millisecondsSinceEpoch,
        if (repliedMessage != null) 'reply_to': repliedMessage.id,
      },
    });
  }

  /// Marks a message as seen by the current user.
  Future<bool> markMessageAsSeen(String messageId, String userId) async {
    try {
      final now = (await NTP.now()).toUtc();
      await _supabase.from('message_receipts').upsert({
        'message_id': messageId,
        'user_id': userId,
        'seen_at': now.toIso8601String(),
      });
      return true;
    } catch (error) {
      debugPrint('Error marking message as seen: $error');
      return false; // Return false on failure
    }
  }

  /// Marks a message as deleted.
  Future<void> deleteMessage(String messageId) async {
    final now = (await NTP.now()).toUtc();
    await _supabase.from('messages').update({
      'text': "this message was deleted",
      'uri': null,
      'metadata': {'type': 'text'},
      'deleted_at': now.toIso8601String(),
    }).eq('id', messageId);
  }

  /// Resolves user details from the 'profiles' table.
  Future<types.User> resolveUser(String id) async {
    if (id == 'deleted_user') {
      return const types.User(id: 'deleted_user', name: 'Deleted User');
    }
    try {
      final response = await _supabase
          .from('profiles')
          .select('display_name, avatar_url')
          .eq('id', id)
          .single();

      return types.User(
        id: id,
        name: response['display_name'] ?? 'Unknown',
        imageSource: response['avatar_url'],
      );
    } catch (error) {
      debugPrint("User not found in profiles table with id: $id");
      return types.User(id: id, name: 'Unknown');
    }
  }

  /// Subscribes to real-time changes for a channel.
  RealtimeChannel subscribeToChannel({
    required int channelId,
    required void Function(Map<String, dynamic> payload) onInsert,
    required void Function(Map<String, dynamic> payload) onUpdate,
  }) {
    return _supabase
        .channel('public:messages:channel_id=eq.$channelId')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'channel_id',
        value: channelId,
      ),
      callback: (payload) {
        if (payload.eventType == PostgresChangeEvent.insert) {
          onInsert(payload.newRecord);
        } else if (payload.eventType == PostgresChangeEvent.update) {
          onUpdate(payload.newRecord);
        }
      },
    )
        .subscribe();
  }
}