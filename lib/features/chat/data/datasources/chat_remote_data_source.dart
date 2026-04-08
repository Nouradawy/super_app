import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

abstract class ChatRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchMessages({
    required int channelId,
    required String currentUserId,
    required int pageSize,
    required int pageNum,
  });

  Future<void> sendTextMessage({
    required String text,
    required int channelId,
    required String userId,
    required String nowIso,
    required int nowMs,
    String? repliedMessageId,
  });

  Future<void> sendFileMessage({
    required String uri,
    required String name,
    required int size,
    required int channelId,
    required String userId,
    required String type,
    required String nowIso,
    required int nowMs,
    Map<String, dynamic>? additionalMetadata,
  });

  Future<void> sendVoiceNote({
    required String uri,
    required Duration duration,
    required List<double> waveform,
    required int channelId,
    required String userId,
    required String nowIso,
    required int nowMs,
  });

  Future<void> markMessageAsSeen(String messageId, String userId, String nowIso);

  Future<void> deleteMessage(String messageId, String authorId, String currentUserId, String nowIso);

  Future<Map<String, dynamic>> resolveUser(String id);

  RealtimeChannel subscribeToChannel({
    required int channelId,
    required void Function(Map<String, dynamic> payload) onInsert,
    required void Function(Map<String, dynamic> payload) onUpdate,
    void Function(Map<String, dynamic> payload)? onDelete,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final SupabaseClient _supabase;

  ChatRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<Map<String, dynamic>>> fetchMessages({
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
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> sendTextMessage({
    required String text,
    required int channelId,
    required String userId,
    required String nowIso,
    required int nowMs,
    String? repliedMessageId,
  }) async {
    final id = const Uuid().v4();
    await _supabase.from('messages').insert({
      'id': id,
      'author_id': userId,
      'text': text,
      'channel_id': channelId,
      'created_at': nowIso,
      'sent_at': nowIso,
      'metadata': {
        'type': 'text',
        'createdAtMs': nowMs,
        if (repliedMessageId != null) 'reply_to': repliedMessageId,
      },
    });
  }

  @override
  Future<void> sendFileMessage({
    required String uri,
    required String name,
    required int size,
    required int channelId,
    required String userId,
    required String type,
    required String nowIso,
    required int nowMs,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    final id = const Uuid().v4();
    await _supabase.from('messages').insert({
      'id': id,
      'author_id': userId,
      'uri': uri,
      'type': type,
      'channel_id': channelId,
      'created_at': nowIso,
      'sent_at': nowIso,
      'metadata': {
        'type': type,
        'name': name,
        'size': size,
        'createdAtMs': nowMs,
        if (additionalMetadata != null) ...additionalMetadata,
      },
    });
  }

  @override
  Future<void> sendVoiceNote({
    required String uri,
    required Duration duration,
    required List<double> waveform,
    required int channelId,
    required String userId,
    required String nowIso,
    required int nowMs,
  }) async {
    final id = const Uuid().v4();
    await _supabase.from('messages').insert({
      'id': id,
      'author_id': userId,
      'uri': uri,
      'channel_id': channelId,
      'created_at': nowIso,
      'sent_at': nowIso,
      'metadata': {
        'type': 'audio',
        'name': 'voice_note_${id.substring(0, 8)}.m4a',
        'createdAtMs': nowMs,
        'duration': '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
        'waveform': waveform,
        'status': 'processing',
      },
    });
  }

  @override
  Future<void> deleteMessage(String messageId, String authorId, String currentUserId, String nowIso) async {
     if(authorId == currentUserId) {
      await _supabase.from('messages').update({
        'text': "this message was deleted",
        'uri': null,
        'metadata': {'type': 'text'},
        'deleted_at': nowIso,
      }).eq('id', messageId);
    } else {
      await _supabase.from('messages').update({
        'text': "this message was deleted by admin",
        'uri': null,
        'metadata': {'type': 'text'},
        'deleted_at': nowIso,
      }).eq('id', messageId);
    }
  }

  @override
  Future<void> markMessageAsSeen(String messageId, String userId, String nowIso) async {
    await _supabase.from('message_receipts').upsert({
      'message_id': messageId,
      'user_id': userId,
      'seen_at': nowIso,
    });
  }

  @override
  Future<Map<String, dynamic>> resolveUser(String id) async {
    return await _supabase
          .from('profiles')
          .select('display_name, avatar_url')
          .eq('id', id)
          .single();
  }

  @override
  RealtimeChannel subscribeToChannel({
    required int channelId,
    required void Function(Map<String, dynamic> payload) onInsert,
    required void Function(Map<String, dynamic> payload) onUpdate,
    void Function(Map<String, dynamic> payload)? onDelete,
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
        } else if (payload.eventType == PostgresChangeEvent.delete) {
          if (onDelete != null) onDelete(payload.oldRecord);
        }
      },
    )
        .subscribe();
  }
}
