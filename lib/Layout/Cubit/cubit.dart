import 'dart:convert';
import 'dart:io';
import 'package:WhatsUnity/Model/MaintenanceReport.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:flutter_polls/flutter_polls.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:ntp/ntp.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:WhatsUnity/Layout/Cubit/states.dart';
import 'package:WhatsUnity/Layout/chatWidget/GeneralChat/GeneralChat.dart';
import 'package:uuid/uuid.dart';
import '../../Confg/Enums.dart';
import '../../Model/CompoundsList.dart';
import '../../Model/CompoundsList.dart' as type;
import '../../Components/Constants.dart';
import '../../Confg/supabase.dart';
import '../../Network/CacheHelper.dart';
import '../../Services//GoogleDriveService.dart';
import '../../Services/PresenceManager.dart';
import '../../Services/gumletService.dart';
import '../MainScreen.dart';
import '../chatWidget/Details/ChatMember.dart';

class AppCubit extends Cubit<AppCubitStates> {
  AppCubit():super(AppInitialState());
  static AppCubit get(context) => BlocProvider.of(context);
  RealtimeChannel? _presenceChannel;
  final supabase = Supabase.instance.client;
  String? _userId;

  int bottomNavIndex = 0;
  bool isPassword = true;
  Roles? roleName ;
  bool apartmentConflict =false;

  IconData? suffixIcon = Icons.visibility;
  bool ActivateDropdown = false;
  int AccountIndex = 0;
  /// used to Get Current TabBar (Chat - Social) Index at HomePage
  int  tabBarIndex =  0 ;
  bool isRecording = false;

  bool signInToggler = false;

  List<double> recordedAmplitudes = [];
  List<type.Category> compoundSuggestions = categories;
  types.InMemoryChatController? chatController ;

  List<XFile>? verFiles;
  bool signingIn = false;

  ///Posts

  int postsCarouselIndex = 0;

  bool apartmentAlreadyRegisterd = false;

  Future<void> apartmentAlreadyTaken({
    required String compoundId,
    required String buildingNum,
    required String apartmentNum,

  }) async {
    final rows = await supabase
        .from('user_apartments')
        .select('user_id')
        .eq('compound_id', compoundId)
        .eq('building_num', buildingNum)
        .eq('apartment_num', apartmentNum)
        .limit(1);

    apartmentAlreadyRegisterd =rows.isNotEmpty? true : false;
    emit(FormValidationState());

  }

  Map<String, dynamic> get currentPresence {
    final state = _presenceChannel?.presenceState();
    if (state == null) return {};

    final Map<String, dynamic> map = {};
    for (final item in state) {
      map[item.key] = item.presences.map((p) => p.payload).toList();
    }
    debugPrint('Cubit presence map: $map');
    return map;
  }

  void signInSwitcher(){
    signingIn = !signingIn;
    emit(SignInState());
  }
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

  void onChangedCarousel(index){
    postsCarouselIndex = index;
    emit(postsOnChangedCarsoleState());
  }

  void showHideMicBrain(){

      emit(ShowHideMicStates());
  }

  void initializePresence() {
    _userId = Supabase.instance.client.auth.currentUser?.id;
    if (_userId == null) {
      debugPrint('Presence: No user ID found');
      return;
    }

    // Important: Always use the same channel name everywhere
    const channelName = 'global_presence';
    _presenceChannel = supabase.channel(channelName);

    // Optional — helpful to debug who else is online in the cubit
    _presenceChannel!
        .onPresenceSync((_) {
      final state = _presenceChannel!.presenceState();
      debugPrint('CUBIT presence sync: $state');
      emit(PresenceUpdated());
    });

    // Subscribe and track AFTER the server confirms subscription
    _presenceChannel!.subscribe((status, [error]) async {
      debugPrint('Presence channel status: $status ${error ?? ''}');
      if (status == RealtimeSubscribeStatus.subscribed) {
        await Future.delayed(const Duration(milliseconds: 300)); // give it a moment
        await updatePresenceStatus('online');
        debugPrint('Presence tracked for user $_userId');
      }
    });
  }


  // Method to update the status payload
  Future<void> updatePresenceStatus(String status) async {
    if (_presenceChannel == null || _userId == null) return;
    await _presenceChannel!.track({
      'user_id': _userId,
      'status': status, // The important part: 'online' or 'available'
    });
    debugPrint('user set as online success');
  }

  // Method to untrack (signals leaving)
  Future<void> untrackPresence() async {
    if (_presenceChannel == null) return;
    await _presenceChannel!.untrack();
  }

