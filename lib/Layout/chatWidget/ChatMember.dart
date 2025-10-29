import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Cubit/cubit.dart';

// A simple data class to hold user information
class ChatMember {
  final String id;
  final String name;
  final String? avatarUrl;

  ChatMember({required this.id, required this.name, this.avatarUrl});
}

class ChatMembersScreen extends StatefulWidget {
  final int compoundId;
  const ChatMembersScreen({super.key, required this.compoundId});

  @override
  State<ChatMembersScreen> createState() => _ChatMembersScreenState();
}

class _ChatMembersScreenState extends State<ChatMembersScreen> {
  final supabase = Supabase.instance.client;
  RealtimeChannel? _presenceChannel;
  List<ChatMember> _members = [];
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
    await _fetchCompoundMembers();

    setState(() {
      _isLoading = false;
    });
  }

  // Fetches the static list of all users in the compound
  Future<void> _fetchCompoundMembers() async {
    try {
      // 1. Get all user_id's for the current compound from the 'user_apartments' table.
      final userApartmentsResponse = await supabase
          .from('user_apartments')
          .select('user_id')
          .eq('compound_id', widget.compoundId);

      if (userApartmentsResponse.isEmpty) {
        setState(() => _members = []);
        return;
      }

      // 2. Extract the list of user IDs.
      final userIds = userApartmentsResponse
          .map((row) => row['user_id'] as String)
          .toList();
      final orFilter = userIds.map((id) => 'id.eq.$id').join(',');
      // 3. Fetch all profiles that match the user IDs using an '.in()' filter.
      final profilesResponse = await supabase
          .from('profiles')
          .select('id, display_name, avatar_url')
          .or(orFilter);

      final membersList = (profilesResponse as List)
          .map((data) => ChatMember(
        id: data['id'],
        name: data['display_name'] ?? 'No Name',
        avatarUrl: data['avatar_url'],
      ))
          .toList();

      setState(() {
        _members = membersList;
      });
    } catch (error) {
      debugPrint('Error fetching members: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading members: $error'), backgroundColor: Colors.red),
        );
      }
    }
  }

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
      appBar: AppBar(
        title: Text('Chat Members'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          final status = statusMap[member.id] ?? 'offline';

          return ListTile(
            leading: CircleAvatar(
              // Display user avatar or a default icon
              backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
              child: member.avatarUrl == null ? Icon(Icons.person) : null,
            ),

            title: Text(member.name),
            trailing: StatusIndicator(status: status),
          );
        },
      ),
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