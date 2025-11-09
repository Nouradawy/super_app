import 'package:flutter/material.dart';
import 'package:super_app/Layout/chatWidget/Details/ChatMember.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../Confg/supabase.dart';

class UserDetails extends StatelessWidget {
  final String userID;
  const UserDetails({super.key, required this.userID});

  @override
  Widget build(BuildContext context) {
    final ChatMember member = ChatMembers.firstWhere(
          (m) => m.id == userID,
      orElse: () => ChatMember(
        id: userID,
        name: 'Unknown',
        avatarUrl: null,
        building: '',
        apartment: '',
      ),
    );
    return Column(
      children: [
        CircleAvatar(
          // Display user avatar or a default icon
          backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
          radius: 40,
          child: member.avatarUrl == null ? Icon(Icons.person , size: 60,) : null,
        ),
        Text(member.name),
        Text("+20108200849"),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
          Container(
            alignment: Alignment.center,
            height: 55,
            width: MediaQuery.sizeOf(context).width*0.20,
            decoration: BoxDecoration(
              color: Colors.blue.shade200,
              borderRadius: BorderRadius.circular(10),

            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(FontAwesomeIcons.whatsapp),
                Text("Whatsapp")
              ],
            ),
          ),

          Container(
            height: 55,
            width: MediaQuery.sizeOf(context).width*0.20,
            decoration: BoxDecoration(
                color: Colors.blue.shade200,
                borderRadius: BorderRadius.circular(10)
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 7,),
                FaIcon(FontAwesomeIcons.exclamation),
                Text("Report")
              ],
            ),
          ),
        ],),
        Text("Last Seen today at 12:52 AM")
      ],
    );
  }
}
