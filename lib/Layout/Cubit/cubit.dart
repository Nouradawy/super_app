import 'dart:convert';
import 'dart:io';


import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ntp/ntp.dart';
import 'package:super_app/Layout/Cubit/states.dart';
import 'package:super_app/Layout/GeneralChat.dart';
import 'package:uuid/uuid.dart';

import '../../Model/CompoundsList.dart';
import '../../Model/CompoundsList.dart' as type;
import '../../Components/Constants.dart';
import '../../Confg/supabase.dart';
import '../../Network/CacheHelper.dart';
import '../../sevices/GoogleDriveService.dart';
import '../../sevices/gumletService.dart';

class AppCubit extends Cubit<AppCubitStates> {
  AppCubit():super(AppInitialState());
  static AppCubit get(context) => BlocProvider.of(context);

  int bottomNavIndex = 0;
  bool isPassword = true;
  Roles? roleName ;

  IconData? suffixIcon = Icons.visibility;
  bool ActivateDropdown = false;
  int AccountIndex = 0;
  /// used to Get Current TabBar (Chat - Social) Index at HomePage
  int  tabBarIndex =  0 ;
  bool isRecording = false;
  List<double> recordedAmplitudes = [];
  List<type.Category> compoundSuggestions = categories;
  types.InMemoryChatController? chatController ;


  /// used to Switch TabBar Index at [Social] page
  void tabBarIndexSwitcher(index){
    tabBarIndex = index;
    emit(TabBarIndexStates());
  }
  bool isChatInputEmpty = true;
  /// used to Switch Mic States (view or hide) it form [GeneralChat] page
  void showHideMic(bool isEmpty){

    if (isChatInputEmpty != isEmpty) {
      isChatInputEmpty = isEmpty;
      emit(ShowHideMicStates());
    }
  }

  void bottomNavIndexChange(index){
    bottomNavIndex = index;
    print(bottomNavIndex);
    emit(BottomNavIndexChangeStates());
  }

  Future<void> selectCompound({Compound? compound , required bool atWelcome} ) async {
    if(atWelcome){
      MyCompounds.addAll({
        compound!.id.toString(): compound.name
            .toString()
      });

      await CacheHelper.saveData(key: "MyCompounds", value: json.encode(MyCompounds));
      selectedCompoundId = compound.id;
    }
    emit(CompoundIdChange());

  }

  void compoundIdSelected()=>emit(CompoundIdChange());


  void Passon(){
    isPassword =! isPassword;
    suffixIcon = isPassword ?Icons.visibility:Icons.visibility_off;
    emit(InputIsPasswordState());
  }


  void micOnPressed(){
    isRecording = !isRecording;
    emit(isRecordingStates());
  }

