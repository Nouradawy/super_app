import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:super_app/Layout/Cubit/states.dart';

import '../../Components/Constants.dart';
import '../../sevices/GoogleDriveService.dart';

class AppCubit extends Cubit<AppCubitStates> {
  AppCubit():super(AppInitialState());
  static AppCubit get(context) => BlocProvider.of(context);
  bool isPassword = true;
  String? RoleName ;

  IconData? suffixIcon = Icons.visibility;
  bool ActivateDropdown = false;
  int AccountIndex = 0;


  void Passon(){
    isPassword =! isPassword;
    suffixIcon = isPassword ?Icons.visibility:Icons.visibility_off;
    emit(InputIsPasswordState());
  }

  void SignupRoleName(String roleName){
    RoleName = roleName;
    emit(SignupRoleChangeState());
  }

  void SignUpSignInToggle(){
    emit(SignUpSignIn_Toggle());
  }

  void SendChatMessage(){
    emit(MessageSentState());
  }

  void AccountSettingsDropdown(index){
    AccountIndex = index;
    ActivateDropdown = !ActivateDropdown;
    emit(AccountSettingsExpandStates());
  }

  void googleSignin()async{
    if (googleUser == null) {
      final user = await driveService.signIn();
      if (user != null) {
        googleUser = user;
      }
    } else {
      await driveService.signOut();
      googleUser = null;
    }
    emit(GoogleSigninStates());
  }
}