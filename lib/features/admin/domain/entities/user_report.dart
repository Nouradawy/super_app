import 'package:equatable/equatable.dart';

class UserReport extends Equatable {
  final int? id;
  final String authorId;
  final DateTime createdAt;
  final String reportedUserId;
  final String state;
  final String description;
  final String messageId;
  final String reportedFor;

  const UserReport({
    this.id,
    required this.authorId,
    required this.createdAt,
    required this.reportedUserId,
    required this.state,
    required this.description,
    required this.messageId,
    required this.reportedFor,
  });

  @override
  List<Object?> get props => [
    id,
    authorId,
    createdAt,
    reportedUserId,
    state,
    description,
    messageId,
    reportedFor,
  ];
}
