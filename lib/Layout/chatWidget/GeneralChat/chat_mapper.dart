// lib/chat/utils/chat_mapper.dart

import 'dart:convert';

import 'package:flutter_chat_core/flutter_chat_core.dart' as types;


/// Normalize metadata to a Map\<String, dynamic\>.
Map<String, dynamic> normalizeMeta(dynamic meta) {
  if (meta == null) return <String, dynamic>{};
  if (meta is Map) return Map<String, dynamic>.from(meta);
  if (meta is String) {
    try {
      final decoded = jsonDecode(meta);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  return <String, dynamic>{};
}

/// Maps a raw data map (from Supabase) to a `types.Message` object.
types.Message mapToMessage(Map<String, dynamic> map) {
  DateTime? parseDate(String? dateStr) {
    if (dateStr == null) return null;
    // If the string ends with 'Z' or an explicit offset like +02:00, DateTime.parse preserves timezone.
    final tzRegex = RegExp(r'(Z|[+\-]\d{2}:\d{2})$');
    DateTime parsed;
    if (tzRegex.hasMatch(dateStr)) {
      parsed = DateTime.parse(dateStr);
    } else {
      // Legacy/naive timestamps: assume UTC to avoid double-shift on devices with DST
      parsed = DateTime.parse('${dateStr}Z');
    }
    return parsed.toLocal();
  }

  DateTime? createdAt;
  final createdAtMsRaw = map['created_at_ms'] ?? map['createdAtMs'] ?? map['metadata']?['createdAtMs'];
  if (createdAtMsRaw != null) {
    int? ms;
    if (createdAtMsRaw is String) {
      ms = int.tryParse(createdAtMsRaw);
    } else if (createdAtMsRaw is num) {
      ms = createdAtMsRaw.toInt();
    }
    if (ms != null) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    }
  }

  createdAt ??= parseDate(map['created_at']);
  final deletedAt = parseDate(map['deleted_at']);
  final failedAt = parseDate(map['failed_at']);
  final bool isSeen = map['isSeen'] ?? false;
  final sentAt = parseDate(map['sent_at']);
  final deliveredAt = parseDate(map['delivered_at']);
  final updatedAt = parseDate(map['updated_at']);

  final metadata = normalizeMeta(map['metadata']);

  // Add all timestamps to metadata for universal access
  metadata['deletedAt'] = deletedAt?.toIso8601String();
  metadata['failedAt'] = failedAt?.toIso8601String();
  metadata['sentAt'] = sentAt?.toIso8601String();
  metadata['deliveredAt'] = deliveredAt?.toIso8601String();
  metadata['isSeen'] = isSeen;
  metadata['updatedAt'] = updatedAt?.toIso8601String();

  if (createdAt != null) {
    metadata['createdAtMs'] = createdAt.toUtc().millisecondsSinceEpoch;
  } else if (createdAtMsRaw != null) {
    metadata['createdAtMs'] = createdAtMsRaw;
  }

  // Defensive: ensure poll options are maps if present (helps downstream code)
  if (metadata['options'] is List) {
    final raw = metadata['options'] as List;
    metadata['options'] = raw.map((e) {
      if (e is Map) return Map<String, dynamic>.from(e);
      if (e is String) {
        try {
          final d = jsonDecode(e);
          if (d is Map) return Map<String, dynamic>.from(d);
        } catch (_) {}
      }
      return <String, dynamic>{};
    }).toList();
  }

  final messageType = metadata['type'] ?? map['type'];
  const String deletedUserId = 'deleted_user';

  switch (messageType) {
    case 'image':
      return types.ImageMessage(
        createdAt: createdAt,
        id: map['id'],
        text: metadata['name'] ?? 'image',
        authorId: map['author_id'] ?? deletedUserId,
        size: metadata['size'] ?? 0,
        height: metadata['height']?.toDouble(),
        width: metadata['width']?.toDouble(),
        source: map['uri'],
        metadata: metadata,
        replyToMessageId: metadata['reply_to'],
      );
    case 'file':
      return types.FileMessage(
        createdAt: createdAt,
        id: map['id'],
        authorId: map['author_id'] ?? deletedUserId,
        name: metadata['name'] ?? 'File',
        size: metadata['size'] ?? 0,
        mimeType: metadata['mimeType'],
        source: map['uri'],
        metadata: metadata,
        replyToMessageId: metadata['reply_to'],
      );
    case 'audio':
      final durationString = metadata['duration'] ?? '00:00';
      final parts = durationString.split(':');
      final duration = Duration(
        minutes: int.tryParse(parts[0]) ?? 0,
        seconds: int.tryParse(parts[1]) ?? 0,
      );
      return types.AudioMessage(
        createdAt: createdAt,
        id: map['id'],
        authorId: map['author_id'] ?? deletedUserId,
        size: metadata['size'] ?? 0,
        source: map['uri'],
        duration: duration,
        metadata: metadata,
        replyToMessageId: metadata['reply_to'],
      );
    default: // 'text'
      return types.TextMessage(
        createdAt: createdAt,
        id: map['id'],
        authorId: map['author_id'] ?? deletedUserId,
        text: map['text'] ?? '',
        metadata: metadata,
        replyToMessageId: metadata['reply_to'],
        deliveredAt: deliveredAt,
      );
  }
}