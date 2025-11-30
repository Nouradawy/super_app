
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_polls/flutter_polls.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Components/Constants.dart';
import '../../Confg/supabase.dart';
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
    required this.isSentByMe,
    required this.isPreviousMessageFromSameUser,
    required this.localMessages,
    required this.isUserScroll



  });

  final types.Message  message;
  final ReactionsController controller;
  final int messageIndex;
  final InMemoryChatController chatController;
  final String userName;
  final String? fileId;
  final Map<String, types.User> userCache;
  final bool isSentByMe;
  final bool isPreviousMessageFromSameUser;
  final List<types.Message> localMessages;
  final bool isUserScroll;

  @override
  Widget build(BuildContext context) {
    final repliedMessage = chatController.messages.where(
            (msg) =>  message.replyToMessageId == msg.id,
    ).firstOrNull;

    final repliedUser = userCache.putIfAbsent(repliedMessage?.authorId !=null?repliedMessage!.authorId :"0", ()=>types.User(id:"0" , name: 'Unknown'));
    final hasReactions = controller.getReactionCounts(message.id).isNotEmpty;
    final msgPadding = const EdgeInsets.only(bottom: 2.0);

    final msgBackgroundColor = isSentByMe
        ? Colors.indigo
        : Colors.purple;
    final msgTextColor =  isSentByMe
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSecondary;

    final seenAt = message.seenAt;




    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
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
                  isSentByMe,
                  hasReactions,
                  msgPadding,
                  msgTextColor,
                  msgBackgroundColor,
                  seenAt,
                  message,
                  repliedMessage,
                  repliedUser

              ),
            ),

            //reactions
            buildReactions(
              context,
              isSentByMe,
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
        reactionBackgroundColor: Colors.black87,
        onTap: ()=>debugPrint("reaction taped"),
        messageId: message!.id,
        controller: controller,
        maxReactionsToShow: 3,
        size: 20,


      ),
    )
        : Positioned(
      bottom: 0,
      left: 15,
      child: StackedReactions(
        reactionBackgroundColor: Colors.black87,
        onTap: ()=>debugPrint("reaction taped"),
        size: 20,
        messageId: message!.id,
        controller: controller,
        maxReactionsToShow: 3,
      ),
    );
  }






  Widget messageBuilder(
      context ,bool isSentByMe ,bool hasReactions ,EdgeInsetsGeometry msgPadding ,Color msgTextColor ,Color msgBackgroundColor  ,  DateTime? seenAt , types.Message message , types.Message? repliedMessage, types.User repliedUser
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
          child: Row(
            spacing: 5,
            children: [
              Icon(Icons.check_circle , color: Colors.greenAccent,size: 10,),
              Text("Verified owner",style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600 ,fontSize: 9 ,color: Colors.white),),
            ],
          )),
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
            padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 4),
            clipper: isSentByMe
                ? (isPreviousMessageFromSameUser? ChatBubbleClipper5(type:BubbleType.sendBubble,radius: 10):ChatBubbleClipper1(
                type:BubbleType.sendBubble,
                radius: 10,
                nipRadius: 0,
                nipHeight: 14,
                nipWidth: 5
            ))
                :ChatBubbleClipper1(
                type:BubbleType.receiverBubble,
                radius: 10,
                nipRadius: 0,
                nipHeight: 14,
                nipWidth: 5
            ),
            alignment: isSentByMe ? Alignment.topRight :Alignment.topLeft,
            backGroundColor: msgBackgroundColor,
            child:Column(
              crossAxisAlignment: isSentByMe?CrossAxisAlignment.end:CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,

              children: [
                // SizedBox(height: 2,),
                Row(
                  spacing: 15,
                  mainAxisSize: MainAxisSize.min,
                  children: isSentByMe?UserInformation.reversed.toList():UserInformation,
                ),
                const SizedBox(height: 4,),
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
                    widgetByType(msgTextColor, repliedMessage ,repliedMessage is ImageMessage?extractDriveFileId(repliedMessage.source):null ,isUserScroll, isReply: true),
                  ],
                ),
                                ),
                widgetByType(msgTextColor, message ,fileId , isUserScroll),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatTimestampToAmPm(message.createdAt!),
                      style: TextStyle(
                        fontSize: 10,
                        color: msgTextColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    MessageStatusIcon(message: message),
                  ],
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
Widget widgetByType(Color msgTextColor , types.Message  message , String? fileId , bool isUserScroll,
    {bool isReply = false}){
  final meta = message.metadata ?? {};
  if (message.metadata?['type'] == 'poll') {
    return Container(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 6 , vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: _pollMessageWidget(message, meta , isUserScroll));
  }
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
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight:250 , maxWidth: 250),
          child: DriveImageMessage(
            key: ValueKey('msg_${message.id}_$fileId'),
            fileId: fileId!,
            driveService: driveService, // Pass your drive service instance
            message : message,
            userName : userName,
          ),
        );
      } else if(message is types.AudioMessage) {
        // 1. Safely get the raw list from metadata. If it's null, use an empty list.
        final List<dynamic> rawAmplitudes = message.metadata?['waveform'] ?? [];

        // 2. Safely convert each element of the raw list to a double.
        // This handles both integers and doubles from the database.
        final List<double> amplitudes = rawAmplitudes.map((e) => (e as num).toDouble()).toList();
        return AudioMessageBuilder(audioUrl: message.source, duration: message.duration, amplitudes: amplitudes , audioMessage: message,);
      }  else {
        return const SizedBox.shrink();
      }

}


  Future<void> _handlePollVote(types.Message message, Map<String, dynamic> meta, String optionId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final sid = optionId.toString();
    final suid = userId.toString();

    // Shallow copies for rollback
    final originalMeta = Map<String, dynamic>.from(meta);
    final originalOptions = (meta['options'] as List<dynamic>?)
        ?.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
        .toList() ??
        [];

    // Defensive: normalize raw votes (handle Map<dynamic,dynamic>, List shapes, null)
    final rawVotesAny = meta['votes'];
    final Map<String, dynamic> rawVotes = {};
    if (rawVotesAny is Map) {
      rawVotesAny.forEach((k, v) => rawVotes[k.toString()] = v);
    }

    // Build normalized votes: optionId -> Map<userId, bool>
    final votes = <String, Map<String, bool>>{};
    rawVotes.forEach((k, v) {
      final key = k.toString();
      // It is a Map
      if (v is Map) {
        final m = <String, bool>{};
        v.forEach((kk, vv) {
          if (kk != null) m[kk.toString()] = vv == true || vv == 1 || vv == 'true';
        });
        votes[key] = m;
      } else if (v is List) {
        final m = <String, bool>{};
        for (final item in v) {
          if (item != null) m[item.toString()] = true;
        }
        votes[key] = m;
      } else {
        votes[key] = <String, bool>{};
      }
    });

    // Detect previous vote by this user
    String? previousOptionId;
    votes.forEach((optId, voters) {
      if (voters.containsKey(suid)) previousOptionId = optId;
    });

    final bool isUnvote = previousOptionId == sid;

    try {
      // Toggle/unvote logic
      if (isUnvote) {
        votes[sid]?.remove(suid);
        if (votes[sid]?.isEmpty ?? true) votes.remove(sid);
      } else {
        if (previousOptionId != null && previousOptionId != sid) {
          votes[previousOptionId!]?.remove(suid);
          if (votes[previousOptionId!]?.isEmpty ?? false) votes.remove(previousOptionId!);
        }
        votes.putIfAbsent(sid, () => <String, bool>{});
        votes[sid]![suid] = true;
      }

      // Update option counts (use stable id: option['id'] or fallback to index)
      final options = (meta['options'] as List<dynamic>?)
          ?.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .toList() ??
          [];

      for (var i = 0; i < options.length; i++) {
        final opt = options[i];
        final id = opt['id']?.toString() ?? i.toString();
        opt['votes'] = votes[id]?.length ?? 0;
      }

      // Prepare updated meta (votes stored as Map<optionId, Map<userId,true>>)
      final updatedMeta = Map<String, dynamic>.from(meta);
      updatedMeta['votes'] = votes.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)));
      updatedMeta['options'] = options;

      // Optimistic local update: preserve runtime message type when possible
      final existing = chatController.messages.firstWhere((m) => m.id == message.id, orElse: () => message);
      types.Message updatedMessage;
      if (existing is types.TextMessage) {
        updatedMessage = types.TextMessage(
          id: existing.id,
          authorId: existing.authorId,
          createdAt: existing.createdAt,
          text: existing.text,
          metadata: updatedMeta,
          replyToMessageId: existing.replyToMessageId,
          deliveredAt: existing.deliveredAt,
        );
      } else if (existing is types.ImageMessage) {
        updatedMessage = types.ImageMessage(
          id: existing.id,
          authorId: existing.authorId,
          createdAt: existing.createdAt,
          height: existing.height,
          width: existing.width,
          size: existing.size,
          source: existing.source,
          metadata: updatedMeta,
          replyToMessageId: existing.replyToMessageId,
        );
      } else if (existing is types.AudioMessage) {
        updatedMessage = types.AudioMessage(
          id: existing.id,
          authorId: existing.authorId,
          createdAt: existing.createdAt,
          size: existing.size,
          source: existing.source,
          duration: existing.duration,
          metadata: updatedMeta,
          replyToMessageId: existing.replyToMessageId,
        );
      } else if (existing is types.FileMessage) {
        updatedMessage = types.FileMessage(
          id: existing.id,
          authorId: existing.authorId,
          createdAt: existing.createdAt,
          name: existing.name,
          size: existing.size,
          mimeType: existing.mimeType,
          source: existing.source,
          metadata: updatedMeta,
          replyToMessageId: existing.replyToMessageId,
        );
      } else {
        updatedMessage = types.CustomMessage(
          id: existing.id,
          authorId: existing.authorId,
          createdAt: existing.createdAt,
          metadata: updatedMeta,
        );
      }

      // Apply optimistic update to controller and local cache
      try {
        chatController.updateMessage(existing, updatedMessage);
      } catch (_) {}
      final idx = localMessages.indexWhere((m) => m.id == message.id);
      if (idx != -1) localMessages[idx] = updatedMessage;

      // Persist to Supabase (votes/options in metadata)
      await supabase.from('messages').update({'metadata': updatedMeta}).eq('id', message.id);
    } catch (e) {
      // Rollback local change on any error
      try {
        final existing = chatController.messages.firstWhere((m) => m.id == message.id, orElse: () => message);
        final rollbackMeta = <String, dynamic>{...originalMeta, 'options': originalOptions};
        final rollbackMessage = existing is types.TextMessage
            ? types.TextMessage(
          id: existing.id,
          authorId: existing.authorId,
          createdAt: existing.createdAt,
          text: existing is types.TextMessage ? existing.text : '',
          metadata: rollbackMeta,
          replyToMessageId: existing.replyToMessageId,
          deliveredAt: existing.deliveredAt,
        )
            : types.CustomMessage(
          id: existing.id,
          authorId: existing.authorId,
          createdAt: existing.createdAt,
          metadata: rollbackMeta,
        );
        chatController.updateMessage(existing, rollbackMessage);
        final idx = localMessages.indexWhere((m) => m.id == message.id);
        if (idx != -1) localMessages[idx] = rollbackMessage;
      } catch (_) {}
    }
  }

  Future<Map<String, String>> _fetchAvatarsForUserIds(Set<String> userIds) async {
    if (userIds.isEmpty) return {};
    try {
      final rows = await supabase
          .from('profiles')
          .select('id, avatar_url')
          .inFilter('id', userIds.toList());

      final Map<String, String> map = {};
      for (final r in (rows as List)) {
        final id = r['id']?.toString();
        final url = r['avatar_url']?.toString();
        if (id != null && url != null && url.isNotEmpty) {
          map[id] = url;
        }else if(id !=null && url ==null){
          map[id] = "null";
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Widget _pollMessageWidget(types.Message message, Map<String, dynamic> meta , bool isUserScroll) {
    final effectiveMeta = Map<String, dynamic>.from(message.metadata ?? const {});
    final currentUserId = supabase.auth.currentUser?.id;
    final question = effectiveMeta['question']?.toString() ?? '';
    final expiresAt = effectiveMeta['expiresAt'] != null
        ? DateTime.tryParse(effectiveMeta['expiresAt']?.toString() ?? '')
        : null;

    // Normalize options to List<Map<String, dynamic>>
    final rawOptionsAny = effectiveMeta['options'];
    final List<Map<String, dynamic>> rawOptions = [];
    if (rawOptionsAny is List) {
      for (final item in rawOptionsAny) {
        if (item is Map) {
          rawOptions.add(Map<String, dynamic>.from(item));
        } else if (item is String) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map) rawOptions.add(Map<String, dynamic>.from(decoded));
            else rawOptions.add(<String, dynamic>{});
          } catch (_) {
            rawOptions.add(<String, dynamic>{});
          }
        } else {
          rawOptions.add(<String, dynamic>{});
        }
      }
    }

    // Normalize votes: accept Map<dynamic,dynamic> or other shapes and convert keys to String
    final votesAny = effectiveMeta['votes'];
    final Map<String, dynamic> votesRaw = {};
    if (votesAny is Map) {
      votesAny.forEach((k, v) => votesRaw[k.toString()] = v);
    }

    // Determine which option the current user voted for
    String? userVotedOptionId;
    votesRaw.forEach((optionId, votersRaw) {
      if (currentUserId == null) return;
      if (votersRaw is Map) {
        if (votersRaw.containsKey(currentUserId) || votersRaw.containsKey(currentUserId.toString())) {
          userVotedOptionId = optionId;
        }
      } else if (votersRaw is List) {
        if (votersRaw.any((it) => it?.toString() == currentUserId)) {
          userVotedOptionId = optionId;
        }
      }
    });
    // Build optionId -> List<userId> for all options
    final Map<String, List<String>> optionVoterIds = {};
    votesRaw.forEach((optId, votersRaw) {
      final list = <String>[];
      if (votersRaw is Map) {
        votersRaw.forEach((uid, val) {
          final isTrue = val == true || val == 1 || val == 'true';
          if (isTrue && uid != null) list.add(uid.toString());
        });
      } else if (votersRaw is List) {
        for (final uid in votersRaw) {
          if (uid != null) list.add(uid.toString());
        }
      }
      optionVoterIds[optId] = list;
    });

    // Fetch avatars once for all unique voter ids in this poll
    final Set<String> allUserIds =
    optionVoterIds.values.expand((e) => e).toSet();

    return FutureBuilder<Map<String,String>>(
      future:_fetchAvatarsForUserIds(allUserIds),
      builder: (context , snapshot){
        final idToAvatar = snapshot.data ?? const  <String  , String>{};
        // Build poll options (use index as fallback id). Limit title overflow.
        final pollOptions = rawOptions.asMap().entries.map((entry) {
          final i = entry.key;
          final option = entry.value;
          final id = option['id']?.toString() ?? i.toString();
          final titleText = option['title']?.toString() ??
              option['label']?.toString() ??
              option['text']?.toString() ??
              'Option ${i + 1}';
          final votes = option['votes'] is int
              ? option['votes'] as int
              : int.tryParse(option['votes']?.toString() ?? '0') ?? 0;
          final voterUrls = (optionVoterIds[id] ?? [])
              .map((uid) => idToAvatar[uid])
              .whereType<String>()
              .toList();


          return PollOption(
            id: id,
            title: Text(
              titleText,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            votes: votes,
            voterAvatars: voterUrls,
          );
        }).toList();

        return FlutterPolls(
          pollId: message.id,
          createdBy: message.authorId,
          voteAnimation: !isUserScroll,
          allowToggleVote:true,
          pollProgressbarHeight: 5,
          hasVoted: userVotedOptionId != null,
          userVotedOptionId: userVotedOptionId,
          userToVote: currentUserId,
          pollTitle: Text(question, overflow: TextOverflow.ellipsis),
          pollOptions: pollOptions,
          onVoted: (PollOption option, int totalVotes) async {
            try {
              await _handlePollVote(message, effectiveMeta, option.id!);
              return true;
            } catch (_) {
              return false;
            }
          },
        );
      },
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


class MessageStatusIcon extends StatelessWidget {
  final types.Message message;
  const MessageStatusIcon({super.key, required this.message});

  @override
  Widget build(BuildContext context) {

    final bool isSeen = message.metadata?['isSeen'] == true;

    IconData iconData = Icons.check;
    Color iconColor = Colors.grey;

    // The logic is now much simpler
    if (isSeen) {
      iconData = Icons.done_all;
      iconColor = Colors.blueAccent;
    } else if (message.metadata?['deliveredAt'] != null) {
      iconData = Icons.done_all;
      iconColor = Colors.grey;
    } else if (message.metadata?['sentAt'] != null) {
      iconData = Icons.check;
    }

    return Icon(iconData, color: iconColor, size: 13);
  }
}



String? extractDriveFileId(String url) {
  try {
    final uri = Uri.parse(url);
    // The file ID is usually the third segment in the path: /file/d/{FILE_ID}
    if (uri.pathSegments.length > 2 && uri.pathSegments[1] == 'd') {
      return uri.pathSegments[2];
    }
  } catch (e) {
    print("Error parsing Drive URL: $e");
  }
  return null;
}

