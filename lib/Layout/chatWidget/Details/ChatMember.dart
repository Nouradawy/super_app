import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:WhatsUnity/Layout/Cubit/ChatDetailsCubit/cubit.dart';


import '../../../Confg/Enums.dart';
import '../../../Confg/supabase.dart';
import '../../Cubit/cubit.dart';
import 'User_details.dart';

// A simple data class to hold user information
class ChatMember {
  final String id;
  final String displayName;
  final String? fullName;
  final String? avatarUrl;
  final String building;
  final String apartment;
  final UserState? userState;
  final String phoneNumber;
  final OwnerTypes? ownerType;



  ChatMember({
    required this.id,
    required this.displayName,
    this.fullName,
    this.avatarUrl,
    required this.building,
    required this.apartment,
    required this.userState,
    required this.phoneNumber,
    required this.ownerType,
  });
  @override
  String toString() {
    return 'ChatMember(id: $id, name: $displayName, building: $building, apartment: $apartment)';
  }
}

class ChatMembersScreen extends StatefulWidget {
  final int compoundId;
  const ChatMembersScreen({super.key, required this.compoundId});

  @override
  State<ChatMembersScreen> createState() => _ChatMembersScreenState();
}

class _ChatMembersScreenState extends State<ChatMembersScreen> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeScreen() async {

    setState(() {
      _isLoading = false;
    });
  }

  // Fetches the static list of all users in the compound


  // String _getUserStatus(Map<String, dynamic> presence, String userId) {
  //   for (final entry in presence.entries) {
  //     final presences = entry.value as List;
  //     for (final p in presences) {
  //       if (p['user_id'] == userId) {
  //         return p['status'] ?? 'offline';
  //       }
  //     }
  //   }
  //   return 'offline';
  // }

  Map<String, String> _getStatusesFromPresence(Map<String, dynamic> presence) {
    final statuses = <String, String>{};
    for (final presences in presence.values) {
      for (final p in (presences as List)) {
        final userId = p['user_id'];
        final status = p['status'] ?? 'offline';
        if (userId != null) {
          statuses[userId] = status;
        }
      }
    }
    return statuses;
  }

  @override
  Widget build(BuildContext context) {
    // final appCubit = context.watch<AppCubit>();
    // final presence = appCubit.currentPresence;
    final presence = context.watch<AppCubit>().currentPresence;
    final statusMap = _getStatusesFromPresence(presence);

    return Scaffold(
      appBar: AppBar(),
      body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
    itemCount: ChatMembers.length,
    itemBuilder: (context, index) {
    final member = ChatMembers[index];
    final status = statusMap[member.id] ?? 'offline';

    return ListTile(
    leading: CircleAvatar(
    // Display user avatar or a default icon
    backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
    child: member.avatarUrl == null ? Icon(Icons.person) : null,
    ),
    onTap: ()=>ChatDetailsCubit.get(context).selectMember(member.id),

    title: Text(member.displayName),
    trailing: StatusIndicator(status: status),
    );
    }),
    );
  }
}

// A helper widget to display the status visually
class StatusIndicator extends StatelessWidget {
  final String status;
  const StatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    switch (status) {
      case 'available':
        statusColor = Colors.green;
        statusText = 'Available';
        break;
      case 'online':
        statusColor = Colors.blue;
        statusText = 'Online';
        break;
      default: // 'offline'
        statusColor = Colors.grey;
        statusText = 'Offline';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(statusText),
      ],
    );
  }
}