  // Method for cleanup
  void disconnectPresence() {
    if (_presenceChannel != null) {
      _presenceChannel!.unsubscribe();
    }
  }

  void bottomNavIndexChange(index){
    bottomNavIndex = index;
    if(bottomNavIndex!=0) tabBarIndex=0;
    emit(BottomNavIndexChangeStates());
  }

  Future<void> selectCompound({Compound? compound , required bool atWelcome} ) async {

    if(atWelcome){
      final args = {
        'url': 'https://nouradawysupabase.duckdns.org', // Your URL
        'anonKey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNjQwOTk1MjAwLCJleHAiOjE5NTY1NTY4MDB9.EOD6RIRAhlJkyIRu92VOWxuCh9E5eJ_DCRWXvAO7YyA', // Your Anon Key
        'CompoundIndex' : compound!.id,
        'role': userRole?.name,
      };
      MyCompounds = {
        '0': "Add New Community",
        compound.id.toString(): compound.name.toString()
      };


      selectedCompoundId = compound.id;
      await CacheHelper.saveData(key: "compoundCurrentIndex", value: compound.id);

      emit(CompoundIdChange());
      //TODO: Fixing on signup fetching compound posts here
      final result =await compute(fetchCompoundMembers,args);
      ChatMembers = result.members;
      if(userRole == Roles.admin) MembersData = result.membersData;
    }
    await CacheHelper.saveData(key: "MyCompounds", value: json.encode(MyCompounds));
    emit(CompoundIdChange());

  }

  Future<void> loadCompoundMembers(int compoundIndex)async{
    final args = {
      'url': 'https://nouradawysupabase.duckdns.org', // Your URL
      'anonKey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNjQwOTk1MjAwLCJleHAiOjE5NTY1NTY4MDB9.EOD6RIRAhlJkyIRu92VOWxuCh9E5eJ_DCRWXvAO7YyA', // Your Anon Key
      'CompoundIndex' : compoundIndex,
      'role': userRole?.name,
    };
    final result =await compute(fetchCompoundMembers,args);

    ChatMembers = result.members;
    currentUser = ChatMembers.firstWhere((member) => member.id.trim() == Userid);

    if(userRole == Roles.admin) MembersData = result.membersData;

    emit(CompoundMembersUpdated());
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

  void SignupRoleName(Roles? newRoleName){
    roleName = newRoleName;
    emit(SignupRoleChangeState());
  }

  void SignUpSignInToggle(){
    signInToggler = !signInToggler;
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



  String? signupGoogleEmail;
  String? signupGoogleUserName;
  bool signInGoogle = false;

  Future<void> supabaseSignInWithGoogle({required BuildContext context , bool isSignin = false}) async {

    try {
      // 1) Ensure Google account
        final currentGoogle = await driveService.signIn();
        if (currentGoogle == null) {
          debugPrint('Google sign-in cancelled');
          return;
        }
        googleUser = currentGoogle;

      // 2) Fetch Google ID token
      final idToken = await driveService.getIdToken();
      if (idToken == null) {
        debugPrint('Failed to get Google ID token');
        return;
      }

      // 3) Sign in / sign up on local Supabase
      final res = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      final user = res.user;
      debugPrint('Supabase Google auth success, user: ${user?.id}');

      /// Signup and continue Regsitration
      if(user != null && isSignin == false)
        {
          resetUserData();
          signupGoogleEmail = user.email;
          signupGoogleUserName = googleUser?.displayName;
          emit(GoogleSignupState());
        }
      ///Signing in
      if(user != null && isSignin)
        {
          signInGoogle = true;

          UserData = Supabase.instance.client.auth.currentSession?.user;
          userRole = Roles.values[UserData?.userMetadata?["role_id"]-1];

          if(UserData != null) {
            presetBeforeSignin(context);

            signupGoogleEmail = null;
            signupGoogleUserName = null;

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PresenceManager(child: MainScreen()),
              ),
            );
          }
        }

    } catch (e, st) {
      debugPrint('Supabase Google auth error: $e\n$st');
    }
  }
  void continueGoogleRegistration( context , String fullName , int roleId , String buildingName , String apartmentNum ,OwnerTypes ownerType , String phoneNumber , String userName) async {
    await supabase.from('profiles').update({
      'full_name':fullName,
      'display_name': userName,
      'owner_type': ownerType.name,
      'phone_number' : phoneNumber
    }
    ).eq('id',Userid);

    if(roleId != 1){
      final updateRole = await supabase.from('user_roles').update({'role_id':roleId}).eq('user_id', Userid).single();
    }

    if(roleId !=2){
      if (selectedCompoundId == null) {
        debugPrint('continueGoogleRegistration: selectedCompoundId is null');
        return;
      }


        final buildingRow = await supabase.from('buildings').upsert({
          'building_name':buildingName,
          'compound_id' : selectedCompoundId!,
        },
            onConflict: 'compound_id , building_name'
        ).select('id').maybeSingle();

      if (buildingRow == null || buildingRow['id'] == null) {
        debugPrint('buildings upsert returned null / no id');
        return;
      }
      final int buildingId = buildingRow['id'] as int;
        debugPrint(
          buildingId.toString());


        await supabase.from('channels').upsert({
          'name':'Building $buildingName Chat',
          'type': 'BUILDING_CHAT',
          'compound_id': selectedCompoundId,
          'building_id' : buildingId,

        },
            onConflict: 'compound_id , building_id , type'
        );
        final apartmentNo = await supabase.from('user_apartments').insert({
          'user_id':Userid,
          'compound_id' : selectedCompoundId,
          'building_num' : buildingName,
          'apartment_num' : apartmentNum
        });


    }


    UserData = Supabase.instance.client.auth.currentSession?.user;
    userRole = Roles.values[UserData?.userMetadata?["role_id"]-1];
    signupGoogleEmail = null;
    signupGoogleUserName = null;
    if(UserData != null) {

      await loadCompoundMembers(selectedCompoundId!);
      await getPostsData(selectedCompoundId);
      await verificationFilesUpload();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PresenceManager(child: MainScreen()),
        ),
      );
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

