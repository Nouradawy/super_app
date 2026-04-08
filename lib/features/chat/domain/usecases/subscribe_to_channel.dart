
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/chat_repository.dart';

class SubscribeToChannel {
  final ChatRepository repository;

  SubscribeToChannel(this.repository);

  RealtimeChannel call({
    required int channelId,
    required void Function(types.Message message) onInsert,
    required void Function(types.Message message) onUpdate,
    void Function(types.Message message)? onDelete,
  }) {
    return repository.subscribeToChannel(
      channelId: channelId,
      onInsert: onInsert,
      onUpdate: onUpdate,
      onDelete: onDelete,
    );
  }
}
