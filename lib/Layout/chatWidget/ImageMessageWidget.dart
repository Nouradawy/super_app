import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Components/Constants.dart';
import '../../Confg/supabase.dart';
import '../../sevices/GoogleDriveService.dart';
import '../GeneralChat.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';

class ImageMessageWidget extends StatelessWidget {
  const ImageMessageWidget({
    super.key,
    required this.message,
    required this.controller,
    required this.messageIndex,
    required this.chatController,
    required this. userName,
    required this. fileId,

  });

  final ImageMessage message;
  final ReactionsController controller;
  final int messageIndex;
  final InMemoryChatController chatController;
  final Username userName;
  final String fileId;


  @override
  Widget build(BuildContext context) {
    final bool isMe = message.authorId == supabase.auth.currentUser!.id?true:false;
    // 1. Extract the file ID from the message's URI

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
            messageBuilder(
              context,
              isMe
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
      bottom: 8,
      right: 20,
      child: StackedReactions(
        messageId: message.id,
        controller: controller,
        maxReactionsToShow: 3,
        size: 18,


      ),
    )
        : Positioned(
      bottom: 2,
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
      context ,isMe
      ){

    final hasReactions = controller.getReactionCounts(message.id).isNotEmpty;
    // padding for the message card
    final padding = hasReactions
        ? isMe
        ? const EdgeInsets.only(left: 30.0, bottom: 25.0)
        : const EdgeInsets.only(right: 30.0, bottom: 25.0)
        : const EdgeInsets.only(bottom: 5.0);

    final BackgroundColor = isMe
        ? Colors.indigo
        : Colors.purple;
    final textColor =  isMe
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSecondary;

    final List<Widget> UserInformation =[
      Container(
          padding: EdgeInsets.symmetric(horizontal: 3,vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(120),
            borderRadius: BorderRadius.circular(5),
          ),
          child:userName),
      Container(
          padding: EdgeInsets.symmetric(horizontal: 3,vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(120),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text("Building:34 , Appartment:20 ",style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600 ,fontSize: 9 ,color: Colors.white),)),
    ];

    final List<Widget> chatObjects=[
      ChatBubble(
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
          Row(
            spacing: 15,
            mainAxisSize: MainAxisSize.max,
            children: isMe?UserInformation.reversed.toList():UserInformation,
          ),

          DriveImageMessage(
          fileId: fileId,
          driveService: driveService, // Pass your drive service instance
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: isMe?MainAxisAlignment.end:MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
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
      Avatar(userId: message.authorId)
    ];
    return Material(
      color:Colors.transparent,
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: isMe?chatObjects:chatObjects.reversed.toList()
        ),
      ),
    );
  }

}





class DriveImageMessage extends StatefulWidget {
  final String fileId;
  final GoogleDriveService driveService;

  const DriveImageMessage({
    super.key,
    required this.fileId,
    required this.driveService,
  });

  @override
  State<DriveImageMessage> createState() => _DriveImageMessageState();
}

class _DriveImageMessageState extends State<DriveImageMessage> {
  // This Future will be created only once.
  late final Future<Uint8List?> _downloadFuture;

  @override
  void initState() {
    super.initState();
    // Call the download method here in initState, so it only runs once.
    _downloadFuture = widget.driveService.downloadFile(widget.fileId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250, maxHeight: 250),
      // Use the Future that was created in initState.
      child: FutureBuilder<Uint8List?>(
        future: _downloadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Icon(Icons.error, color: Colors.red));
          }
          return GestureDetector(
            onTap:(){

              FullScreenImageViewer( snapshot.data! , context);


            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                snapshot.data ?? Uint8List(0),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}