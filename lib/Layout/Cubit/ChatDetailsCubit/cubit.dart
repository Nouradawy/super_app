import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:WhatsUnity/Layout/Cubit/ChatDetailsCubit/states.dart';

class ChatDetailsCubit extends Cubit<ChatDetailsStates> {
  ChatDetailsCubit():super(ChatInitialState());
  static ChatDetailsCubit get(context) => BlocProvider.of(context);

  int selectedIndex = 0;
  String? selectedMemberId;
  NavigationRailLabelType labelType = NavigationRailLabelType.all;

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

}
