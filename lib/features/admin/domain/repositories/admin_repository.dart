import '../entities/admin_user.dart';
import '../entities/user_report.dart';

abstract class AdminRepository {
  Future<List<AdminUser>> getCompoundMembers(int compoundId);
  Future<void> updateUserStatus(String userId, String status);
  Future<List<UserReport>> getUserReports({String? status});
  Future<void> updateReportStatus(int reportId, String status);
  Future<void> createReport(UserReport report);
}
