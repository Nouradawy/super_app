import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:googleapis/admob/v1.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:ntp/ntp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_recorder/provider/sound_record_notifier.dart';
import 'package:social_media_recorder/screen/social_media_recorder.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:super_app/Layout/Cubit/cubit.dart';
import 'package:super_app/Layout/Cubit/states.dart';
import 'package:super_app/Layout/chatWidget/AudioMessageWidget.dart';
import 'package:uuid/uuid.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../Components/Constants.dart';
import '../Confg/supabase.dart';
import '../sevices/GoogleDriveService.dart';
import 'chatWidget/ImageMessageWidget.dart';
import 'chatWidget/MessageWidget.dart';
import 'chatWidget/UploadProgressMessage.dart';
import 'package:record/record.dart';


final supabase = Supabase.instance.client;
TextEditingController chatTextController = TextEditingController();

class Generalchat extends StatefulWidget {
  const Generalchat({super.key});

  @override
  State<Generalchat> createState() => _GeneralchatState();
}

class _GeneralchatState extends State<Generalchat> with AutomaticKeepAliveClientMixin{
  @override
  bool get wantKeepAlive => true;

  final Map<String, types.User> _userCache = {};
  final Map<String, double> _uploadProgress = {};
  types.Message? _repliedMessage;
  late types.InMemoryChatController _chatController;

  late final ScrollController _scrollController;
  late final ReactionsController _reactionsController;


  final int _pageSize = 20;
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isTyping = false;

  String? _lastMessageId;
  RealtimeChannel? _realtimeChannel;
  static const String _messagesCacheKey = 'chat_messages';

  @override
  void initState() {
    super.initState();
    _chatController = types.InMemoryChatController();
    chatTextController = TextEditingController();
    _scrollController = ScrollController();
    _reactionsController = ReactionsController(currentUserId: Userid);
    _loadMessagesFromCacheAndFetchLatest();
    _subscribeToRealtime();
    chatTextController.addListener(_handleTypingStatus);



    // Add this to try and sign in silently on start
    // driveService.signInSilently().then((_) {
    //   if (driveService.currentUser != null) {
    //     setState(() {
    //       googleUser = driveService.currentUser;
    //     });
    //   }
    // });

  }
  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _chatController.dispose();
    _scrollController.dispose();
    _saveMessagesToCache(_chatController.messages);
    chatTextController.removeListener(_handleTypingStatus);
    chatTextController.dispose();

