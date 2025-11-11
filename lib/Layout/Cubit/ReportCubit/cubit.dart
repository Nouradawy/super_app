import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:ntp/ntp.dart';
import 'package:super_app/Confg/supabase.dart';
import 'package:super_app/Layout/Cubit/ReportCubit/states.dart';


class ReportUsers{
  final int? id;
  final String authorId;
  final DateTime createdAt;
  final String reportedUserId;
  final String state;
  final String description;
  final String messageId;
  final String reportedFor;


  ReportUsers({
    this.id,
    required this.authorId,
    required this.createdAt,
    required this.reportedUserId,
    required this.state,
    required this.description,
    required this.messageId,
    required this.reportedFor,
  });

  factory ReportUsers.fromJson(Map<String,dynamic> json){
    return ReportUsers(
      id:json['id'],
      authorId: json['authorId'],
      createdAt: DateTime.tryParse(json['createdAt'])!,
      reportedUserId: json['reportedUserId'],
      state: json['state'],
      description: json['description'],
      messageId: json['messageId'],
      reportedFor: json['reportedFor'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorId': authorId.trim(),
      'createdAt': createdAt.toIso8601String(),
      'reportedUserId': reportedUserId.trim(),
      'state': state,
      'description': description,
      'messageId': messageId,
      'reportedFor': reportedFor,
    };
  }


}

enum ReportsFilters{
  All,
  New,
  inReview,
  Resolved
}

enum ReportType{
  spam,
  harassment,
  selling,
  inappropriateContent
}
class ReportCubit extends Cubit<ReportCubitState> {
  ReportCubit():super(ReportInitialState());
  static ReportCubit get(context) =>BlocProvider.of(context);

  TextEditingController reportDescription = TextEditingController();
  TextEditingController issueType = TextEditingController();
  late String reportAuthorId;
  late String reportedUserId;
  late String messageId;

  int index = 0;
  ReportUsers? reportUser;

  List<ReportUsers> reportListData = [];




ListView reportsList(){
  return ListView.builder(
    shrinkWrap: true,
    itemCount: reportListData.length,
    itemBuilder: (context,index){
      final member = ChatMembers.firstWhere((m)=>m.id.trim() == reportListData[index].reportedUserId);
      final author_member = ChatMembers.firstWhere((m)=>m.id.trim() == reportListData[index].authorId);
      return Card(
        elevation: 0.5,
        margin: EdgeInsets.symmetric(horizontal: 30 , vertical: 7),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0 , horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// Reported User Details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                          child: member.avatarUrl == null ? Icon(Icons.person) : null,
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(member.name),
                              Text("Reported ${reportListData[index].createdAt.hour.toString()}")
                            ]),
                      ],),
                    Chip(
                      visualDensity: VisualDensity(vertical: -4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.symmetric(horizontal: 0.0,vertical: 0),
                      label: Text(reportListData[index].state),
                      labelStyle:TextStyle(color: Colors.redAccent , fontWeight: FontWeight.w900 , ),
                      backgroundColor: Colors.red.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),

                    ),
                  ]),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                child: Text(reportListData[index].description),
              ),
              Divider(thickness: 0.7),
              Padding(
                  padding:const EdgeInsets.symmetric(vertical: 7),
                child: Text("Reported by ${author_member.name} for ${ReportType.inappropriateContent.name}"),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> fileReportToUser()async {
  await supabase.from('Report_user').insert(
      ReportUsers(
        authorId: reportAuthorId,
        createdAt: DateTime.now().toUtc(),
        reportedUserId: reportedUserId,
        state: "New",
        description: reportDescription.text,
        messageId: messageId,
        reportedFor: issueType.text,
      ).toJson());

}

Future<void> getReportList() async{
  final result = await supabase.from('Report_user').select('*');
  reportListData = result.map((element)=>ReportUsers.fromJson(element)).toList();
}

}