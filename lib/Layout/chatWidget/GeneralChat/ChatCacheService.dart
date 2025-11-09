// lib/chat/services/cache_service.dart

import 'dart:collection';
import 'dart:convert';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:shared_preferences/shared_preferences.dart';

import 'chat_mapper.dart';

class ChatCacheService {
  /// Saves a list of messages to the local cache for a specific channel.
  Future<void> saveMessages(int channelId, List<types.Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'chat_messages_$channelId';
    final seen = <String>{};
    final List<String> encodedMessages = messages.
        where((msg)=>seen.add(msg.id)).map((msg) {
          // Avoid storing DateTime objects inside metadata; store metadata as JSON string.
      final meta = msg.metadata ?? <String, dynamic>{};
      // Ensure created timestamps in ISO + ms are present for sorting later.
      final createdAtIso = msg.createdAt?.toUtc().toIso8601String();
      final createdAtMs = msg.createdAt?.toUtc().millisecondsSinceEpoch;

      final messageMap = {
        'author_id': msg.authorId,
        'created_at': msg.createdAt?.toUtc().toIso8601String(),
        'created_at_ms': msg.createdAt?.toUtc().millisecondsSinceEpoch,
        'id': msg.id,
        'metadata': jsonEncode(meta),
        'uri': msg is types.FileMessage
            ? msg.source
            : (msg is types.ImageMessage ? msg.source : (msg is types.AudioMessage ? msg.source : null)),
        'text': msg is types.TextMessage ? msg.text : null,
        'type': msg.metadata?['type'],
      };
      return jsonEncode(messageMap);
    }).toList();

    await prefs.setStringList(cacheKey, encodedMessages);
  }

  /// Loads messages from the local cache for a specific channel.
  Future<List<types.Message>> loadMessages(int channelId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'chat_messages_$channelId';
    final encodedMessages = prefs.getStringList(cacheKey);

    if (encodedMessages == null) {
      return [];
    }

    final List<Map<String, dynamic>> messageMaps = encodedMessages.map((encodedMsg) {
      final m = jsonDecode(encodedMsg) as Map<String, dynamic>;
      // If metadata is a JSON string, decode it so mapToMessage receives either Map or String (normalize handles both)
      if (m['metadata'] is String) {
        try {
          final decodedMeta = jsonDecode(m['metadata'] as String);
          m['metadata'] = decodedMeta;
        } catch (_) {
          // Leave as-string if decode fails; mapToMessage.normalizeMeta will still handle it.
        }
      }
      return m;
    }).toList();

    int _tsFromMap(Map<String, dynamic> m) {
      final dynamic ms = m['created_at_ms'];
      if (ms is int) return ms;
      if (ms is num) return ms.toInt();
      final createdAt = m['created_at'];
      if (createdAt is String) {
        try {
          return DateTime.parse(createdAt).toUtc().millisecondsSinceEpoch;
        } catch (_) {}
      }
      return 0;
    }

    // Sort chronologically (oldest first). Swap compareTo for newest-first if needed.
    messageMaps.sort((a, b) => _tsFromMap(a).compareTo(_tsFromMap(b)));

    // Map to types.Message and remove duplicates while preserving the sorted order.
    final LinkedHashMap<String, types.Message> unique = LinkedHashMap();
    for (final map in messageMaps) {
      final msg = mapToMessage(map);
      if (!unique.containsKey(msg.id)) {
        unique[msg.id] = msg;
      }
    }

      return unique.values.toList();
  }
}