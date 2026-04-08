import 'package:equatable/equatable.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatRecordingState extends ChatState {
  final bool isRecording;
  const ChatRecordingState(this.isRecording);
  @override
  List<Object?> get props => [isRecording];
}

class ChatInputState extends ChatState {
  final bool isEmpty;
  const ChatInputState(this.isEmpty);
  @override
  List<Object?> get props => [isEmpty];
}

class ChatBrainStormingState extends ChatState {
  final bool isBrainStorming;
  const ChatBrainStormingState(this.isBrainStorming);
  @override
  List<Object?> get props => [isBrainStorming];
}

class ChatLoading extends ChatState {}

class ChatMessagesLoaded extends ChatState {
  final List<types.Message> messages;
  final bool hasMore;
  final int? channelId;
  final bool isBrainStorming;
  final bool isRecording;
  final bool isChatInputEmpty;
  final double micPadding;

  const ChatMessagesLoaded({
    required this.messages,
    this.hasMore = true,
    this.channelId,
    this.isBrainStorming = false,
    this.isRecording = false,
    this.isChatInputEmpty = true,
    this.micPadding = 0.0,
  });

  @override
  List<Object?> get props => [messages, hasMore, channelId, isBrainStorming, isRecording, isChatInputEmpty, micPadding];

  ChatMessagesLoaded copyWith({
    List<types.Message>? messages,
    bool? hasMore,
    int? channelId,
    bool? isBrainStorming,
    bool? isRecording,
    bool? isChatInputEmpty,
    double? micPadding,
  }) {
    return ChatMessagesLoaded(
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      channelId: channelId ?? this.channelId,
      isBrainStorming: isBrainStorming ?? this.isBrainStorming,
      isRecording: isRecording ?? this.isRecording,
      isChatInputEmpty: isChatInputEmpty ?? this.isChatInputEmpty,
      micPadding: micPadding ?? this.micPadding,
    );
  }
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
