import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;
import '../../../../core/config/Enums.dart';
import '../../../../core/config/supabase.dart';
import '../../../../core/constants/Constants.dart';
import '../../../../core/models/CompoundsList.dart';
import '../../../../core/network/CacheHelper.dart';
import '../../../chat/presentation/widgets/chatWidget/Details/ChatMember.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  // UI state moved from AppCubit
  bool isPassword = true;
  IconData suffixIcon = Icons.visibility_off;
  bool signInToggler = false;
  OwnerTypes ownerType = OwnerTypes.owner;
  String? signupGoogleEmail;
  String? signupGoogleUserName;
  bool signInGoogle = false;

  bool signingIn = false;
  List<XFile>? verFiles;
  final List<double> uploadProgress = [];
  bool apartmentConflict = false;

  List<Category> compoundSuggestions = [];

  Roles roleName = Roles.user;
  int? selectedCompoundId;
  Map<String, dynamic> myCompounds = {'0': "Add New Community"};

  AuthCubit({required this.repository}) : super(AuthInitial()) {
    repository.onAuthStateChange.listen((data) {
      // Token refresh fires often and would rebuild the whole tree (e.g. MainScreen) for no UI change.
      if (data.event == AuthChangeEvent.tokenRefreshed) return;

      final user = data.session?.user;
      if (user != null) {
        if (state is Authenticated) {
          emit((state as Authenticated).copyWith(user: user));
        } else {
          emit(Authenticated(
            user: user,
            enabledMultiCompound: enabledMultiCompound,
            googleUser: googleUser,
            categories: state.categories,
            compoundsLogos: state.compoundsLogos,
          ));
        }
      } else {
        emit(Unauthenticated(
          categories: state.categories,
          compoundsLogos: state.compoundsLogos,
        ));
      }
    });
  }

  bool enabledMultiCompound = false;
  GoogleSignInAccount? googleUser;

  void togglePasswordVisibility() {
    isPassword = !isPassword;
    suffixIcon = isPassword ? Icons.visibility_off : Icons.visibility;
    if (state is Authenticated) {
      emit((state as Authenticated).copyWith());
    } else if (state is Unauthenticated) {
      emit(Unauthenticated(categories: state.categories, compoundsLogos: state.compoundsLogos));
    } else {
      emit(AuthInitial(categories: state.categories, compoundsLogos: state.compoundsLogos));
    }
  }

  void toggleSignIn() {
    signInToggler = !signInToggler;
    if (state is Authenticated) {
      emit((state as Authenticated).copyWith());
    } else if (state is Unauthenticated) {
      emit(Unauthenticated(categories: state.categories, compoundsLogos: state.compoundsLogos));
    } else {
      emit(AuthInitial(categories: state.categories, compoundsLogos: state.compoundsLogos));
    }
  }

  void changeRole(Roles? newRole) {
    roleName = newRole ?? Roles.user;
    if (state is Authenticated) {
      emit((state as Authenticated).copyWith(role: roleName));
    } else {
      emit(AuthInitial());
    }
  }

  void updateMember(ChatMember updatedMember) {
    if (state is Authenticated) {
      final s = state as Authenticated;
      final members = List<ChatMember>.from(s.chatMembers);
      final index = members.indexWhere((m) => m.id == updatedMember.id);
      if (index != -1) {
        members[index] = updatedMember;
        
        ChatMember? current = s.currentUser;
        if (current?.id == updatedMember.id) {
          current = updatedMember;
        }

        emit(s.copyWith(chatMembers: members, currentUser: current));
      }
    }
  }

  void updateRole(Roles role) {
    if (state is Authenticated) {
      emit((state as Authenticated).copyWith(role: role));
    }
  }

  void changeOwnerType(OwnerTypes newType) {
    ownerType = newType;
    emit(AuthInitial());
  }

  void signInSwitcher() {
    signingIn = !signingIn;
    emit(AuthInitial());
  }

  Future<void> verFileImport() async {
    final List<XFile> result = await ImagePicker().pickMultiImage(
      imageQuality: 70,
      maxWidth: 1440,
    );

    if (result.isEmpty) return;

    verFiles = result;
    emit(AuthInitial());
  }

  void clearVerFiles() {
    verFiles = null;
    emit(AuthInitial());
  }

  Future<void> verificationFilesUpload() async {
    if (verFiles == null || verFiles!.isEmpty) return;
    
    emit(AuthLoading());
    try {
      final s = state;
      final userId = (s is Authenticated) ? s.user.id : supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User ID not found");

      await repository.uploadVerificationFiles(
        files: verFiles!,
        userId: userId,
        driveService: driveService,
        onProgress: (index, progress) {
          if (uploadProgress.length <= index) {
            uploadProgress.add(progress);
          } else {
            uploadProgress[index] = progress;
          }
          emit(AuthInitial());
        },
      );
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> isApartmentTaken({
    required int compoundId,
    required String buildingName,
    required String apartmentNum,
  }) async {
    try {
      final taken = await repository.isApartmentTaken(
        compoundId: compoundId,
        buildingName: buildingName,
        apartmentNum: apartmentNum,
      );
      apartmentConflict = taken;
      emit(ApartmentTakenStatus(isTaken: taken));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> resetUserData() async {
    // Note: ChatMembers and MembersData are now managed via Authenticated state.
    // Resetting involves emitting a clean state if needed, or handled via signOut.
    emit(AuthInitial());
  }

  Future<void> selectCompound({
    required int compoundId,
    required String compoundName,
    required bool atWelcome,
  }) async {
    try {
      selectedCompoundId = compoundId;
      if (atWelcome) {
        myCompounds = {
          '0': "Add New Community",
          compoundId.toString(): compoundName,
        };
      } else {
        myCompounds[compoundId.toString()] = compoundName;
      }

      await repository.selectCompound(
        compoundId: compoundId,
        compoundName: compoundName,
        atWelcome: atWelcome,
      );

      if (state is Authenticated) {
        emit((state as Authenticated).copyWith(
          selectedCompoundId: compoundId,
          myCompounds: Map<String, dynamic>.from(myCompounds),
        ));
      } else {
        emit(CompoundSelected(compoundId));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  int? _coerceToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> _parseMyCompoundsMap(dynamic raw) {
    if (raw == null) return {'0': "Add New Community"};
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    return {'0': "Add New Community"};
  }

  Future<void> _cacheUserSnapshotOnSignOut() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final Map<String, dynamic> compounds = (state is Authenticated)
        ? Map<String, dynamic>.from((state as Authenticated).myCompounds)
        : Map<String, dynamic>.from(myCompounds);

    final int? compoundId = (state is Authenticated)
        ? (state as Authenticated).selectedCompoundId
        : selectedCompoundId;

    final payload = <String, dynamic>{
      'email': user.email ?? '',
      'selectedCompoundId': compoundId,
      'myCompounds': compounds,
    };

    await CacheHelper.saveData(
      key: CacheHelper.cachedUserDataKey(user.id),
      value: jsonEncode(payload),
    );
  }

  Future<void> presetBeforeSignin() async {
    emit(AuthLoading(categories: state.categories, compoundsLogos: state.compoundsLogos));
    try {
      List<Category> currentCategories = state.categories;
      List<String> currentLogos = state.compoundsLogos;

      if (currentCategories.isEmpty) {
        currentCategories = await repository.loadCompounds();
      }
      if (currentLogos.isEmpty) {
        currentLogos = await AssetHelper.loadCompoundLogos();
      }

      final currentUserAuth = supabase.auth.currentUser;
      if (currentUserAuth == null) {
        emit(Unauthenticated(
          categories: currentCategories,
          compoundsLogos: currentLogos,
        ));
        return;
      }
      final String userId = currentUserAuth.id;

      Map<String, dynamic> localMyCompounds = {'0': "Add New Community"};
      int? localSelectedCompoundId;

      // 1) Prefer per-user snapshot from last sign-out
      final String? cachedRaw = await CacheHelper.getData(
        key: CacheHelper.cachedUserDataKey(userId),
        type: "String",
      ) as String?;
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedRaw);
          if (decoded is Map) {
            final m = Map<String, dynamic>.from(decoded);
            localSelectedCompoundId = _coerceToInt(m['selectedCompoundId']);
            final mc = m['myCompounds'];
            if (mc != null) {
              localMyCompounds = _parseMyCompoundsMap(mc);
            }
          }
        } catch (e) {
          debugPrint('presetBeforeSignin: invalid cached user JSON, using fallback ($e)');
        }
      }

      // 2) Fallback: Supabase user_apartments
      if (localSelectedCompoundId == null) {
        final compoundIdResponse = await supabase
            .from('user_apartments')
            .select('compound_id')
            .eq('user_id', userId)
            .maybeSingle();
        if (compoundIdResponse != null) {
          localSelectedCompoundId = _coerceToInt(compoundIdResponse['compound_id']);
        }
      }

      // 3) If only default row(s), resolve compound label from loaded categories
      if (localSelectedCompoundId != null && localMyCompounds.length <= 1) {
        final compound = currentCategories.expand((cat) => cat.compounds).firstWhere(
              (c) => c.id == localSelectedCompoundId,
              orElse: () => throw Exception("Compound not found in categories"),
            );
        localMyCompounds = {
          '0': "Add New Community",
          localSelectedCompoundId.toString(): compound.name.toString(),
        };
        await CacheHelper.saveData(
          key: CacheHelper.cachedUserDataKey(userId),
          value: jsonEncode({
            'email': currentUserAuth.email ?? '',
            'selectedCompoundId': localSelectedCompoundId,
            'myCompounds': localMyCompounds,
          }),
        );
      }

      Roles? userRole;
      if (currentUserAuth != null) {
        final roleId = currentUserAuth.userMetadata?["role_id"];
        if (roleId != null && roleId > 0 && roleId <= Roles.values.length) {
          userRole = Roles.values[roleId - 1];
        }
      }

      List<ChatMember> chatMembers = [];
      List<Users> membersData = [];
      ChatMember? currentUser;

      if (localSelectedCompoundId != null) {
        selectedCompoundId = localSelectedCompoundId;
        myCompounds = localMyCompounds;

        // 4. Load members
        final result = await repository.loadCompoundMembers(localSelectedCompoundId, role: userRole);
        chatMembers = result.members;
        membersData = result.membersData;
        final currentUserId = (state is Authenticated) ? (state as Authenticated).user.id : (supabase.auth.currentUser?.id);
        currentUser = chatMembers.firstWhere(
          (member) => member.id.trim() == currentUserId,
          orElse: () => chatMembers.isNotEmpty ? chatMembers.first : throw Exception("User not found in members"),
        );
      }

      if (state is Authenticated) {
        emit((state as Authenticated).copyWith(
          role: userRole,
          selectedCompoundId: localSelectedCompoundId,
          myCompounds: localMyCompounds,
          chatMembers: chatMembers,
          membersData: membersData,
          currentUser: currentUser,
          enabledMultiCompound: enabledMultiCompound,
          googleUser: googleUser,
          categories: currentCategories,
          compoundsLogos: currentLogos,
        ));
      } else {
        final currentSessionUser = supabase.auth.currentUser;
        if (currentSessionUser != null) {
          emit(Authenticated(
            user: currentSessionUser,
            role: userRole,
            selectedCompoundId: localSelectedCompoundId,
            myCompounds: localMyCompounds,
            chatMembers: chatMembers,
            membersData: membersData,
            currentUser: currentUser,
            enabledMultiCompound: enabledMultiCompound,
            googleUser: googleUser,
            categories: currentCategories,
            compoundsLogos: currentLogos,
          ));
        } else {
          emit(Unauthenticated(
            categories: currentCategories,
            compoundsLogos: currentLogos,
          ));
        }
      }
    } catch (e) {
      debugPrint("Error in presetBeforeSignin: $e");
      emit(AuthError(e.toString(), categories: state.categories, compoundsLogos: state.compoundsLogos));
    }
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final user = await repository.signInWithPassword(email: email, password: password);
      if (user != null) {
        emit(Authenticated(user: user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  }) async {
    emit(AuthLoading());
    try {
      await repository.signUp(email: email, password: password, data: data);
      emit(SignUpSuccess(email: email));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signInWithGoogle({bool isSignin = false}) async {
    emit(AuthLoading());
    try {
      signInGoogle = true;
      final user = await repository.signInWithGoogle();
      if (user != null) {
        if (isSignin) {
          emit(Authenticated(user: user));
        } else {
          signupGoogleEmail = user.email;
          signupGoogleUserName = user.userMetadata?['full_name'] ?? user.userMetadata?['name'];
          emit(GoogleSignupState());
        }
      } else {
        signInGoogle = false;
        emit(Unauthenticated());
      }
    } catch (e) {
      signInGoogle = false;
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading(categories: state.categories, compoundsLogos: state.compoundsLogos));
    try {
      await _cacheUserSnapshotOnSignOut();
      await repository.signOut();
      emit(Unauthenticated(
        categories: state.categories,
        compoundsLogos: state.compoundsLogos,
      ));
    } catch (e) {
      emit(AuthError(e.toString(), categories: state.categories, compoundsLogos: state.compoundsLogos));
    }
  }

  Future<void> completeRegistration({
    required String fullName,
    required String userName,
    required OwnerTypes ownerType,
    required String phoneNumber,
    required int roleId,
    required String buildingName,
    required String apartmentNum,
    required int compoundId,
  }) async {
    emit(AuthLoading());
    try {
      await repository.completeRegistration(
        fullName: fullName,
        userName: userName,
        ownerType: ownerType,
        phoneNumber: phoneNumber,
        roleId: roleId,
        buildingName: buildingName,
        apartmentNum: apartmentNum,
        compoundId: compoundId,
      );
      
      roleName = Roles.values[roleId - 1];
      selectedCompoundId = compoundId;
      emit(RegistrationSuccess());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String displayName,
    required OwnerTypes ownerType,
    required String phoneNumber,
  }) async {
    emit(AuthLoading());
    try {
      await repository.updateProfile(
        fullName: fullName,
        displayName: displayName,
        ownerType: ownerType,
        phoneNumber: phoneNumber,
      );
      emit(ProfileUpdated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> requestEmailChange(String newEmail, {String? redirectUrl}) async {
    emit(AuthLoading());
    try {
      await repository.requestEmailChange(newEmail, redirectUrl: redirectUrl);
      emit(EmailChangeRequested());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> updatePassword(String newPassword) async {
    emit(AuthLoading());
    try {
      await repository.updatePassword(newPassword);
      emit(PasswordUpdated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void getSuggestions(TextEditingController controller) {
    if (controller.text.isEmpty) {
      compoundSuggestions = [];
    } else {
      compoundSuggestions = state.categories.where((category) {
        return category.name
            .toLowerCase()
            .contains(controller.text.toLowerCase());
      }).toList();
    }
    if (state is Authenticated) {
      emit((state as Authenticated).copyWith());
    } else {
      emit(AuthInitial(categories: state.categories, compoundsLogos: state.compoundsLogos));
    }
  }

  Future<void> loadCompounds() async {
    emit(AuthLoading(categories: state.categories, compoundsLogos: state.compoundsLogos));
    try {
      final fetchedCategories = await repository.loadCompounds();
      final fetchedLogos = await AssetHelper.loadCompoundLogos();
      
      if (state is Authenticated) {
        emit((state as Authenticated).copyWith(
          categories: fetchedCategories,
          compoundsLogos: fetchedLogos,
        ));
      } else {
        emit(AuthInitial(
          categories: fetchedCategories,
          compoundsLogos: fetchedLogos,
        ));
      }
    } catch (e) {
      emit(AuthError(e.toString(), categories: state.categories, compoundsLogos: state.compoundsLogos));
    }
  }

  Future<void> loadCompoundMembers(int compoundId) async {
    emit(AuthLoading());
    try {
      final Roles? currentRole = (state is Authenticated) ? (state as Authenticated).role : null;
      final result = await repository.loadCompoundMembers(compoundId, role: currentRole);
      final members = result.members;
      final membersData = result.membersData;
      
      final currentUserId = (state is Authenticated) ? (state as Authenticated).user.id : (supabase.auth.currentUser?.id);
      final currentMember = members.firstWhere(
        (member) => member.id.trim() == currentUserId,
        orElse: () => members.isNotEmpty ? members.first : throw Exception("User not found in members"),
      );
      
      if (state is Authenticated) {
        emit((state as Authenticated).copyWith(
          chatMembers: members,
          membersData: membersData,
          currentUser: currentMember,
        ));
      } else {
        emit(CompoundMembersUpdated(
          compoundId: compoundId,
          chatMembers: members,
          membersData: membersData,
          currentUser: currentMember,
        ));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void updateChatMembers(List<ChatMember> updatedMembers) {
    if (state is Authenticated) {
      final s = state as Authenticated;
      
      ChatMember? current = s.currentUser;
      final currentUserId = s.user.id;
      final newCurrent = updatedMembers.firstWhere(
        (m) => m.id == currentUserId,
        orElse: () => current ?? updatedMembers.first,
      );

      emit(s.copyWith(chatMembers: updatedMembers, currentUser: newCurrent));
    }
  }
}
