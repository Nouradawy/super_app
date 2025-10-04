import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
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

import 'AudioWaveformPainter.dart';

class AudioMessageWidget extends StatelessWidget {
  const AudioMessageWidget({
    super.key,
    required this.message,
    required this.controller,
    required this.messageIndex,
    required this.chatController,
    required this.userName,


  });

  final AudioMessage message;
  final ReactionsController controller;
  final int messageIndex;
  final InMemoryChatController chatController;
  final Username userName;




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

    // 1. Safely get the raw list from metadata. If it's null, use an empty list.
    final List<dynamic> rawAmplitudes = message.metadata?['waveform'] ?? [];

    // 2. Safely convert each element of the raw list to a double.
    // This handles both integers and doubles from the database.
    final List<double> amplitudes = rawAmplitudes.map((e) => (e as num).toDouble()).toList();

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
            SizedBox(height: 2,),
            Row(
              spacing: 15,
              mainAxisSize: MainAxisSize.max,
              children: isMe?UserInformation.reversed.toList():UserInformation,
            ),
            SizedBox(height: 5,),
            //TODO:Add audiourl
            AudioMessageBuilder(audioUrl: message.source, duration: message.duration.toString(), amplitudes: amplitudes,),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: isMe?MainAxisAlignment.end:MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(

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




class AudioMessageBuilder extends StatefulWidget {
  final String audioUrl;
  final String duration;
  final List<double> amplitudes;

  const AudioMessageBuilder({
    super.key,
    required this.audioUrl,
    required this.duration,
    required this.amplitudes,
  });

  @override
  State<AudioMessageBuilder> createState() => _AudioMessageBuilderState();
}

class _AudioMessageBuilderState extends State<AudioMessageBuilder> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      // No need for setState here, onPlayerComplete will handle the icon change
    } else {
      await _audioPlayer.play(UrlSource(widget.audioUrl));
    }

    // It's slightly more efficient to set the isPlaying state here
    // based on the player's actual state stream.
    setState(() {
      _isPlaying = _audioPlayer.state == PlayerState.playing;
    });

    // Listen for when the playback completes
    _audioPlayer.onPlayerComplete.first.then((_) {
      // ADD THIS CHECK: Only call setState if the widget is still visible.
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
            onPressed: _togglePlay,
            color: Colors.blue.shade800,
          ),
          SizedBox( // Wrap the painter in a SizedBox to give it a defined size
            width: 150,
            height: 40,
            child: CustomPaint( // Use CustomPaint here
              painter: AudioWaveformPainter(
                // 3. PASS THE WIDGET'S AMPLITUDES TO THE PAINTER
                amplitudes: widget.amplitudes,
                waveColor: Colors.blue.shade800, // Changed for better contrast
              ),
            ),
          ),
          Text(widget.duration),
        ],
      ),
    );
  }
}