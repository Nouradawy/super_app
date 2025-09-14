import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:super_app/Layout/Cubit/states.dart';
import 'package:super_app/Layout/GeneralChat.dart';
import 'package:uuid/uuid.dart';

import '../../Components/CompoundsList.dart';
import '../../Components/Constants.dart';
import '../../Confg/supabase.dart';
import '../../sevices/GoogleDriveService.dart';
import '../../sevices/gumletService.dart';

class AppCubit extends Cubit<AppCubitStates> {
  AppCubit():super(AppInitialState());
  static AppCubit get(context) => BlocProvider.of(context);
  bool isPassword = true;
  String? RoleName ;

  IconData? suffixIcon = Icons.visibility;
  bool ActivateDropdown = false;
  int AccountIndex = 0;
  /// used to Get Current TabBar (Chat - Social) Index at HomePage
  int tabBarIndex =  0 ;
  bool isRecording = false;



  /// used to Switch TabBar Index at [Social] page
  void tabBarIndexSwitcher(index){
    tabBarIndex = index;
    emit(TabBarIndexStates());
  }

  /// used to Switch Mic States (view or hide) it form [Generalchat] page
  void showHideMic(){

      emit(ShowHideMicStates());
  }

  void Passon(){
    isPassword =! isPassword;
    suffixIcon = isPassword ?Icons.visibility:Icons.visibility_off;
    emit(InputIsPasswordState());
  }


  void micOnPressed(){
    isRecording = !isRecording;
    emit(isRecordingStates());
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

  Future<List<Category>> fetchCompounds () async {

      // This is the magic query:
      // 1. From the 'categories' table...
      // 2. Select all its columns (*), AND...
      // 3. Select all columns (*) from the 'compounds' table that are related to it.
      // Supabase knows the relationship because of the Foreign Key you created.
      final response = await supabase
          .from('compound_categories')
          .select('*, compounds(*)'); // MAGIC!

      // Supabase returns a List<dynamic> where each element is a Map (a category)
      // We parse this raw data into our clean Dart models
      final data = (response as List)
          .map((categoryJson) => Category.fromJson(categoryJson))
          .toList();

      return data;

  }


  Future<void> uploadVoiceNote(File soundFile, Duration duration) async {
    // 1. Instantiate your Google Drive service
    final googleDriveService = GoogleDriveService();

    // Ensure the user is signed in to Google Drive
    if (googleDriveService.currentUser == null) {
      await googleDriveService.signIn();
      if (googleDriveService.currentUser == null) {
        print('Google Sign-In failed. Aborting voice note upload.');
        // Optionally, emit a state to show an error to the user
        return;
      }
    }

    final fileName = 'voice_note_${const Uuid().v4()}.m4a';

    try {
      // 2. Upload the file to Google Drive
      final fileLink = await googleDriveService.uploadFile(
        soundFile,
        fileName,
        'audio', // Specify the file type
      );

      if (fileLink == null) {
        throw Exception('Failed to get Google Drive link.');
      }

      // 3. Upload the file from google drive to gumlet
      final String? gumleturl = await uploadVoiceNoteGumlet(fileLink);

      if (gumleturl == null) {
        throw Exception('Failed to get Gumlet URL.');
      }

      // 3. If upload is successful, insert the record into Supabase
      await supabase.from('messages').insert({
        'id': const Uuid().v4(),
        'author_id': Userid, // Assuming Userid is accessible here
        'uri': gumleturl, // The public link from Google Drive
        'created_at': DateTime.now().toIso8601String(),
        'metadata': {
          'type': 'audio',
          'name': fileName,
          'size': await soundFile.length(),
          // Format duration to a string like "01:23"
          'duration': '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
        },
      });

      print('Successfully uploaded voice note and created Supabase record.');

    } catch (e) {
      print('Error uploading voice note: $e');
      // Optionally, emit a state to show an error
    }
  }
}