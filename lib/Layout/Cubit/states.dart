import 'package:flutter/cupertino.dart';

import '../../Confg/Enums.dart';
import '../chatWidget/Details/ChatMember.dart';

abstract class AppCubitStates{}

class AppInitialState extends AppCubitStates{}
class InputIsPasswordState extends AppCubitStates{}
class SignInState extends AppCubitStates{}
class SignupRoleChangeState extends AppCubitStates{}
class ProfileApplyChangesState extends AppCubitStates{}

class AppProfileSectionToggledState extends AppCubitStates {
  final ProfileSection section;
  final int? index;
  AppProfileSectionToggledState({required this.section, required this.index});
}
class AppPasswordUpdatedState extends AppCubitStates {}

class AppEmailChangeRequestedState extends AppCubitStates {
  final String newEmail;
  AppEmailChangeRequestedState(this.newEmail);
}

class AppEmailChangeVerifiedState extends AppCubitStates {}

class AppEmailChangeFailedState extends AppCubitStates {
  final String message;

  AppEmailChangeFailedState(this.message);
}

class MessageSentState extends AppCubitStates{}
class LoadAnnouncementState extends AppCubitStates{}
class ProfileUpdatedState extends AppCubitStates{
  final ChatMember member;

  ProfileUpdatedState({required this.member});
}
class UserRoleChangedState extends AppCubitStates{
  final Roles role;
  UserRoleChangedState({required this.role});
}
class GoogleSigninStates extends AppCubitStates{}
class AccountSettingsExpandStates extends AppCubitStates{}
class SignUpSignIn_Toggle extends AppCubitStates{}
class TabBarIndexStates extends AppCubitStates{}
class ShowHideMicStates extends AppCubitStates{}
class isRecordingStates extends AppCubitStates{}
class UploadProgressStates extends AppCubitStates{}
class GetPostsDataStates extends AppCubitStates{}
class CompoundIdChanged extends AppCubitStates{}
class CompoundIdChange extends AppCubitStates{}
class NewPostState extends AppCubitStates{}
class NewReportSubmitState extends AppCubitStates{}
class ExpandReportState extends AppCubitStates{}
class GetMaintenanceReportsState extends AppCubitStates{}
class PresenceUpdated extends AppCubitStates{}
class BottomNavIndexChangeStates extends AppCubitStates{}
class CompoundSuggestionsUpdated extends AppCubitStates{}
class CompoundMembersUpdated extends AppCubitStates{}
class CategoriesLoadedSuccess extends AppCubitStates{}
class AppSignOutSuccessState extends AppCubitStates{}
class CreateNewBrainStormState extends AppCubitStates{}
class HandelNewBrainStormState extends AppCubitStates{}
class ImportNewVerFileState extends AppCubitStates{}
class OwnerNewSelectionState extends AppCubitStates{}
class UploadVerFileState extends AppCubitStates{}
class postsOnChangedCarsoleState extends AppCubitStates{}
class ChangeCarsolePageState extends AppCubitStates{}
class ChangeCarsoleIndexState extends AppCubitStates{}
class addIndexState extends AppCubitStates{}
class BrainStormVoteUpdated extends AppCubitStates{}
class GoogleSignupState extends AppCubitStates{}
class UpdatePostCommentsState extends AppCubitStates{}
class FormValidationState extends AppCubitStates{}
