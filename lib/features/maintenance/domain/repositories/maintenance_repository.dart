import 'package:image_picker/image_picker.dart';
import '../../../../core/config/Enums.dart';
import '../../../../core/models/MaintenanceReport.dart';

abstract class MaintenanceRepository {
  Future<void> submitReport({
    required String title,
    required String description,
    required String category,
    required List<XFile>? files,
    required MaintenanceReportType type,
    required int? compoundId,
  });

  Future<List<MaintenanceReports>> getReports({
    required int compoundId,
    required MaintenanceReportType type,
  });

  Future<List<MaintenanceReportsAttachments>> getAttachments({
    required int compoundId,
    required MaintenanceReportType type,
  });

  Future<List<MaintenanceReportsHistory>> getReportNotes(int reportId);

  Future<void> postReportNote({
    required int reportId,
    required String actorId,
    required String action,
  });

  Future<void> updateReportStatus({
    required int reportId,
    required String status,
    required int compoundId,
    required MaintenanceReportType type,
  });
}
