import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_app/Layout/Cubit/ChatDetailsCubit/cubit.dart';
import 'package:super_app/Layout/Cubit/ChatDetailsCubit/states.dart';
import 'package:super_app/Layout/chatWidget/Details/OverviewScreen.dart';

import 'ChatMember.dart';
import 'User_details.dart';

class ChatDetails extends StatelessWidget {
  final int compoundId;
  const ChatDetails({super.key, required this.compoundId});

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      OverviewScreen(),
      ChatMembersScreen(
        compoundId: compoundId,
      ),

    ];
    return BlocBuilder<ChatDetailsCubit,ChatDetailsStates>(
      builder: (context,states) {
        return Scaffold(
          appBar: AppBar(),
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: ChatDetailsCubit.get(context).selectedIndex,
                onDestinationSelected: (int index){
                  ChatDetailsCubit.get(context).indexChange(index);
                },
                destinations: const <NavigationRailDestination>[
                  NavigationRailDestination(
                      icon: Icon(Icons.info_outline_rounded), label: Text("Overview")
                  ),
                  NavigationRailDestination(
                      icon: Icon(Icons.group_outlined), label: Text("Members")
                  ),
                ],
              ),
              Expanded(
                child: ChatDetailsCubit.get(context).selectedMemberId !=null? UserDetails(userID: ChatDetailsCubit.get(context).selectedMemberId!):screens[ChatDetailsCubit.get(context).selectedIndex],
                ),

            ],
          ),
        );
      }
    );
  }
}
