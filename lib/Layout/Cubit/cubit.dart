import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_app/Layout/Cubit/states.dart';

class AppCubit extends Cubit<AppCubitStates> {
  AppCubit():super(AppInitialState());
  static AppCubit get(context) => BlocProvider.of(context);
  bool isPassword = true;
  String? RoleName ;

  IconData? suffixIcon = Icons.visibility;


  void Passon(){
    isPassword =! isPassword;
    suffixIcon = isPassword ?Icons.visibility:Icons.visibility_off;
    emit(InputIsPasswordState());
  }

  void SignupRoleName(String roleName){
    RoleName = roleName;
    emit(SignupRoleChangeState());
  }

  void SendChatMessage(){
    emit(MessageSentState());
  }
}