import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MaintenanceRemoteDataSource {
  Future<Map<String, dynamic>> submitReport({
    required String userId,
    required String title,
    required String description,
    required String category,
    required String type,
    required int? compoundId,
  });

  Future<void> uploadAttachments({
    required int reportId,
    required List<Map<String, String>> imageSources,
    required int? compoundId,
    required String type,
  });

  Future<List<Map<String, dynamic>>> getReports({
    required int compoundId,
    required String type,
  });

  Future<List<Map<String, dynamic>>> getAttachments({
    required int compoundId,
    required String type,
  });

  Future<List<Map<String, dynamic>>> getReportNotes(int reportId);

  Future<void> postReportNote({
    required int reportId,
    required String actorId,
    required String action,
    required DateTime createdAt,
  });

  Future<void> updateReportStatus({
    required int reportId,
    required String status,
    required int compoundId,
    required String type,
  });
}

class SupabaseMaintenanceRemoteDataSourceImpl implements MaintenanceRemoteDataSource {
  final SupabaseClient supabaseClient;

  SupabaseMaintenanceRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<Map<String, dynamic>> submitReport({
    required String userId,
    required String title,
    required String description,
    required String category,
    required String type,
    required int? compoundId,
  }) async {
    final response = await supabaseClient.from('MaintenanceReports').insert({
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'type': type,
      'compound_id': compoundId
    }).select('id').single();
    return response;
  }

  @override
  Future<void> uploadAttachments({
    required int reportId,
    required List<Map<String, String>> imageSources,
    required int? compoundId,
    required String type,
  }) async {
    await supabaseClient.from('MReportsAttachments').insert({
      'report_id': reportId,
      'source_url': imageSources,
      'compound_id': compoundId,
      'type': type
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getReports({
    required int compoundId,
    required String type,
  }) async {
    final response = await supabaseClient
        .from("MaintenanceReports")
        .select("*")
        .eq('compound_id', compoundId)
        .eq('type', type);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> getAttachments({
    required int compoundId,
    required String type,
  }) async {
    final response = await supabaseClient
        .from("MReportsAttachments")
        .select("*")
        .eq('compound_id', compoundId)
        .eq('type', type);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> getReportNotes(int reportId) async {
    final response = await supabaseClient
        .from("MReportsHistory")
        .select("*")
        .eq("report_id", reportId);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> postReportNote({
    required int reportId,
    required String actorId,
    required String action,
    required DateTime createdAt,
  }) async {
    await supabaseClient.from("MReportsHistory").insert({
      "report_id": reportId,
      "actor_id": actorId,
      "action": action,
      "created_at": createdAt.toIso8601String(),
    });
  }

  @override
  Future<void> updateReportStatus({
    required int reportId,
    required String status,
    required int compoundId,
    required String type,
  }) async {
    await supabaseClient
        .from("MaintenanceReports")
        .update({'status': status})
        .eq('compound_id', compoundId)
        .eq('type', type)
        .eq('id', reportId);
  }
}
