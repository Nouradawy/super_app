import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/Enums.dart';
import '../../../../core/models/MaintenanceReport.dart';
import '../../../../core/services/GoogleDriveService.dart';
import '../../../../core/constants/Constants.dart';
import '../../domain/repositories/maintenance_repository.dart';
import '../datasources/maintenance_remote_data_source.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  final MaintenanceRemoteDataSource remoteDataSource;
  final GoogleDriveService driveService;
  final SupabaseClient supabaseClient;

  MaintenanceRepositoryImpl({
    required this.remoteDataSource,
    required this.driveService,
    required this.supabaseClient,
  });

  @override
  Future<void> submitReport({
    required String title,
    required String description,
    required String category,
    required List<XFile>? files,
    required MaintenanceReportType type,
    required int? compoundId,
  }) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return;

    final formattedCategory = category.isNotEmpty
        ? '${category[0].toUpperCase()}${category.substring(1)}'
        : '';

    final reportResponse = await remoteDataSource.submitReport(
      userId: userId,
      title: title,
      description: description,
      category: formattedCategory,
      type: type.name,
      compoundId: compoundId,
    );

    final reportId = reportResponse['id'];

    if (files != null && files.isNotEmpty) {
      List<Map<String, String>> imageSources = [];
      for (final xfile in files) {
        final bytes = await xfile.readAsBytes();
        final file = File(xfile.path);
        final fileName = xfile.name;

        // Using driveService directly for now as it's a core service
        final driveLink = await driveService.uploadFile(
          file,
          fileName,
          'image',
        );

        if (driveLink != null) {
          // Note: In a full refactor, decoding image for width/height might move to a utility
          imageSources.add({
            'uri': driveLink,
            'name': fileName,
            'size': bytes.length.toString(),
            // 'height': ..., 'width': ... // Omitting for brevity or move decoding logic here
          });
        }
      }

      if (imageSources.isNotEmpty) {
        await remoteDataSource.uploadAttachments(
          reportId: reportId,
          imageSources: imageSources,
          compoundId: compoundId,
          type: type.name,
        );
      }
    }
  }

  @override
  Future<List<MaintenanceReports>> getReports({
    required int compoundId,
    required MaintenanceReportType type,
  }) async {
    final data = await remoteDataSource.getReports(compoundId: compoundId, type: type.name);
    return data.map((json) => MaintenanceReports.fromJson(json)).toList();
  }

  @override
  Future<List<MaintenanceReportsAttachments>> getAttachments({
    required int compoundId,
    required MaintenanceReportType type,
  }) async {
    final data = await remoteDataSource.getAttachments(compoundId: compoundId, type: type.name);
    return data.map((json) => MaintenanceReportsAttachments.fromJson(json)).toList();
  }

  @override
  Future<List<MaintenanceReportsHistory>> getReportNotes(int reportId) async {
    final data = await remoteDataSource.getReportNotes(reportId);
    return data.map((json) => MaintenanceReportsHistory.fromJson(json)).toList();
  }

  @override
  Future<void> postReportNote({
    required int reportId,
    required String actorId,
    required String action,
  }) async {
    await remoteDataSource.postReportNote(
      reportId: reportId,
      actorId: actorId,
      action: action,
      createdAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> updateReportStatus({
    required int reportId,
    required String status,
    required int compoundId,
    required MaintenanceReportType type,
  }) async {
    await remoteDataSource.updateReportStatus(
      reportId: reportId,
      status: status,
      compoundId: compoundId,
      type: type.name,
    );
  }
}
