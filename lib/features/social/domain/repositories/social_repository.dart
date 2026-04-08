import 'package:image_picker/image_picker.dart';
import '../entities/post.dart';
import '../entities/brainstorm.dart';

abstract class SocialRepository {
  Future<List<Post>> getPosts(int compoundId);
  Future<void> createPost({
    required String postHead,
    required bool getCalls,
    required int compoundId,
    required String authorId,
    List<XFile>? files,
  });
  Future<void> addComment({
    required int compoundId,
    required String postId,
    required String commentText,
    required String authorId,
    required List<Map<String, dynamic>> currentComments,
  });

  Future<List<BrainStorm>> getBrainStorms(int channelId, int compoundId);
  Future<void> createBrainStorm({
    required String title,
    required List<XFile>? images,
    required dynamic options,
    required int channelId,
    required int compoundId,
    required String authorId,
  });
  Future<void> voteBrainStorm({
    required String pollId,
    required String optionId,
    required String userId,
    required List<Map<String, dynamic>> currentOptions,
    required Map<String, dynamic>? currentVotes,
  });
  Future<void> addBrainStormComment({
    required int channelId,
    required int compoundId,
    required String pollId,
    required String commentText,
    required String authorId,
    required List<Map<String, dynamic>> currentComments,
  });
}