  Future<void> signOut() async {
    signInGoogle = false;
    final int existingIndex = prevSignIn.indexWhere(
            (m) => m.containsKey(Userid));
    final newValue = {
      "googleUser": googleUser?.email,
      "compoundIndex": selectedCompoundId,
      "MyCompounds" : MyCompounds,
    };

    if (existingIndex != -1){
      prevSignIn[existingIndex][Userid] = newValue;
    } else {
      prevSignIn.add({
        Userid: newValue,
      });
    }

    await CacheHelper.saveData(key: "prevSignIn", value: json.encode(prevSignIn));
    try {
      // 1. Perform the asynchronous sign-out from Supabase.
      await supabase.auth.signOut();

      // 2. Clear any local user data.
      UserData = null;


      // 3. Emit a new state to notify the UI that sign-out is complete.
      emit(AppSignOutSuccessState()); // You'll need to create this state
    } catch (error) {
      // Handle potential errors during sign-out
      debugPrint('Error signing out: $error');
    }
  }

  Future<void> resetUserData() async {
    selectedCompoundId = null;
    await CacheHelper.saveData(key: "compoundCurrentIndex", value: selectedCompoundId);
    googleUser = null; // Also clear the googleUser if you have one
    MyCompounds = {'0': "Add New Community"};
    await CacheHelper.saveData(key: "MyCompounds", value: json.encode(MyCompounds));
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

  void attachChatController(types.InMemoryChatController controller) {
    chatController = controller;
  }

  /// Detach/clear the controller when the chat view is disposed.
  void detachChatController() {
    chatController = null;
  }

  Future<void> uploadVoiceNote(File soundFile, Duration duration , List<double> amplitudes , int compoundId) async {
    // 1. Instantiate your Google Drive service
    final googleDriveService = GoogleDriveService();

    final localId = const Uuid().v4(); // Unique ID for our placeholder
    // TODO: Consider showing a loading indicator to the user here

    final placeholderMessage = types.AudioMessage(
      id: localId,
      authorId: Userid,
      createdAt: (await NTP.now()).toUtc(),
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
    // final response = await supabase
    //     .from('channels')
    //     .select('id')
    //     .eq('compound_id',compoundId) // Use the passed-in compoundId
    //     .eq('type', 'COMPOUND_GENERAL') // As defined in the schema
    //     .single(); // Assuming one general channel per compound
    //
    //   _channelId = response['id'];
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
        'created_at': (await NTP.now()).toUtc().toIso8601String(),
        'channel_id': channelId,
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


  ///Maintenance Reports
  bool isExpanded = false;
  int reportIndex = 0;
  void expandReport (int currentIndex){
    reportIndex = currentIndex;
    if(currentIndex == reportIndex) {
      isExpanded = !isExpanded;
    }
    emit(ExpandReportState());
  }
  Future<void> reportSubmit (String title , String description , String category, List<XFile>? files , MaintenanceReportType type ) async {
    final formattedCategory = category.isNotEmpty
        ? '${category[0].toUpperCase()}${category.substring(1)}'
        : '';
    final newReport =
    await supabase.from('MaintenanceReports').insert({
      'user_id': Userid,
      'title': title,
      'description': description,
      'category':formattedCategory,
      'type':type.name,
      'compound_id':selectedCompoundId
    })
        .select('id')
        .single();

    final reportId = newReport['id'];

    if(files != null ){
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

      await supabase.from('MReportsAttachments').insert({

        'report_id': reportId,
        'source_url': imageSources,
        'compound_id':selectedCompoundId,
        'type' : type.name
      });
    }

    imageSources.clear();
    emit(NewReportSubmitState());
  }

  Future<void> getMaintenanceReports(MaintenanceReportType type) async {
    final reports = await supabase.from("MaintenanceReports").select("*").eq('compound_id',selectedCompoundId!).eq('type',type.name);
    final attachments = await supabase.from("MReportsAttachments").select("*").eq('compound_id',selectedCompoundId!).eq('type',type.name);
    maintenanceReportsData = reports.map((element) => MaintenanceReports.fromJson(element)).toList();
    maintenanceReportsAttachmentsData = attachments.map((element) => MaintenanceReportsAttachments.fromJson(element)).toList();
    emit(GetMaintenanceReportsState());
  }

  Future<void> verFileImport() async {
    List<XFile>? result = await ImagePicker()
        .pickMultiImage(
      imageQuality: 70,
      maxWidth: 1440,
    );

    if (result.isEmpty) return;

    verFiles = result;
    emit(ImportNewVerFileState());
  }

  Future<void> verificationFilesUpload () async {

    if(verFiles != null || verFiles!.isNotEmpty){

      try{
        for (final xfile in verFiles!) {
          final bytes = await xfile.readAsBytes();
          final image = await decodeImageFromList(bytes);
          int index =0;                     //count the number of items in files List used for _uploadProgress
          _uploadProgress.add(0);           //adding new item to the list and using index to update it's progress
          final file = File(xfile.path);
          final fileName = xfile.name;
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final mime = lookupMimeType(xfile.path) ?? 'application/octet-stream';
          final storage = supabase.storage.from("verification");
          final objectKey = 'users/$Userid/verifications/$fileName';
          String? driveLink;
          String? supabaseLink;

          if(storageType == Storage.googleDrive || storageType == Storage.both ){ // 1. Upload the file to Google Drive
            driveLink = await driveService.uploadFile(
              file,
              fileName,
              'image',
            );

          }
          if(storageType == Storage.superbaseStorage || storageType == Storage.both )
            {
              await storage.upload(
                objectKey,
                file,
                fileOptions: FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                  contentType: mime,
                ),
              );
              supabaseLink = storage.getPublicUrl(objectKey);
            }
          imageSources.add({
            if (driveLink != null)'uri': driveLink,
            if(supabaseLink != null)'bucket' : 'verification',
            if(supabaseLink != null)'path' : supabaseLink,
            'name': fileName,
            'size': bytes.length.toString(),
            'height': image.height.toString(),
            'width': image.width.toString(),
          });
          index++;
        }

      } catch(e) {
        debugPrint("uploading verFiles Failed ${e.toString()}");
      }

    }
    await supabase.from("profiles").update({
      'verFiles' : imageSources,
    }).eq("id", Userid);
    imageSources.clear();
    emit(UploadVerFileState());


  }

  OwnerTypes ownerType = OwnerTypes.owner;
  void ownerTypeChange(selectionIndex){
    ownerType = selectionIndex;
    emit(OwnerNewSelectionState());
  }

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
  Future<void> postNewComment (int compoundId , String postId , int postIndex , TextEditingController newComment) async {
    // await supabase.from('Posts').select('Comments').eq('compound_id', compoundId).eq('id',postId).single();
    List newComments= [];
    newComments=Posts[postIndex]['Comments']?? [];
    newComments.add({
      'author_id':Userid,
      'comment':newComment.text,});
    debugPrint(newComments.toString());
    await supabase.from('Posts').update({
      'Comments':newComments
    }).eq('id',postId);
    emit(UpdatePostCommentsState());
  }


  ///BrainStorming

  int currentCarouselIndex =0;
  void changeCarouselIndex (int index) {
    _ensureVoteBuffers(index);
    currentCarouselIndex = index;
    emit(ChangeCarsoleIndexState());
  }

  void changeCarouselPage ({bool isPrev =false , bool isNext =false, required CarouselSliderController controller}) {

    if (controller.ready != true) {
      // One deferred attempt (optional); skip if still not ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.ready != true) return;
        if (isPrev) controller.previousPage();
        if (isNext) controller.nextPage();
        emit(ChangeCarsolePageState());
      });
      return;
    }

    if (isPrev) controller.previousPage();
    if (isNext) controller.nextPage();
    emit(ChangeCarsolePageState());
  }
  Future<void> createNewBrainStorm (String title , List<XFile>? image , options , int channelId )async {
    final now = await NTP.now();
    final nowUtc = now.toUtc();

    if(image != null){

      for (final xfile in image) {
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

    try{
      await supabase.from("BrainStorming").insert({
        'id': const Uuid().v4(),
        'author_id' : Userid,
        'created_at' : nowUtc.toIso8601String(),
        'compound_id' : selectedCompoundId,
        'channel_id' : channelId,
        'Title' : title,
        'Image' : imageSources,
        'Options' : options,
      });
    } catch (error){
      debugPrint("Error during inserting at BrainStorming Table : ${error.toString()}");
    }
    imageSources.clear();
    emit(CreateNewBrainStormState());
  }

  List brainStormData=[];

  void _ensureVoteBuffers(int index) {
    while (previousOptionId.length <= index) {
      previousOptionId.add(null);
    }
    while (optionVoterIds.length <= index) {
      optionVoterIds.add(<String, List<String>>{});
    }
  }

  Future<void> getBrainStormData(int channelId) async{
    try{
      brainStormData = await supabase.from("BrainStorming").select('*').eq('compound_id',selectedCompoundId!).eq('channel_id',channelId);
      previousOptionId =
      List<String?>.filled(brainStormData.length, null, growable: true);
      optionVoterIds = List<Map<String, List<String>>>.generate(
        brainStormData.length,
            (_) => <String, List<String>>{},
        growable: true,
      );
    } catch(error){
      debugPrint('Error during pulling BrainStorm Data : ${error.toString()}');
    }
    emit(CreateNewBrainStormState());
  }

  List<String?> previousOptionId = [];
  List<Map<String, List<String>>> optionVoterIds = [];


  Future<void> addCurrentPollId (String index) async{

    emit(addIndexState());
  }

  Future<void> handleBrainStormVote(PollOption option, {required String pollId}) async {
    // Locate poll index
    final int idx = brainStormData.indexWhere((e) => e['id'] == pollId);
    if (idx == -1) return;

    // Normalize existing votes
    final rawVotesAny = brainStormData[idx]['Votes'];
    final Map<String, Map<String, bool>> votes = {};
    if (rawVotesAny is Map) {
      rawVotesAny.forEach((k, v) {
        final key = k.toString();
        final Map<String, bool> inner = {};
        if (v is Map) {
          v.forEach((vk, vv) => inner[vk.toString()] = vv == true);
        }
        votes[key] = inner;
      });
    }

    // Detect previous user selection (for this poll only)
    String? prevOptionIdLocal;
    votes.forEach((opId, voters) {
      if (voters.containsKey(Userid)) prevOptionIdLocal = opId;
    });

    final targetId = option.id.toString();
    final bool isUnvote = prevOptionIdLocal == targetId;

    // Apply mutation locally (optimistic)
    if (isUnvote) {
      votes[targetId]?.remove(Userid);
      if (votes[targetId]?.isEmpty ?? true) votes.remove(targetId);
    } else {
      if (prevOptionIdLocal != null && prevOptionIdLocal != targetId) {
        votes[prevOptionIdLocal]?.remove(Userid);
        if (votes[prevOptionIdLocal]?.isEmpty ?? true) votes.remove(prevOptionIdLocal);
      }
      votes.putIfAbsent(targetId, () => <String, bool>{});
      votes[targetId]![Userid] = true;
    }

    // Recompute option vote counts
    final List<Map<String, dynamic>> options =
    (brainStormData[idx]['Options'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    for (final o in options) {
      final idStr = o['id'].toString();
      o['votes'] = votes[idStr]?.length ?? 0;
    }

    // Update local poll object
    brainStormData[idx]['Votes'] = votes;
    brainStormData[idx]['Options'] = options;

    emit(BrainStormVoteUpdated());

    // Persist (no full list refetch to avoid slide flicker)
    try {
      await supabase
          .from("BrainStorming")
          .update({'Votes': votes, 'Options': options})
          .eq('id', pollId);
    } catch (e) {
      debugPrint("vote persist error $e");
    }
  }


}