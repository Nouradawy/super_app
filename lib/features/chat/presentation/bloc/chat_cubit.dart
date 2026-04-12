import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/usecases/fetch_messages.dart';
import '../../domain/usecases/send_text_message.dart';
import '../../domain/usecases/send_file_message.dart';
import '../../domain/usecases/send_voice_note.dart';
import '../../domain/usecases/mark_message_seen.dart';
import '../../domain/usecases/delete_message.dart';
import '../../domain/usecases/resolve_user.dart';
import '../../domain/usecases/subscribe_to_channel.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final FetchMessages fetchMessagesUsecase;
  final SendTextMessage sendTextMessageUsecase;
  final SendFileMessage sendFileMessageUsecase;
  final SendVoiceNote sendVoiceNoteUsecase;
  final MarkMessageSeen markMessageSeenUsecase;
  final DeleteMessage deleteMessageUsecase;
  final ResolveUser resolveUserUsecase;
  final SubscribeToChannel subscribeToChannelUsecase;

  ChatCubit({
    required this.fetchMessagesUsecase,
    required this.sendTextMessageUsecase,
    required this.sendFileMessageUsecase,
    required this.sendVoiceNoteUsecase,
    required this.markMessageSeenUsecase,
    required this.deleteMessageUsecase,
    required this.resolveUserUsecase,
    required this.subscribeToChannelUsecase,
  }) : super(ChatInitial());

  bool isRecording = false;
  List<double> recordedAmplitudes = [];
  bool isChatInputEmpty = true;
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;
  RealtimeChannel? _realtimeChannel;
  double micPadding = 0;
  int? channelId;
  bool isBrainStorming = false;

  List<types.Message> _messages = [];

  void showHideMic(bool isEmpty) {
    isChatInputEmpty = isEmpty;
    if (state is ChatMessagesLoaded) {
      emit((state as ChatMessagesLoaded).copyWith(isChatInputEmpty: isEmpty, micPadding: micPadding));
    } else {
      emit(ChatInputState(isEmpty));
    }
  }

  void updateMicPadding(double padding) {
    micPadding = padding;
    if (state is ChatMessagesLoaded) {
      emit((state as ChatMessagesLoaded).copyWith(micPadding: padding));
    }
  }

  void toggleRecording() {
    isRecording = !isRecording;
    if (state is ChatMessagesLoaded) {
      emit((state as ChatMessagesLoaded).copyWith(isRecording: isRecording));
    } else {
      emit(ChatRecordingState(isRecording));
    }
  }

  void toggleBrainStorming() {
    isBrainStorming = !isBrainStorming;
    if (state is ChatMessagesLoaded) {
      final currentState = state as ChatMessagesLoaded;
      emit(currentState.copyWith(isBrainStorming: isBrainStorming));
    } else {
      emit(ChatBrainStormingState(isBrainStorming));
    }
  }

  Future<void> initChat({required int channelId, required String currentUserId}) async {
    this.channelId = channelId;
    _currentPage = 0;
    _messages = [];
    _hasMore = true;
    emit(ChatLoading());
    try {
      final pageRequested = _currentPage;
      final messages = await fetchMessagesUsecase(
        channelId: channelId,
        currentUserId: currentUserId,
        pageSize: _pageSize,
        pageNum: pageRequested,
        onRemoteSynced: (synced, pageNum) => _applyRemoteSyncedPage(synced, pageNum),
      );
      _messages = messages;
      _currentPage++;
      _hasMore = messages.length >= _pageSize;
      
      _subscribeToRealtime(channelId);
      
      emit(ChatMessagesLoaded(
        messages: _messages,
        hasMore: _hasMore,
        channelId: channelId,
        isBrainStorming: isBrainStorming,
        isChatInputEmpty: isChatInputEmpty,
        isRecording: isRecording,
        micPadding: micPadding,
      ));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> loadMoreMessages({required int channelId, required String currentUserId}) async {
    if (!_hasMore || state is ChatLoading) return;
    
    try {
      final pageRequested = _currentPage;
      final messages = await fetchMessagesUsecase(
        channelId: channelId,
        currentUserId: currentUserId,
        pageSize: _pageSize,
        pageNum: pageRequested,
        onRemoteSynced: (synced, pageNum) => _applyRemoteSyncedPage(synced, pageNum),
      );
      
      if (messages.isEmpty) {
        _hasMore = false;
      } else {
        _messages.addAll(messages);
        _currentPage++;
      }
      
      if (state is ChatMessagesLoaded) {
        emit((state as ChatMessagesLoaded).copyWith(
            messages: List.from(_messages),
            hasMore: _hasMore,
            isChatInputEmpty: isChatInputEmpty,
            isRecording: isRecording,
            isBrainStorming: isBrainStorming,
            micPadding: micPadding));
      }
    } catch (e) {
      // Keep existing messages but notify error? 
    }
  }

  void _subscribeToRealtime(int channelId) {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = subscribeToChannelUsecase(
      channelId: channelId,
      onInsert: (message) {
        _addOrUpdateMessage(message);
      },
      onUpdate: (message) {
        _addOrUpdateMessage(message);
      },
      onDelete: (message) {
        _removeMessage(message.id);
      },
    );
  }

  void _addOrUpdateMessage(types.Message message) {
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      _messages[index] = message;
    } else {
      _messages.add(message);
      _messages.sort((a, b) => (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    }
    if (state is ChatMessagesLoaded) {
      emit((state as ChatMessagesLoaded).copyWith(
          messages: List.from(_messages),
          hasMore: _hasMore,
          isChatInputEmpty: isChatInputEmpty,
          isRecording: isRecording,
          isBrainStorming: isBrainStorming,
          micPadding: micPadding));
    }
  }

  void _applyRemoteSyncedPage(List<types.Message> synced, int pageNum) {
    if (isClosed) return;
    if (synced.isEmpty) return;

    if (pageNum == 0) {
      _messages = List<types.Message>.from(synced);
    } else {
      final ids = _messages.map((m) => m.id).toSet();
      for (final m in synced) {
        if (!ids.contains(m.id)) {
          _messages.add(m);
          ids.add(m.id);
        }
      }
    }
    _messages.sort(
      (a, b) => (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
    );

    if (state is ChatMessagesLoaded) {
      emit(
        (state as ChatMessagesLoaded).copyWith(
          messages: List<types.Message>.from(_messages),
          hasMore: _hasMore,
          isChatInputEmpty: isChatInputEmpty,
          isRecording: isRecording,
          isBrainStorming: isBrainStorming,
          micPadding: micPadding,
        ),
      );
    }
  }

  void _removeMessage(String messageId) {
    _messages.removeWhere((m) => m.id == messageId);
    if (state is ChatMessagesLoaded) {
      emit((state as ChatMessagesLoaded).copyWith(
          messages: List.from(_messages),
          hasMore: _hasMore,
          isChatInputEmpty: isChatInputEmpty,
          isRecording: isRecording,
          isBrainStorming: isBrainStorming,
          micPadding: micPadding));
    }
  }

  Future<void> sendMessage({
    required String text,
    required int channelId,
    required String userId,
    types.Message? repliedMessage,
  }) async {
    await sendTextMessageUsecase(
      text: text,
      channelId: channelId,
      userId: userId,
      repliedMessage: repliedMessage,
    );
  }

  Future<void> sendFileMessage({
    required String uri,
    required String name,
    required int size,
    required int channelId,
    required String userId,
    required String type,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    await sendFileMessageUsecase(
      uri: uri,
      name: name,
      size: size,
      channelId: channelId,
      userId: userId,
      type: type,
      additionalMetadata: additionalMetadata,
    );
  }

  Future<void> sendVoiceNote({
    required String uri,
    required Duration duration,
    required List<double> waveform,
    required int channelId,
    required String userId,
  }) async {
    await sendVoiceNoteUsecase(
      uri: uri,
      duration: duration,
      waveform: waveform,
      channelId: channelId,
      userId: userId,
    );
  }

  Future<void> markAsSeen(String messageId, String userId) async {
    await markMessageSeenUsecase(messageId, userId);
  }

  Future<void> deleteMessage(types.Message message) async {
    await deleteMessageUsecase(message);
  }

  Future<types.User> resolveUser(String id) async {
    return await resolveUserUsecase(id);
  }

  @override
  Future<void> close() {
    _realtimeChannel?.unsubscribe();
    return super.close();
  }
}
