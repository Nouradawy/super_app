import '../../../../core/models/CompoundsList.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/Enums.dart';
import '../../../../core/services/GoogleDriveService.dart';
import '../../../../core/config/supabase.dart';

abstract class AuthRepository {
  Future<User?> signInWithGoogle();
  Future<User?> signInWithPassword({required String email, required String password});
  Future<void> signUp({required String email, required String password, required Map<String, dynamic> data});
  Future<void> signOut();
  Future<void> updateProfile({
    required String fullName,
    required String displayName,
    required OwnerTypes ownerType,
    required String phoneNumber,
  });
  Future<void> completeRegistration({
    required String fullName,
    required String userName,
    required OwnerTypes ownerType,
    required String phoneNumber,
    required int roleId,
    required String buildingName,
    required String apartmentNum,
    required int compoundId,
  });
  Future<void> uploadVerificationFiles({
    required List<XFile> files,
    required String userId,
    required GoogleDriveService driveService,
    required void Function(int index, double progress) onProgress,
  });
  Future<bool> isApartmentTaken({
    required int compoundId,
    required String buildingName,
    required String apartmentNum,
  });
  Future<void> selectCompound({required int compoundId, required String compoundName, required bool atWelcome});
  Future<void> requestEmailChange(String newEmail, {String? redirectUrl});
  Future<void> updatePassword(String newPassword);
  
  Future<List<Category>> loadCompounds();
  Future<CompoundMembersResult> loadCompoundMembers(int compoundId, {Roles? role});

  Stream<AuthState> get onAuthStateChange;
  User? get currentUser;
}
