import 'package:WhatsUnity/Layout/Cubit/ManagerCubit/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../Components/Constants.dart';
import '../../../Confg/Enums.dart';
import '../../../Confg/supabase.dart';
import '../../../Model/MaintenanceReport.dart';

class ManagerCubit extends Cubit<ManagerCubitStates>{
  ManagerCubit():super(ManagerInitialState());
  static ManagerCubit get(context) => BlocProvider.of(context);

  int filterIndex = 0;
  MaintenanceReportType  currentMaintenanceType = MaintenanceReportType.maintenance;
  List<MaintenanceReports> maintenanceDataFiltered = [];
  List<MaintenanceReportsHistory> reportNotes = [];
  bool isAnnouncment = false;
  // List<MaintenanceReportsHistory> filteredReportNotes = [];


  // Future<void> reportFollowUp (String title , String description , String category, List<XFile>? files , MaintenanceReportType type ) async {
  //   final formattedCategory = category.isNotEmpty
  //       ? '${category[0].toUpperCase()}${category.substring(1)}'
  //       : '';
  //   final newReport =
  //   await supabase.from('MaintenanceReports').insert({
  //     'user_id': Userid,
  //     'title': title,
  //     'description': description,
  //     'category':formattedCategory,
  //     'type':type.name,
  //     'compound_id':selectedCompoundId
  //   })
  //       .select('id')
  //       .single();
  //
  //   final reportId = newReport['id'];
  //
  //   if(files != null ){
  //     for (final xfile in files) {
  //       final bytes = await xfile.readAsBytes();
  //       final image = await decodeImageFromList(bytes);
  //       int index =0;                     //count the number of items in files List used for _uploadProgress
  //       _uploadProgress.add(0);           //adding new item to the list and using index to update it's progress
  //       final file = File(xfile.path);
  //       final fileName = xfile.name;
  //
  //
  //       // 1. Upload the file to Google Drive
  //       final driveLink = await driveService.uploadFile(
  //         file,
  //         fileName,
  //         'image',
  //       );
  //       if(driveLink !=null){
  //         imageSources.add({
  //           'uri': driveLink,
  //           'name': fileName,
  //           'size': bytes.length.toString(),
  //           'height': image.height.toString(),
  //           'width': image.width.toString(),
  //         });
  //       }
  //       index++;
  //     }
  //
  //     await supabase.from('MReportsAttachments').insert({
  //
  //       'report_id': reportId,
  //       'source_url': imageSources,
  //       'compound_id':selectedCompoundId,
  //       'type' : type.name
  //     });
  //   }
  //
  //   imageSources.clear();
  //   emit(NewReportSubmitState());
  // }

  void resetToInitial() {
    emit(ManagerInitialState());
  }

  void loadAnnouncement(){
    isAnnouncment = true;
    emit(LoadAnnouncementState());
  }

  Future<void> getMaintenanceReports() async {
    isAnnouncment = false;
    emit(LoadAnnouncementState());
    final reports = await supabase.from("MaintenanceReports").select("*").eq('compound_id',selectedCompoundId!).eq('type',currentMaintenanceType.name);
    final attachments = await supabase.from("MReportsAttachments").select("*").eq('compound_id',selectedCompoundId!).eq('type',currentMaintenanceType.name);
    maintenanceReportsData = reports.map((element) => MaintenanceReports.fromJson(element)).toList();
    maintenanceReportsAttachmentsData = attachments.map((element) => MaintenanceReportsAttachments.fromJson(element)).toList();
    debugPrint(currentMaintenanceType.name);
    debugPrint(reports.toString());
    emit(GetMaintenanceReportsState());
  }

  Future<void> getReportsNotes(int reportId) async{
    final reportsHistory = await supabase.from("MReportsHistory").select("*").eq("report_id",reportId);
    reportNotes = reportsHistory.map((element) => MaintenanceReportsHistory.fromJson(element)).toList();
    emit(GetReportNotesState());
  }
  
  Future<void> postReportNote(int reportId , String note) async{
    await supabase.from("MReportsHistory").insert
      (MaintenanceReportsHistory(
        reportId: reportId ,
        actorId: currentUser!.id,
        action: note,
        createdAt: DateTime.now().toUtc()).toJson());
    await getReportsNotes(reportId);
    emit(PostReportNotesState());
  }

  void setMaintenanceType (MaintenanceReportType type){
    currentMaintenanceType = type;
    emit(SetMaintenanceTypeState());
  }

  void filterRequests ({
    required MaintenanceReportType type,
    ManagerReportsFilter? statusFilter}) {
    if(statusFilter == ManagerReportsFilter.all) {
      maintenanceDataFiltered = maintenanceReportsData;
    } else {
    maintenanceDataFiltered = maintenanceReportsData.where((main) => main.type == type && managerReportsFilterString(main.states) == statusFilter).toList();
    }
    emit(FilterDataState());
  }

  Future<void> updateReportState(int reportId, ManagerReportsFilter newState , String state) async {
    // Update local model
     final filteredIdx = maintenanceReportsData.indexWhere((r) => r.id == reportId);
     if (filteredIdx != -1) {
       final updatedFilteredMap = maintenanceReportsData[filteredIdx].toJson();
       updatedFilteredMap['status'] = newState.value;
       maintenanceReportsData[filteredIdx] = MaintenanceReports.fromJson(updatedFilteredMap);
     }


    // call API / backend to persist the new state for reportId

     await supabase.from("MaintenanceReports").update({'status':state}).eq('compound_id',selectedCompoundId!).eq('type',currentMaintenanceType.name).eq('id',reportId);

    // Re-apply filters so UI updates (filterRequests already emits)
    filterRequests(type: currentMaintenanceType, statusFilter: ManagerReportsFilter.values[filterIndex]);
     emit(FilterDataState());
  }
}

