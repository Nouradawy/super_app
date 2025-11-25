import 'cubit.dart';

abstract class MessageReceiptsState {
  const MessageReceiptsState();
}

class MessageReceiptsInitial extends MessageReceiptsState {
  const MessageReceiptsInitial();
}

class MessageReceiptsLoading extends MessageReceiptsState {
  const MessageReceiptsLoading();
}

class MessageReceiptsLoaded extends MessageReceiptsState {
  final List<SeenUser> seenUsers;
  const MessageReceiptsLoaded(this.seenUsers);
}

class MessageReceiptsError extends MessageReceiptsState {
  final String message;
  const MessageReceiptsError(this.message);
}