    super.dispose();
  }




  void _subscribeToRealtime() {
    _realtimeChannel = supabase
        .channel('public:messages')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        final newMessageMap = payload.newRecord;
        final localId = newMessageMap['metadata']?['localId'];

        // --- Replacement Logic ---
        if (localId != null) {
          // Find and remove the placeholder message
          try {
            final placeholder = _chatController.messages
                .firstWhere((m) => m.id == localId);
            _chatController.removeMessage(placeholder);
            _uploadProgress.remove(localId); // Clean up progress tracking
          } catch (e) {
            // Placeholder might not be found if the user scrolled away and it was disposed
            print('Could not find placeholder to remove: $e');
          }
        }

        final newMessage = _mapToMessage(newMessageMap);

        if (!_chatController.messages.any((m) => m.id == newMessage.id)) {

          _chatController.insertMessage(newMessage);

          // Save updated list to cache
          _saveMessagesToCache(_chatController.messages);
        }
      },
    )
        .subscribe();
  }

  Future<void> _saveMessagesToCache(List<types.Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedMessages = messages.map((msg) {
      // First, convert the message to a Map that flutter_chat_ui can work with
      // Unfortunately, flutter_chat_types doesn't have a built-in toJson for all message types.
      // We need to handle this manually.
      final messageMap = {
        'author_id': msg.authorId,
        'created_at':msg.createdAt?.toIso8601String(),
        'id': msg.id,
        'metadata': msg.metadata,
        'replyToMessageId': msg.replyToMessageId ,
        'uri': msg is types.FileMessage ? msg.source : (msg is types.ImageMessage ? msg.source : null),
        'text': msg is types.TextMessage ? msg.text : null,
        'name': msg is types.FileMessage ? msg.name : null,
        'size': msg is types.FileMessage ? msg.size : (msg is types.ImageMessage ? msg.size : null),
        'height': msg is types.ImageMessage ? msg.height : null,
        'width': msg is types.ImageMessage ? msg.width : null,
      };
      return jsonEncode(messageMap);
    }).toList();
    await prefs.setStringList(_messagesCacheKey, encodedMessages);
  }

  Future<List<types.Message>> _loadMessagesFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedMessages = prefs.getStringList(_messagesCacheKey);
    if (encodedMessages == null) {
      return [];
    }
    return encodedMessages.map((encodedMsg) {
      final messageMap = jsonDecode(encodedMsg) as Map<String, dynamic>;
      return _mapToMessage(messageMap); // Reuse your existing mapping function
    }).toList();
  }

  // Modified and new loading methods
  Future<void> _loadMessagesFromCacheAndFetchLatest() async {
    // Load from cache first for instant UI
    final cachedMessages = await _loadMessagesFromCache();
    if (cachedMessages.isNotEmpty) {
      _chatController.insertAllMessages(cachedMessages);
    }

    // Now, fetch from Supabase to get the latest
    _loadMessages();
  }

  void _markMessageAsSeen(String messageId) async {
    if (!mounted) return;
    // Add a print statement to be certain of the data being sent.
    print('Attempting to mark message as seen. User ID: ${UserData!.id}, Message ID: $messageId');

    try {
      // Await the future to ensure the operation completes and to catch errors.
      await supabase.from('message_receipts').upsert(
        {
          'message_id': messageId,
          'user_id': Userid,
          'seen_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'message_id, user_id',
      );

      // Optional: A success message to confirm the upsert worked.
      print('Successfully upserted seen status for message: $messageId');

    } catch (error) {
      // This will catch and print any error from the upsert operation.
      print('Error marking message as seen: $error');
    }
  }

  Future<void> _loadMessages() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    // Fetch messages using _lastMessageId for pagination
    final response = await supabase
        .rpc('get_messages_with_seen_status', params: {
          'page_size': _pageSize,
          'page_num': _currentPage,
        });



    final List<types.Message> newMessages = (response as List)
        .map((map) => _mapToMessage(map as Map<String, dynamic>))
        .toList();
    if (newMessages.isEmpty) {
      _hasMore = false;
    } else {

      final existingIds = _chatController.messages.map((m) => m.id).toSet();
      final uniqueNewMessages = newMessages.where((m) => !existingIds.contains(m.id)).toList().reversed.toList();

      if (uniqueNewMessages.isNotEmpty) {
        await _chatController.insertAllMessages(uniqueNewMessages, index: 0);
        _currentPage++;
        _lastMessageId = uniqueNewMessages.first.id;

        // Save updated list to cache
        _saveMessagesToCache(_chatController.messages);
      }
    }
    setState(() => _isLoading = false);
  }


  types.Message _mapToMessage(Map<String, dynamic> map) {
    final seenAtTimestamp = map['latest_seen_at'] != null
        ? DateTime.parse(map['latest_seen_at'])
        : null;
    final metadata = map['metadata'] as Map<String, dynamic>?;
    final messageType = metadata?['type'] ?? map['type'];


    switch (messageType) {
      case 'image':
        final metadata = map['metadata'] as Map<String, dynamic>?;
        print('iam at Image case ??????????!!!!0');
        return types.ImageMessage(
          createdAt: DateTime.parse(map['created_at']),
          id: map['id'],
          text:metadata?['name'] ?? 'image',
          authorId:  map['author_id'],
          size: metadata?['size'] ?? 0,
          height: metadata?['height']?.toDouble(),
          width: metadata?['width']?.toDouble(),
          source: map['uri'],
          metadata: map['metadata'],
        );
      case 'file':
        final metadata = map['metadata'] as Map<String, dynamic>?;
        return types.FileMessage(
          createdAt: DateTime.parse(map['created_at']),
          id: map['id'],
          authorId:  map['author_id'],
          name: metadata?['name'] ?? 'File',
          size: metadata?['size'] ?? 0,
          mimeType: metadata?['mimeType'],
          source: map['uri'],
          metadata: map['metadata'],
        );
      case 'audio':
        final durationString = metadata?['duration'] ?? '00:00';
        final parts = durationString.split(':');
        final duration = Duration(
          minutes: int.tryParse(parts[0]) ?? 0,
          seconds: int.tryParse(parts[1]) ?? 0,
        );

        return types.AudioMessage(
          createdAt: DateTime.parse(map['created_at']),
          id: map['id'],
          authorId: map['author_id'],
          size: metadata?['size'] ?? 0,
          source: map['uri'], // This will be the Google Drive link
          duration: duration,
          metadata: map['metadata'],
        );
      default: // 'text'
        return types.TextMessage(
          createdAt: DateTime.parse(map['created_at']),
          id: map['id'],
          authorId:  map['author_id'],
          text: map['text'] ?? '',
          metadata: map['metadata'],
          replyToMessageId: (map['metadata'] as Map<String, dynamic>?)?['reply_to'],
          deliveredAt: DateTime.parse(map['created_at']),
          seenAt: seenAtTimestamp,


        );
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result == null) return;

    final file = File(result.path);

    final localId = const Uuid().v4(); // Unique ID for our placeholder
    // TODO: Consider showing a loading indicator to the user here

    final placeholderMessage = types.CustomMessage(
      id: localId,
      authorId: Userid,
      createdAt: await NTP.now(),
      metadata: {
        'type': 'image',
        'localId': localId,
        'filePath': result.path, // Path to the local file for the thumbnail
      },
    );

    _chatController.insertMessage(placeholderMessage);
    setState(() {
      _uploadProgress[localId] = 0.0; // Initialize progress
    });

    // 2. Upload the file to Google Drive
    final fileName = '${const Uuid().v4()}.${result.path.split('.').last}';
    final driveLink = await driveService.uploadFile(
        file,
        fileName,
        'image',

      onProgress: (progress){
          setState(() {
            _uploadProgress[localId] =  progress;
          });
      }
    );

    if (driveLink != null) {

      final bytes = await file.readAsBytes();
      final image = await decodeImageFromList(bytes);

      // 4. Insert one message record with the Google Drive link
      await supabase.from('messages').insert({
        'id': const Uuid().v4(),
        'author_id': Userid,
        'uri': driveLink, // The link from Google Drive
        'created_at': (await NTP.now()).toIso8601String(), // Use NTP UTC time
        'metadata': {
          'type': 'image',
          'localId': localId, // **IMPORTANT** link to the placeholder
          'name': result.name, // Use the original file name for display
          'size': bytes.length,
          'height': image.height.toDouble(),
          'width': image.width.toDouble(),
        }
      });
    } else {
      // Handle failure: maybe update the placeholder to show a "failed" state
      print('Upload failed for local message ID: $localId');
      // You could update the progress map with a special value like -1 to indicate failure
      setState(() {
        _uploadProgress.remove(localId); // Or simply remove it
        _chatController.removeMessage(placeholderMessage);
      });
      // Handle the upload failure
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleAttachmentPressed() {
    if (googleUser == null) {
      // Prompt user to sign in if they haven't already
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please link your Google Drive account first.')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result == null || result.files.single.path == null) return;

    final file = result.files.single;
    final fileBytes = await File(file.path!).readAsBytes();
    final fileName = '${const Uuid().v4()}_${file.name}';

    // Upload to Supabase Storage
    await supabase.storage.from('chat_attachments').uploadBinary(
      fileName,
      fileBytes,
      fileOptions: FileOptions(contentType: lookupMimeType(file.path!)),
    );

    // Get public URL
    final fileUrl = supabase.storage.from('chat_attachments').getPublicUrl(fileName);

    // Insert message record
    await supabase.from('messages').insert({
      'id': const Uuid().v4(),
      'author_id':UserData!.id,
      'uri': fileUrl,
      'type': 'file',
      'created_at': DateTime.now().toIso8601String(),
      'metadata': {
        'name': file.name,
        'size': file.size,
        'mimeType': lookupMimeType(file.path!),
      }
    });
  }

  void _handleSendPressed(text) async {
    String id = const Uuid().v4();


    _chatController.insertMessage(types.TextMessage(
        id: id,
        authorId:Userid,
        text: text,
        createdAt: await NTP.now(),
    ));


    await supabase.from('messages').insert({
      'id': id,
      'author_id': Userid,
      'text': text,

      'created_at' :  (await NTP.now()).toIso8601String(),
      'metadata': {
        'type': 'text',
        if (_repliedMessage != null) 'reply_to': _repliedMessage!.id,

      },

    });
    setState(() {
      _repliedMessage = null; // Clear after sending
    });
  }

  Widget replyTopBar(){
    if (_repliedMessage != null) {
      return Container(
          width: MediaQuery.sizeOf(context).width*0.7,
          decoration: BoxDecoration(
              color:HexColor("#E8E8E8"),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(5),topRight: Radius.circular(5))
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("UserName"),
                  IconButton(
                    iconSize:20,
                    padding: EdgeInsets.zero,
                    onPressed: (){
                      _repliedMessage = null;
                      setState(() {
                      });
                    },
                    icon: Icon(Icons.close ),
                  ),
                ],
              ),
              Container(
                width: MediaQuery.sizeOf(context).width*0.6,
                padding: EdgeInsets.symmetric(horizontal: 10,vertical: 2),
                decoration: BoxDecoration(
                    color:Colors.black12,
                    border: BoxBorder.fromLTRB(left: BorderSide(color:Colors.greenAccent , width: 2)),
                    borderRadius: BorderRadius.circular(5)
                ),
                child: Text(
                  (_repliedMessage is types.TextMessage
                      ? (_repliedMessage as types.TextMessage).text
                      : _repliedMessage is types.ImageMessage
                      ? 'Image'
                      : _repliedMessage is types.FileMessage
                      ? 'File: ' + (_repliedMessage as types.FileMessage).name
                      : 'Message'),
                ),),
            ],
          )
      );
    }
    return Container();

  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }


  void _handleTypingStatus() {
    if (chatTextController.text.isNotEmpty && !_isTyping) {
      // User started typing
      setState(() {
        _isTyping = true;
      });
      AppCubit.get(context).showHideMic();
      // You can add logic here to notify others, e.g., via Supabase
      print("User is typing...");
    } else if (chatTextController.text.isEmpty && _isTyping) {
      // User cleared the text field
      setState(() {
        _isTyping = false;
      });
      AppCubit.get(context).showHideMic();
      // Notify that the user has stopped typing
      print("User has stopped typing.");
    }
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar:AppBar(
          title:Text("General Chat"),
      ),
      body: Stack(
        children: [
          Chat(
            chatController: _chatController,
            currentUserId: Userid,
            resolveUser: (id) async{

              // THIS IS THE KEY: Replace your old resolveUser with this new version
             if(_userCache.containsKey(id)){
               return _userCache[id]!;
             }
             // 2. If not in cache, fetch the profile from your 'profiles' table
            try{
               final response = await supabase
                   .from('profiles')
                   .select('display_name , avatar_url')
                   .eq('id',id)
                   .single(); // Use .single() as each user has only one profile

              final user = types.User(
                id:id,
                name: response['display_name'] ?? 'Unknown',
                imageSource: response['avatar_url'],
              );
              // 3. Store the newly fetched user in the cache
              _userCache[id]  = user;
              return user;

            } catch (error) {
               print("User not found in profiles table with id : "+id);
              // If any error occurs (e.g., profile not found), return an 'Unknown' user
              final unknownUser = types.User(id: id, name: 'Unknown');
              _userCache[id] = unknownUser; // Cache the unknown user too
              return unknownUser;
            }
            },

            onMessageSend: (text) {

                _handleSendPressed(text);


            },

            onAttachmentTap:_handleAttachmentPressed,
            builders: types.Builders(
              textMessageBuilder:
                  (
                  context,
                  message,
                  index,
                  {
                required bool isSentByMe,
                types.MessageGroupStatus? groupStatus,
              }) {
                    final replyToId = message.metadata?['reply_to'];
                    final repliedMessage = _chatController.messages
                        .where((m) => m.id == replyToId)
                        .cast<types.Message?>()
                        .firstOrNull;

                    return Stack(
                      children: [
                        VisibilityDetector(
                          key: Key(message.id),
                          onVisibilityChanged: (VisibilityInfo info) {
                            if (info.visibleFraction  >= 0.8 ) {

                              // Call a function to mark the message as seen
                             if(message.authorId != Userid) _markMessageAsSeen(message.id);
                            }
                          },
                          child: ChatMessageWrapper(
                              messageId: message.id,
                              controller: _reactionsController,
                              onMenuItemTapped: (item){
                                if(item.label == "Reply") {
                                  setState(() {
                                    _repliedMessage = message;
                                  });
                                }
                              },
                              child: MessageWidget(
                                message: message,
                                controller: _reactionsController,
                                messageIndex:index ,
                                chatController: _chatController,
                                userName : Username(
                                    userId: message.authorId,
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600 ,fontSize: 10 ,color: Colors.greenAccent)
                                ),
                              )),
                        ),
                        // if (repliedMessage != null && repliedMessage is types.TextMessage)
                        // Container(
                        //   margin: EdgeInsets.only(bottom: 4),
                        //   padding: EdgeInsets.all(6),
                        //   decoration: BoxDecoration(
                        //     color: Colors.grey[300],
                        //     borderRadius: BorderRadius.circular(6),
                        //   ),
                        //   child: Text(
                        //     (repliedMessage).text,
                        //     style: TextStyle(fontSize: 12, color: Colors.black87),
                        //   ),
                        // ),
                      ],
                    );
                  },
              chatMessageBuilder: (context,
              message,
              index,
              animation,
              child, {
                bool? isRemoved,
                required bool isSentByMe,
                types.MessageGroupStatus? groupStatus,
                  }) {
                final isSystemMessage =
                    message.authorId == 'system';
                final isFirstInGroup = groupStatus?.isFirst ?? true;

                final shouldShowAvatar = true;

                final shouldShowUsername = true;
                double avatarSize = 36;

                // 2️⃣ Normalize to non-null DateTimes
                final current = message.createdAt?.toLocal() ?? DateTime.now();
                // final prevMsg = index > 0
                //     ? _chatController.messages[index - 1]
                //     : null;
                // final previous =
                //     prevMsg?.createdAt?.toLocal() ?? current;
                //
                // // 3️⃣ Decide which header (if any)
                // Widget? header;
                // if (!_isSameDay(previous, current) ||
                //     current.difference(previous).abs() >
                //         _timeGapThreshold) {
                //   // a) day changed → date header
                //   header = _buildDateandTimeHeader(current);
                // }
                return ChatMessage(
                    message: message,
                    index: index,
                    animation: animation,
                    child: child
                );
              },
              chatAnimatedListBuilder: (context,itemBuilder){
                return ChatAnimatedList(
                  itemBuilder: itemBuilder,
                  onEndReached: _loadMessages,

                  initialScrollToEndMode:InitialScrollToEndMode.none,
                );
              },
        audioMessageBuilder:(context,
            message,
            index,{
          required bool isSentByMe,
              types.MessageGroupStatus? groupStatus,
            }){
                return  AudioMessageWidget(
                  message: message,
                  controller: _reactionsController,
                  messageIndex:index ,
                  chatController: _chatController,
                  userName : Username(
                      userId: message.authorId,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600 ,fontSize: 10 ,color: Colors.greenAccent)
                  ),
                );
        },


              imageMessageBuilder: (
                  context,
                  message,
                  index, {
                    required bool isSentByMe,
                    types.MessageGroupStatus? groupStatus,
                  }) {

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

                final fileId = extractDriveFileId((message).source);

                if (fileId == null) {
                  // Show an error icon if the URL is invalid
                  return const Center(child: Icon(Icons.error_outline, color: Colors.red));
                }

                // 2. Use a FutureBuilder to download and display the image
                return ImageMessageWidget(
                  message: message,
                  controller: _reactionsController,
                  fileId : fileId,
                  messageIndex:index ,
                  chatController: _chatController,
                  userName : Username(
                      userId: message.authorId,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600 ,fontSize: 10 ,color: Colors.greenAccent)
                  ),
                );
              },


              customMessageBuilder: (
                  context,
                  message,
                  index, {
                    required bool isSentByMe,
                    types.MessageGroupStatus? groupStatus,
                  }){
                final localId = message.metadata?['localId'];
                final filePath = message.metadata?['filePath'];
                final progress = _uploadProgress[localId] ?? 0.0;

                if (filePath != null) {
                  return UploadProgressMessage(filePath: filePath, progress: progress);
                }
                // Fallback for any other custom message type
                return const SizedBox();
              },
              composerBuilder: (context) {
                return BlocBuilder<AppCubit,AppCubitStates>(
                  builder: (context,state) {

                    return Visibility(
                      visible: !AppCubit.get(context).isRecording,
                      child: Composer(
                        gap:0,
                        sendIcon:Icon(Icons.send),
                        textEditingController: chatTextController,
                        handleSafeArea: true,
                        sigmaX: 3,
                        sigmaY: 3,
                        sendButtonHidden:chatTextController.text.isEmpty?true:false,



                      ),
                    );
                  }
                );
              }),


          ),
          //Used to render Replay toBar in case you click and hold the message
          Transform.translate(

              offset: Offset(0, -70),
              child: replyTopBar()),
        ],
      ),
    );
  }
}




Future FullScreenImageViewer (imageData , context) {
    return showDialog(
      builder: (BuildContext context)=> Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.memory(imageData),
        ),
      ), context: context,
    );
  }
