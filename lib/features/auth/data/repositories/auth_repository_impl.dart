import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../../core/services/GoogleDriveService.dart';
import '../../../../core/models/CompoundsList.dart';
import '../../../../core/config/supabase.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/Enums.dart';
import '../../../../core/constants/Constants.dart';

import '../../../../core/network/CacheHelper.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';


class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SupabaseClient supabaseClient;
  final GoogleDriveService googleDriveService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.supabaseClient,
    required this.googleDriveService,
  });

  @override
  Future<User?> signInWithGoogle() async {
    final user = await googleDriveService.signIn();
    if (user == null) return null;

    final auth = await user.authentication;
    final idToken = auth.idToken;
    final accessToken = auth.accessToken;

    if (idToken == null) {
      throw Exception('Could not get ID token from Google.');
    }

    return await remoteDataSource.signInWithGoogle(
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  @override
  Future<User?> signInWithPassword({required String email, required String password}) async {
    return await remoteDataSource.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUp({required String email, required String password, required Map<String, dynamic> data}) async {
    await remoteDataSource.signUp(email: email, password: password, data: data);
  }

  @override
  Future<void> signOut() async {
    await remoteDataSource.signOut();

  }

  @override
  Future<void> updateProfile({
    required String fullName,
    required String displayName,
    required OwnerTypes ownerType,
    required String phoneNumber,
  }) async {
    final user = supabaseClient.auth.currentUser;
    if (user != null) {
      await remoteDataSource.updateProfile(
        userId: user.id,
        fullName: fullName,
        displayName: displayName,
        ownerType: ownerType.name,
        phoneNumber: phoneNumber,
      );
    }
  }

  @override
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
    final user = supabaseClient.auth.currentUser;
    if (user == null) return;

    // 1. Update Profile
    await remoteDataSource.updateProfile(
      userId: user.id,
      fullName: fullName,
      displayName: userName,
      ownerType: ownerType.name,
      phoneNumber: phoneNumber,
    );

    // 2. Update Role if not default
    if (roleId != 1) {
      await remoteDataSource.updateUserRole(user.id, roleId);
    }

    // 3. Handle Building
    final buildingRow = await supabaseClient.from('buildings').upsert({
      'building_name': buildingName,
      'compound_id': compoundId,
    }, onConflict: 'compound_id , building_name').select('id').maybeSingle();

    if (buildingRow != null) {
      final int buildingId = buildingRow['id'] as int;
      
      // 4. Handle Channel
      await supabaseClient.from('channels').upsert({
        'name': 'Building $buildingName Chat',
        'type': 'BUILDING_CHAT',
        'compound_id': compoundId,
        'building_id': buildingId,
      }, onConflict: 'compound_id , building_id , type');

      // 5. Handle Apartment
      await supabaseClient.from('user_apartments').insert({
        'user_id': user.id,
        'compound_id': compoundId,
        'building_num': buildingName,
        'apartment_num': apartmentNum
      });
    }
  }

  @override
  Future<void> uploadVerificationFiles({
    required List<XFile> files,
    required String userId,
    required GoogleDriveService driveService,
    required void Function(int index, double progress) onProgress,
  }) async {
    await remoteDataSource.uploadVerificationFiles(
      files: files,
      userId: userId,
      driveService: googleDriveService,
      onProgress: onProgress,
    );
  }

  @override
  Future<bool> isApartmentTaken({
    required int compoundId,
    required String buildingName,
    required String apartmentNum,
  }) async {
    return await remoteDataSource.isApartmentTaken(
      compoundId: compoundId,
      buildingName: buildingName,
      apartmentNum: apartmentNum,
    );
  }

  @override
  Future<void> selectCompound({required int compoundId, required String compoundName, required bool atWelcome}) async {
    await CacheHelper.saveData(key: "compoundCurrentIndex", value: compoundId);

    if (atWelcome) {
      final myCompounds = {
        '0': "Add New Community",
        compoundId.toString(): compoundName,
      };
      await CacheHelper.saveData(key: "MyCompounds", value: json.encode(myCompounds));
    }
  }

  @override
  Future<void> requestEmailChange(String newEmail, {String? redirectUrl}) async {
    await remoteDataSource.requestEmailChange(newEmail, redirectUrl: redirectUrl);
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await remoteDataSource.updatePassword(newPassword);
  }

  @override
  Future<List<Category>> loadCompounds() async {
    final args = SupabaseArgs(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    return await compute(fetchCompounds, args);
  }

  @override
  Future<CompoundMembersResult> loadCompoundMembers(int compoundId, {Roles? role}) async {
    final args = {
      'url': dotenv.env['SUPABASE_URL']!,
      'anonKey': dotenv.env['SUPABASE_ANON_KEY']!,
      'CompoundIndex': compoundId,
      'role': role?.name,
    };
    return await compute(fetchCompoundMembers, args);
  }

  @override
  Stream<AuthState> get onAuthStateChange => supabaseClient.auth.onAuthStateChange;

  @override
  User? get currentUser => supabaseClient.auth.currentUser;
}
