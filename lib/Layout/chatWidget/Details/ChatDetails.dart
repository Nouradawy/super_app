import 'package:WhatsUnity/Components/Constants.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:WhatsUnity/Layout/Cubit/ChatDetailsCubit/cubit.dart';
import 'package:WhatsUnity/Layout/Cubit/ChatDetailsCubit/states.dart';
import 'package:WhatsUnity/Layout/Cubit/ReportCubit/cubit.dart';
import 'package:WhatsUnity/Themes/lightTheme.dart';

import '../../../Confg/supabase.dart';
import 'ChatMember.dart';
import 'Reports.dart';

class ChatDetails extends StatelessWidget {
  final int compoundId;
  const ChatDetails({super.key, required this.compoundId});


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatDetailsCubit,ChatDetailsStates>(
      builder: (context,states) {
        return Scaffold(
          appBar: AppBar(),
          body:Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white70,
                  shape: BoxShape.circle
                ),
                  child:ClipOval(child: getCompoundPicture(compoundId,160))
              )
              ) ,
              SizedBox(height: 10),
              Text("GENERAL CHAT"),
              SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Group . "),
                  Text.rich(
                    TextSpan(
                      text: '${ChatMembers.length.toString()} members',
                      style: context.txt.signSubtitle.copyWith(color: Colors.blue),
                      recognizer:
                      TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                 builder: (BuildContext context) =>
                                     ChatMembersScreen(
                                   compoundId: compoundId,
                                 ),
                              ));
                        },
                    ),
                  )
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 10,
                children: [
                  MaterialButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.0),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    onPressed: (){} ,
                    child: Text("Mute Notifications"),
                  ),
                  MaterialButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.0),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    onPressed: (){} ,
                    child: Text("Add new suggestion"),
                  )
                ],
              ),
              SizedBox(height: 10),
              Text("Description"),
              SizedBox(height: 10),
              Text("Notes"),
              SizedBox(height: 15),
              MaterialButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onPressed: (){
                  ReportCubit.get(context).getReportList();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => Reports(),
                      ));
                } ,
                child: Text("Reports"),
              ),

            ],
          ),
        );
      }
    );
  }
}
