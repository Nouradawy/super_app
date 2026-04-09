import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SocialRemoteDataSource {
  Future<List<Map<String, dynamic>>> getPosts(int compoundId);
  Future<void> createPost({
    required String postHead,
    required bool getCalls,
    required int compoundId,
    required String authorId,
    required List<Map<String, dynamic>> imageSources,
  });
  Future<void> updatePostComments({
    required String postId,
    required List<Map<String, dynamic>> comments,
  });

  Future<List<Map<String, dynamic>>> getBrainStorms(int channelId, int compoundId);
  Future<void> createBrainStorm({
    required String id,
    required String title,
    required String authorId,
    required String createdAt,
    required int channelId,
    required int compoundId,
    required List<Map<String, dynamic>> imageSources,
    required dynamic options,
  });
  Future<void> updateBrainStormVote({
    required String pollId,
    required Map<String, Map<String, bool>> votes,
    required List<Map<String, dynamic>> options,
  });
  Future<void> updateBrainStormComments({
    required String pollId,
    required List<Map<String, dynamic>> comments,
  });
}

class SocialRemoteDataSourceImpl implements SocialRemoteDataSource {
  final SupabaseClient client;

  SocialRemoteDataSourceImpl({required this.client});

  @override
  Future<List<Map<String, dynamic>>> getPosts(int compoundId) async {
    final response = await client
        .from('Posts')
        .select('*')
        .eq('compound_id', compoundId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> createPost({
    required String postHead,
    required bool getCalls,
    required int compoundId,
    required String authorId,
    required List<Map<String, dynamic>> imageSources,
  }) async {
    await client.from('Posts').insert({
      'post_head': postHead,
      'getCalls': getCalls,
      'compound_id': compoundId,
      'author_id': authorId,
      'source_url': imageSources,
      'Comments': [],
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> updatePostComments({
    required String postId,
    required List<Map<String, dynamic>> comments,
  }) async {
    await client.from('Posts').update({'Comments': comments}).eq('id', postId);
  }

  @override
  Future<List<Map<String, dynamic>>> getBrainStorms(int channelId, int compoundId) async {
    final response = await client
        .from('BrainStorming')
        .select('*')
        .eq('channel_id', channelId)
        .eq('compound_id', compoundId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> createBrainStorm({
    required String id,
    required String title,
    required String authorId,
    required String createdAt,
    required int channelId,
    required int compoundId,
    required List<Map<String, dynamic>> imageSources,
    required dynamic options,
  }) async {
    await client.from('BrainStorming').insert({
      'id': id,
      'title': title,
      'author_id': authorId,
      'created_at': createdAt,
      'channel_id': channelId,
      'compound_id': compoundId,
      'imageSources': imageSources,
      'options': options,
      'votes': {},
      'comments': [],
    });
  }

  @override
  Future<void> updateBrainStormVote({
    required String pollId,
    required Map<String, Map<String, bool>> votes,
    required List<Map<String, dynamic>> options,
  }) async {
    await client.from('BrainStorming').update({
      'votes': votes,
      'options': options,
    }).eq('id', pollId);
  }

  @override
  Future<void> updateBrainStormComments({
    required String pollId,
    required List<Map<String, dynamic>> comments,
  }) async {
    await client.from('BrainStorming').update({'comments': comments}).eq('id', pollId);
  }
}
