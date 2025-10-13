import 'dart:async';
import 'dart:typed_data';
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
import '../../sevices/GoogleDriveService.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:audioplayers/audioplayers.dart';

import 'AudioWaveformPainter.dart';

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    super.key,
    required this.message,
    required this.controller,
    required this.messageIndex,
    required this.chatController,
    required this. userName,
    this.fileId,
    required this.userCache,



  });

  final types.Message  message;
  final ReactionsController controller;
  final int messageIndex;
  final InMemoryChatController chatController;
  final String userName;
  final String? fileId;
  final Map<String, types.User> userCache;

  @override
  Widget build(BuildContext context) {
    final repliedMessage = chatController.messages.where(
            (msg) =>  message.replyToMessageId == msg.id,
    ).firstOrNull;

    final repliedUser = userCache.putIfAbsent(repliedMessage?.authorId !=null?repliedMessage!.authorId :"0", ()=>types.User(id:"0" , name: 'Unknown'));

    final bool isMe = message.authorId == supabase.auth.currentUser!.id?true:false;
    final hasReactions = controller.getReactionCounts(message.id).isNotEmpty;
    final msgPadding = const EdgeInsets.only(bottom: 2.0);

    final msgBackgroundColor = isMe
        ? Colors.indigo
        : Colors.purple;
    final msgTextColor =  isMe
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSecondary;
    final createdAt = message.createdAt;
    final seenAt = message.seenAt;

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
              padding: EdgeInsets.only(bottom:
              hasReactions ? 12.0 : 0

              ),
              child: messageBuilder(
                  context,
                  isMe,
                  hasReactions,
                  msgPadding,
                  msgTextColor,
                  msgBackgroundColor,
                  createdAt,
                  seenAt,
                  message,
                  repliedMessage,
                  repliedUser

              ),
            ),

            //reactions
            buildReactions(
              context,
              isMe,
              message
            ),
          ],
        ),
      ),
    );
  }

  // reactions widget
  Widget buildReactions(BuildContext context, bool isMe , message) {
    return isMe
        ? Positioned(
      bottom: 0,
      right: 20,
      child: StackedReactions(
        messageId: message!.id,
        controller: controller,
        maxReactionsToShow: 3,
        size: 18,


      ),
    )
        : Positioned(
      bottom: 0,
      left: 8,
      child: StackedReactions(
        messageId: message!.id,
        controller: controller,
        maxReactionsToShow: 3,
      ),
    );
  }

bool isPrevPost(message){
    if(messageIndex>0 && chatController.messages[messageIndex-1].authorId == message?.authorId ){
      return true;
    }
    return false;
}

  Widget messageBuilder(
      context ,bool isMe ,bool hasReactions ,EdgeInsetsGeometry msgPadding ,Color msgTextColor ,Color msgBackgroundColor ,DateTime? createdAt , DateTime? seenAt , types.Message message , types.Message? repliedMessage, types.User repliedUser
      ){

    final List<Widget> UserInformation =[
       Container(
          padding: EdgeInsets.symmetric(horizontal: 3,vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(120),
            borderRadius: BorderRadius.circular(5),
          ),
          child:Text(userName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 10, color: Colors.greenAccent,))),
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
        padding: msgPadding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // prevents full-width stretch
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: ChatBubble(
            padding: EdgeInsets.symmetric(horizontal: 15,vertical: 4),
            clipper: isMe
                ? isPrevPost(message)? ChatBubbleClipper5(type:BubbleType.sendBubble,radius: 10):ChatBubbleClipper1(
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
            backGroundColor: msgBackgroundColor,
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
                SizedBox(height: 4,),
                if(repliedMessage !=null)
                Container(
                margin: EdgeInsets.only(bottom: 4),
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                         Text(repliedUser.name!),
                      ],
                    ),
                    widgetByType(msgTextColor, repliedMessage ,fileId , isReply: true),
                  ],
                ),
                                ),
                widgetByType(msgTextColor, message ,fileId),
          
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: isMe?MainAxisAlignment.end:MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      //TODO:: Change Time sent logic for Messages Widget
                      createdAt !=null ?formatTimestampToAmPm(createdAt.toString()):"null",
                      style: TextStyle(
                        fontSize: 10,
                        color: msgTextColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    seenAt !=null ?Icon(
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
Widget widgetByType(Color msgTextColor , types.Message  message , String? fileId ,
    {bool isReply = false}){

  msgTextColor = isReply ? Colors.black : msgTextColor;

  if(message is types.TextMessage){
        return Text(
          message.text,
          style: TextStyle(
            color: msgTextColor,
          ),
        );
      }
      else if(message is types.ImageMessage){
        return DriveImageMessage(
          fileId: fileId!,
          driveService: driveService, // Pass your drive service instance
        );
      } else if(message is types.AudioMessage) {
        // 1. Safely get the raw list from metadata. If it's null, use an empty list.
        final List<dynamic> rawAmplitudes = message.metadata?['waveform'] ?? [];

        // 2. Safely convert each element of the raw list to a double.
        // This handles both integers and doubles from the database.
        final List<double> amplitudes = rawAmplitudes.map((e) => (e as num).toDouble()).toList();
        return AudioMessageBuilder(audioUrl: message.source, duration: message.duration, amplitudes: amplitudes , audioMessage: message,);
      } else {
        return const SizedBox.shrink();
      }

}

  types.Message? msgType(TextMessage? textMessage , ImageMessage? imageMessage , AudioMessage? audioMessage){
    if (textMessage !=null) return textMessage;
    else if (imageMessage != null) return imageMessage;
    else if (audioMessage !=null) return audioMessage;
    else return null;
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
              fullScreenImageViewer( snapshot.data! , context);
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

class AudioMessageBuilder extends StatefulWidget {
  final String audioUrl;
  final Duration  duration;
  final List<double> amplitudes;
  final AudioMessage audioMessage;

  const AudioMessageBuilder({
    super.key,
    required this.audioUrl,
    required this.duration,
    required this.amplitudes,
    required this.audioMessage,
  });

  @override
  State<AudioMessageBuilder> createState() => _AudioMessageBuilderState();
}

class _AudioMessageBuilderState extends State<AudioMessageBuilder> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool isReady = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    // Set the initial state based on the metadata
    isReady = (widget.audioMessage.metadata?['status'] ?? 'ready') == 'ready';
  }

  // 2. ▼▼▼ ADD THIS LIFECYCLE METHOD ▼▼▼
  // This function is called whenever the widget's properties are updated from the parent.
  @override
  void didUpdateWidget(covariant AudioMessageBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the status has changed from the old version of the widget to the new one.
    final oldStatus = oldWidget.audioMessage.metadata?['status'];
    final newStatus = widget.audioMessage.metadata?['status'];

    if (oldStatus != newStatus && newStatus == 'ready' ) {
      // If the status changed to 'ready', call setState to rebuild the UI.
      setState(() {
        isReady = true;
      });
    }
  }



  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
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
          if (isReady)
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
              onPressed: _togglePlay,
              color: Colors.blue.shade800,
            )
          else
            Container(
              width: 48, // Standard IconButton touch area
              height: 48,
              padding: const EdgeInsets.all(12.0),
              child: const CircularProgressIndicator(strokeWidth: 2),
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
          Text(_formatDuration(widget.duration)),
        ],
      ),
    );
  }
}