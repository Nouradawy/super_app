import 'package:WhatsUnity/Components/Constants.dart';
import 'package:WhatsUnity/Confg/Enums.dart';
import 'package:WhatsUnity/Layout/Cubit/ReportCubit/cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:WhatsUnity/Layout/Cubit/ChatDetailsCubit/states.dart';

import '../../../Confg/supabase.dart';
import '../../../Model/ReportAUser.dart';
import '../../chatWidget/Details/ChatMember.dart';

class ChatDetailsCubit extends Cubit<ChatDetailsStates> {
  ChatDetailsCubit():super(ChatInitialState());
  static ChatDetailsCubit get(context) => BlocProvider.of(context);

  int selectedIndex = 0;
  bool isExpanded = false;
  String? selectedMemberId;
  NavigationRailLabelType labelType = NavigationRailLabelType.all;
  List<ReportAUsers> userFilteredReports = [];

  void indexChange(index){
    selectedIndex = index;
    selectedMemberId = null;
    emit(ChatDetailsIndexChange());
  }

  void selectMember(String id) {
    selectedMemberId = id;
    emit(ChatDetailsMemberSelected());
  }

  void clearSelectedMember() {
    selectedMemberId = null;
    emit(ChatDetailsMemberCleared());
  }

  void expandReport (int currentIndex){
    selectedIndex = currentIndex;
    if(currentIndex == selectedIndex) {
      isExpanded = !isExpanded;
    }
    emit(ExpandReportState());
  }
  List<ReportAUsers> reportFilterUser(BuildContext context , String userId)  {
    final reportList = ReportCubit.get(context).reportListData;
    return reportList.where((report)=>report.reportedUserId == userId).toList();
  }

  Future<void> banUser(String userid , UserState banType) async {
    debugPrint("ban pressed:$userid");

    await supabase.from('profiles').update({"userState":banType.name}).eq('id',userid);
    final index = ChatMembers.indexWhere((m) => m.id == userid);
    if (index != -1) {
      ChatMembers[index] = ChatMember(
          id: ChatMembers[index].id,
          displayName: ChatMembers[index].displayName,
          building: ChatMembers[index].building,
          apartment: ChatMembers[index].apartment,
          userState: banType,
          phoneNumber: ChatMembers[index].phoneNumber,
          ownerType: ChatMembers[index].ownerType,
        avatarUrl: ChatMembers[index].avatarUrl,
        fullName: ChatMembers[index].fullName
      );
    }
    emit(BanMemberState());
  }

  void onProfileUpdated(ChatMember member) {

    emit(ProfileUpdatedState(member: member));
  }

}
