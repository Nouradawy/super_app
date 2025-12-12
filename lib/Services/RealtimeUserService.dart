import 'dart:async';

import 'package:WhatsUnity/Layout/Cubit/ChatDetailsCubit/cubit.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Confg/supabase.dart';
import '../Confg/Enums.dart';
import '../Components/Constants.dart';
import '../Layout/Cubit/cubit.dart';
import '../Layout/Cubit/ManagerCubit/cubit.dart';
import '../Layout/chatWidget/Details/ChatMember.dart';

class RealtimeUserService {
  RealtimeUserService._();
  static final RealtimeUserService instance = RealtimeUserService._();

  RealtimeChannel? _profileChannel;
  RealtimeChannel? _rolesChannel;

  void init(BuildContext context) {
    final client = supabase; // your global client
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final userId = user.id;

    // \[1] Listen on profiles table for this user
    _profileChannel ??= client.channel('public:profiles:$userId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'profiles',
        filter: PostgresChangeFilter(column: 'id', type:PostgresChangeFilterType.eq, value:userId),
        callback: (payload) {
          _handleProfileUpdate(context, payload);
        },
      )
      ..subscribe();

    // \[2] Listen on user_roles (or equivalent) for this user
    _rolesChannel ??= client.channel('public:user_roles:$userId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'user_roles',
        filter: PostgresChangeFilter(column: 'user_id', type:PostgresChangeFilterType.eq, value:userId),
        callback: (payload) {
          _handleRoleUpdate(context, payload);
        },
      )
      ..subscribe();
  }

  void dispose() {
    _profileChannel?.unsubscribe();
    _rolesChannel?.unsubscribe();
    _profileChannel = null;
    _rolesChannel = null;
  }

  // \[A] Handle profile row change
  void _handleProfileUpdate(BuildContext context, PostgresChangePayload payload) {
    if (!context.mounted) return;
    final newRecord = payload.newRecord;

    if (currentUser == null) return;

    final appCubit = AppCubit.get(context);
    // 1) Find existing member by user id (adjust to your storage)
    final String userId = newRecord['id']?.toString() ?? '';
    debugPrint(newRecord['userState']);
    final ChatMember existing = ChatMembers.firstWhere((m) => m.id == userId);
    final updatedMember = ChatMember.fromJson(newRecord);
    ChatMember member;

    member = existing.copyWithProfileUpdate(newRecord);
    currentUser = member;
    final index = ChatMembers.indexWhere((m) => m.id == updatedMember.id);
    if (index != -1) {
      ChatMembers[index] = updatedMember;
    }
    appCubit.onProfileUpdated(member);
    ChatDetailsCubit.get(context).onProfileUpdated(member);
  }

  // \[B] Handle role change row
  void _handleRoleUpdate(BuildContext context, PostgresChangePayload payload) {
    if (!context.mounted) return;
    final newRecord = payload.newRecord;

    final int? newRoleId = newRecord['role_id'] as int?;
    if (newRoleId == null) return;

    // Update global role
    if (newRoleId > 0 && newRoleId <= Roles.values.length) {
      userRole = Roles.values[newRoleId - 1];

    }
    debugPrint("current userRole on update :${userRole?.name} ");
    final appCubit = AppCubit.get(context);

    // If you want to reset bottom nav index or screens, do it through AppCubit
    appCubit.onUserRoleChanged(userRole!);
  }
}