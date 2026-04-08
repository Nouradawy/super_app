import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:ntp/ntp.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final SupabaseClient _supabase;

  ChatRepositoryImpl(this.remoteDataSource, this._supabase);

  @override
  Future<List<types.Message>> fetchMessages({
    required int channelId,
    required String currentUserId,
    required int pageSize,
    required int pageNum,
  }) async {
    final rawMessages = await remoteDataSource.fetchMessages(
      channelId: channelId,
      currentUserId: currentUserId,
      pageSize: pageSize,
      pageNum: pageNum,
    );
    return rawMessages.map((m) => MessageModel.fromMap(m)).toList();
  }

  @override
  Future<void> sendTextMessage({
    required String text,
    required int channelId,
    required String userId,
    types.Message? repliedMessage,
  }) async {
    final now = (await NTP.now()).toUtc();
    await remoteDataSource.sendTextMessage(
      text: text,
      channelId: channelId,
      userId: userId,
      nowIso: now.toIso8601String(),
      nowMs: now.millisecondsSinceEpoch,
      repliedMessageId: repliedMessage?.id,
    );
  }

  @override
  Future<void> sendFileMessage({
    required String uri,
    required String name,
    required int size,
    required int channelId,
    required String userId,
    required String type,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    final now = (await NTP.now()).toUtc();
    await remoteDataSource.sendFileMessage(
      uri: uri,
      name: name,
      size: size,
      channelId: channelId,
      userId: userId,
      type: type,
      nowIso: now.toIso8601String(),
      nowMs: now.millisecondsSinceEpoch,
      additionalMetadata: additionalMetadata,
    );
  }

  @override
  Future<void> sendVoiceNote({
    required String uri,
    required Duration duration,
    required List<double> waveform,
    required int channelId,
    required String userId,
  }) async {
    final now = (await NTP.now()).toUtc();
    await remoteDataSource.sendVoiceNote(
      uri: uri,
      duration: duration,
      waveform: waveform,
      channelId: channelId,
      userId: userId,
      nowIso: now.toIso8601String(),
      nowMs: now.millisecondsSinceEpoch,
    );
  }

  @override
  Future<bool> markMessageAsSeen(String messageId, String userId) async {
    try {
      final now = (await NTP.now()).toUtc();
      await remoteDataSource.markMessageAsSeen(messageId, userId, now.toIso8601String());
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> deleteMessage(types.Message message) async {
    final now = (await NTP.now()).toUtc();
    final currentUserId = _supabase.auth.currentUser?.id ?? '';
    await remoteDataSource.deleteMessage(message.id, message.authorId, currentUserId, now.toIso8601String());
  }

  @override
  Future<types.User> resolveUser(String id) async {
    if (id == 'deleted_user') {
      return const types.User(id: 'deleted_user', name: 'Deleted User');
    }
    try {
      final userData = await remoteDataSource.resolveUser(id);
      return types.User(
        id: id,
        name: userData['display_name'] ?? 'Unknown',
        imageSource: userData['avatar_url'],
      );
    } catch (error) {
       return types.User(id: id, name: 'Unknown');
    }
  }

  @override
  RealtimeChannel subscribeToChannel({
    required int channelId,
    required void Function(types.Message message) onInsert,
    required void Function(types.Message message) onUpdate,
    void Function(types.Message message)? onDelete,
  }) {
    return remoteDataSource.subscribeToChannel(
      channelId: channelId,
      onInsert: (payload) => onInsert(MessageModel.fromMap(payload)),
      onUpdate: (payload) => onUpdate(MessageModel.fromMap(payload)),
      onDelete: onDelete != null ? (payload) => onDelete(MessageModel.fromMap(payload)) : null,
    );
  }
}
