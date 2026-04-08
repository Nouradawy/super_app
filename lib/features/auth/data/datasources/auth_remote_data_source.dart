import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/Enums.dart';
import '../../../../core/config/supabase.dart';
import '../../../../core/services/GoogleDriveService.dart';

abstract class AuthRemoteDataSource {
  Future<User?> signInWithGoogle({required String idToken, String? accessToken});
  Future<User?> signInWithPassword({required String email, required String password});
  Future<void> signUp({required String email, required String password, required Map<String, dynamic> data});
  Future<void> signOut();
  Future<void> updateProfile({
    required String userId,
    required String fullName,
    required String displayName,
    required String ownerType,
    required String phoneNumber,
  });
  Future<void> updateUserRole(String userId, int roleId);
  Future<void> requestEmailChange(String newEmail, {String? redirectUrl});
  Future<void> updatePassword(String newPassword);
  Future<bool> isApartmentTaken({
    required int compoundId,
    required String buildingName,
    required String apartmentNum,
  });
  Future<void> uploadVerificationFiles({
    required List<XFile> files,
    required String userId,
    required GoogleDriveService driveService,
    required void Function(int index, double progress) onProgress,
  });
}

class SupabaseAuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  SupabaseAuthRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<User?> signInWithGoogle({required String idToken, String? accessToken}) async {
    final response = await supabaseClient.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
    return response.user;
  }

  @override
  Future<User?> signInWithPassword({required String email, required String password}) async {
    final response = await supabaseClient.auth.signInWithPassword(email: email, password: password);
    return response.user;
  }

  @override
  Future<void> signUp({required String email, required String password, required Map<String, dynamic> data}) async {
    await supabaseClient.auth.signUp(email: email, password: password, data: data);
  }

  @override
  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }

  @override
  Future<void> updateProfile({
    required String userId,
    required String fullName,
    required String displayName,
    required String ownerType,
    required String phoneNumber,
  }) async {
    await supabaseClient.from('profiles').update({
      'full_name': fullName,
      'display_name': displayName,
      'owner_type': ownerType,
      'phone_number': phoneNumber,
    }).eq('id', userId);
  }

  @override
  Future<void> updateUserRole(String userId, int roleId) async {
    await supabaseClient.from('user_roles').update({'role_id': roleId}).eq('user_id', userId);
  }

  @override
  Future<void> requestEmailChange(String newEmail, {String? redirectUrl}) async {
    await supabaseClient.auth.updateUser(
      UserAttributes(email: newEmail),
      emailRedirectTo: redirectUrl,
    );
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await supabaseClient.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  @override
  Future<void> uploadVerificationFiles({
    required List<XFile> files,
    required String userId,
    required GoogleDriveService driveService,
    required void Function(int index, double progress) onProgress,
  }) async {
    for (int i = 0; i < files.length; i++) {
      final xfile = files[i];
      final file = File(xfile.path);
      final fileName = xfile.name;
      final objectKey = 'users/$userId/verifications/$fileName';

      if (storageType == Storage.googleDrive || storageType == Storage.both) {
        await driveService.uploadFile(file, fileName, 'image');
      }
      
      if (storageType == Storage.superbaseStorage || storageType == Storage.both) {
        final storage = supabaseClient.storage.from("verification");
        await storage.upload(
          objectKey,
          file,
          fileOptions: FileOptions(
            contentType: lookupMimeType(xfile.path) ?? 'application/octet-stream',
            upsert: true,
          ),
        );
      }
      onProgress(i, 1.0);
    }
  }

  @override
  Future<bool> isApartmentTaken({
    required int compoundId,
    required String buildingName,
    required String apartmentNum,
  }) async {
    final response = await supabaseClient
        .from('user_apartments')
        .select('user_id')
        .eq('compound_id', compoundId)
        .eq('building_num', buildingName)
        .eq('apartment_num', apartmentNum)
        .maybeSingle();

    return response != null;
  }
}
