import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Components/Constants.dart';
import '../../Confg/supabase.dart';
import '../GeneralChat.dart';
import 'package:intl/intl.dart';

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    super.key,
    required this.message,
    required this.controller,
    required this.messageIndex,
    required this.chatController,
    required this. userName,

  });

  final TextMessage message;
  final ReactionsController controller;
  final int messageIndex;
  final InMemoryChatController chatController;
  final String? userName;


  @override
  Widget build(BuildContext context) {
    final bool isMe = message.authorId == supabase.auth.currentUser!.id?true:false;
    final hasReactions = controller.getReactionCounts(message.id).isNotEmpty;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          minWidth: MediaQuery.of(context).size.width * 0.0,
        ),
        child: Stack(
          children: [
            // message
            Padding(
              padding: EdgeInsets.only(bottom: hasReactions ? 12.0 : 0),
              child: messageBuilder(
                context,
                isMe,
                  hasReactions
              ),
            ),

            //reactions
            buildReactions(
              context,
              isMe,
            ),
          ],
        ),
      ),
    );
  }

  // reactions widget
  Widget buildReactions(BuildContext context, bool isMe) {
    return isMe
        ? Positioned(
      bottom: 0,
      right: 20,
      child: StackedReactions(
        messageId: message.id,
        controller: controller,
        maxReactionsToShow: 3,
        size: 18,


      ),
    )
        : Positioned(
      bottom: 0,
      left: 8,
      child: StackedReactions(
        messageId: message.id,
        controller: controller,
        maxReactionsToShow: 3,
      ),
    );
  }

bool isPrevPost(){
    if(messageIndex>0 && chatController.messages[messageIndex-1].authorId == message.authorId ){
      return true;
    }
    return false;
}

  Widget messageBuilder(
      context ,isMe , hasReactions
      ){


    // padding for the message card
    final padding = const EdgeInsets.only(bottom: 2.0);

    final BackgroundColor = isMe
        ? Colors.indigo
        : Colors.purple;
    final textColor =  isMe
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSecondary;

    final List<Widget> UserInformation =[
       userName !=null ?Container(
          padding: EdgeInsets.symmetric(horizontal: 3,vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(120),
            borderRadius: BorderRadius.circular(5),
          ),
          child:Text(userName! ,style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600 ,fontSize: 10 ,color: Colors.greenAccent),)):SizedBox.shrink(),
      Container(
          padding: EdgeInsets.symmetric(horizontal: 3,vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(120),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text("Building:34 , Appartment:20 ",style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600 ,fontSize: 9 ,color: Colors.white),)),
    ];


    return Material(
      color:Colors.transparent,
      child: Padding(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // prevents full-width stretch
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: ChatBubble(
            padding: EdgeInsets.symmetric(horizontal: 15,vertical: 2),
            clipper: isMe
                ? isPrevPost()? ChatBubbleClipper5(type:BubbleType.sendBubble,radius: 10):ChatBubbleClipper1(
                type:BubbleType.sendBubble,
                radius: 10,
                nipRadius: 0,
                nipHeight: 14,
                nipWidth: 5
            )
                :ChatBubbleClipper1(
                type:BubbleType.receiverBubble,
                radius: 10,
                nipRadius: 0,
                nipHeight: 14,
                nipWidth: 5
            ),
            alignment: isMe
                ?Alignment.topRight
                :Alignment.topLeft,
            backGroundColor: BackgroundColor,
            child:Column(
              crossAxisAlignment: isMe?CrossAxisAlignment.end:CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,

              children: [
                // SizedBox(height: 2,),
                Row(
                  spacing: 15,
                  mainAxisSize: MainAxisSize.min,
                  children: isMe?UserInformation.reversed.toList():UserInformation,
                ),
                SizedBox(height: 3,),
                Flexible(
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: textColor,
                    ),
                  ),
                ),
          
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: isMe?MainAxisAlignment.end:MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      //TODO:: Change Time sent logic for Messages Widget
                      message.createdAt !=null ?formatTimestampToAmPm(message.createdAt.toString()):"null",
                      style: TextStyle(
                        fontSize: 10,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    message.seenAt !=null ?Icon(
                      Icons.done_all,
                      color: Colors.greenAccent,
                      size: 13,
                    ):Icon(
                      Icons.done_all,
                      color: Colors.grey,
                      size: 13,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