  void SignupRoleName(Roles? roleName){
    roleName = roleName;
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

  Future<void> signOut() async {
    try {
      // 1. Perform the asynchronous sign-out from Supabase.
      await supabase.auth.signOut();

      // 2. Clear any local user data.
      UserData = null;
      selectedCompoundId = null;
      await CacheHelper.saveData(key: "compoundCurrentIndex", value: selectedCompoundId);
      googleUser = null; // Also clear the googleUser if you have one
      MyCompounds = {'0': "Add New Community"};
      await CacheHelper.saveData(key: "MyCompounds", value: json.encode(MyCompounds));

      // 3. Emit a new state to notify the UI that sign-out is complete.
      emit(AppSignOutSuccessState()); // You'll need to create this state
    } catch (error) {
      // Handle potential errors during sign-out
      debugPrint('Error signing out: $error');
    }
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


  Future<void> loadCompounds () async {
    final args = SupabaseArgs(
      url: 'https://nouradawysupabase.duckdns.org', // Your URL
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNjQwOTk1MjAwLCJleHAiOjE5NTY1NTY4MDB9.EOD6RIRAhlJkyIRu92VOWxuCh9E5eJ_DCRWXvAO7YyA', // Your Anon Key
    );

    categories = await compute(fetchCompounds,args);
    emit(CategoriesLoadedSuccess());

  }

  void getSuggestions(TextEditingController controller) {
    if(controller.text.isEmpty) { compoundSuggestions = categories;}
    else {
      compoundSuggestions = categories.map((category) {
        final filteredCompounds = category.compounds
            .where((compound) => compound.name.toLowerCase().contains(controller.text.toLowerCase()))
            .toList();

        return type.Category(
          id: category.id,
          name: category.name,
          compounds: filteredCompounds
        );
      }).toList();
      compoundSuggestions.removeWhere((category) => category.compounds.isEmpty);
    }


    emit(CompoundSuggestionsUpdated());
  }
  Future<void> uploadVoiceNote(File soundFile, Duration duration , List<double> amplitudes , int compoundId) async {
    // 1. Instantiate your Google Drive service
    final googleDriveService = GoogleDriveService();
    int? _channelId;
    final localId = const Uuid().v4(); // Unique ID for our placeholder
    // TODO: Consider showing a loading indicator to the user here

    final placeholderMessage = types.AudioMessage(
      id: localId,
      authorId: Userid,
      createdAt: await NTP.now(),
      metadata: {
        'type': 'soundFile',
        'localId': localId,
        'status': 'processing',
        'waveform': amplitudes,
      },
      source: "soundFile",
      duration: duration,

    );

    chatController?.insertMessage(placeholderMessage);
    final response = await supabase
        .from('channels')
        .select('id')
        .eq('compound_id',compoundId) // Use the passed-in compoundId
        .eq('type', 'COMPOUND_GENERAL') // As defined in the schema
        .single(); // Assuming one general channel per compound

      _channelId = response['id'];
      emit(GetPostsDataStates());
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
        'created_at': (await NTP.now()).toIso8601String(),
        'channel_id': _channelId,
        'metadata': {
          'type': 'audio',
          'name': fileName,
          'size': await soundFile.length(),
          'localId': localId,
          // Format duration to a string like "01:23"
          'duration': '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
          'waveform': amplitudes,
          'status': 'processing'
        },
      });

      print('Successfully uploaded voice note and created Supabase record.');

    } catch (e) {
      print('Error uploading voice note: $e');
      // Optionally, emit a state to show an error
    }
  }

  final List _uploadProgress = [];

  final List<Map<String, String>> imageSources = [];

  Future<void> fetchPostsData (String postHead , bool getCalls , String? type , List<XFile>? files , int compoundId ) async {

    if(files != null || files!.isNotEmpty){

      for (final xfile in files) {
        final bytes = await xfile.readAsBytes();
        final image = await decodeImageFromList(bytes);
        int index =0;                     //count the number of items in files List used for _uploadProgress
        _uploadProgress.add(0);           //adding new item to the list and using index to update it's progress
        final file = File(xfile.path);
        final fileName = xfile.name;


        // 1. Upload the file to Google Drive
        final driveLink = await driveService.uploadFile(
            file,
            fileName,
            'image',
        );
        if(driveLink !=null){
          imageSources.add({
            'uri': driveLink,
            'name': fileName,
            'size': bytes.length.toString(),
            'height': image.height.toString(),
            'width': image.width.toString(),
          });
        }
        index++;
      }
    }

    await supabase.from('Posts').insert({
      'id': const Uuid().v4(),
      'compound_id': compoundId,
      'author_id': Userid,
      'user_name':UserData!.userMetadata!["display_name"].toString(),
      'post_head': postHead,
      'source_url': imageSources,
      'getCalls':getCalls,


  });
    imageSources.clear();
    emit(NewPostState());

  }

  List Posts=[];

  Future<void> getPostsData (int? compoundId) async {
    if(compoundId !=null) {
      Posts = await supabase.from('Posts').select('*').eq('compound_id', compoundId);
    }
    emit(GetPostsDataStates());
  }





}