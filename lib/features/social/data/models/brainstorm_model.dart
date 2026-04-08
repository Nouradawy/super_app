import '../../domain/entities/brainstorm.dart';

class BrainStormModel extends BrainStorm {
  const BrainStormModel({
    required super.id,
    required super.authorId,
    required super.createdAt,
    required super.compoundId,
    required super.channelId,
    required super.title,
    required super.image,
    required super.options,
    required super.comments,
    super.votes,
  });

  factory BrainStormModel.fromJson(Map<String, dynamic> json) {
    return BrainStormModel(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      compoundId: json['compound_id'] as int,
      channelId: json['channel_id'] as int,
      title: json['title'] ?? '',
      image: List<Map<String, dynamic>>.from(json['imageSources'] ?? []),
      options: List<Map<String, dynamic>>.from(json['options'] ?? []),
      comments: List<Map<String, dynamic>>.from(json['comments'] ?? []),
      votes: json['votes'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'created_at': createdAt.toIso8601String(),
      'compound_id': compoundId,
      'channel_id': channelId,
      'title': title,
      'imageSources': image,
      'options': options,
      'comments': comments,
      'votes': votes,
    };
  }
}
