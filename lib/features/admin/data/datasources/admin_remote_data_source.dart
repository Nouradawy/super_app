import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_user_model.dart';
import '../models/user_report_model.dart';

abstract class AdminRemoteDataSource {
  Future<List<AdminUserModel>> getCompoundMembers(int compoundId);
  Future<void> updateUserStatus(String userId, String status);
  Future<List<UserReportModel>> getUserReports({String? status});
  Future<void> updateReportStatus(int reportId, String status);
  Future<void> createReport(UserReportModel report);
}

class SupabaseAdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final SupabaseClient supabase;

  SupabaseAdminRemoteDataSourceImpl({required this.supabase});

  @override
  Future<List<AdminUserModel>> getCompoundMembers(int compoundId) async {
    // 1. Get user IDs for the compound
    final userApartmentsResponse = await supabase
        .from('user_apartments')
        .select('user_id')
        .eq('compound_id', compoundId);

    if (userApartmentsResponse.isEmpty) return [];

    final userIds = (userApartmentsResponse as List)
        .map((row) => row['user_id'] as String)
        .toList();

    // 2. Fetch profiles for these users
    final profilesResponse = await supabase
        .from('profiles')
        .select('id, phone_number, updated_at, owner_type, userState, actionTakenBy, verFiles')
        .inFilter('id', userIds);

    return (profilesResponse as List)
        .map((json) => AdminUserModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> updateUserStatus(String userId, String status) async {
    await supabase
        .from('profiles')
        .update({'userState': status})
        .eq('id', userId);
  }

  @override
  Future<List<UserReportModel>> getUserReports({String? status}) async {
    var query = supabase.from('Report_user').select('*');
    
    if (status != null && status != 'All') {
      query = query.eq('state', status);
    }

    final response = await query;
    return (response as List)
        .map((json) => UserReportModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> updateReportStatus(int reportId, String status) async {
    await supabase
        .from('Report_user')
        .update({'state': status})
        .eq('id', reportId);
  }

  @override
  Future<void> createReport(UserReportModel report) async {
    await supabase.from('Report_user').insert(report.toJson());
  }
}
