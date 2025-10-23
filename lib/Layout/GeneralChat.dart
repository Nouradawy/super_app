import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:ntp/ntp.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:super_app/Layout/Cubit/cubit.dart';
import 'package:super_app/Layout/Cubit/states.dart';
import 'package:uuid/uuid.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../Components/Constants.dart';
import '../Confg/supabase.dart';
import 'package:http/http.dart' as http;
import 'chatWidget/MessageWidget.dart';
import 'chatWidget/UploadProgressMessage.dart';


class GeneralChat extends StatefulWidget {

  final int compoundId;
  const GeneralChat({super.key , required this.compoundId});

  @override
  State<GeneralChat> createState() => _GeneralChatState();
}

class _GeneralChatState extends State<GeneralChat> {
  late final TextEditingController _chatTextController;
  int? _channelId;

  bool _isInitializing = true;
  late final String _userId;
///Initialize _userCache from supabase
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


  RealtimeChannel? _realtimeChannel;
  types.User? messageUser ;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _chatController = types.InMemoryChatController();
    _chatTextController = TextEditingController();
    _scrollController = ScrollController();
    _chatTextController.addListener(_handleTypingStatus);

  }


  final Map<String, Timer> _pollingTimers = {};
  @override
  void dispose() {
    _pollingTimers.values.forEach((timer) => timer.cancel());
    _realtimeChannel?.unsubscribe();
    _chatController.dispose();
    _scrollController.dispose();
    _saveMessagesToCache(_chatController.messages);
    _chatTextController.removeListener(_handleTypingStatus);
    _chatTextController.dispose();

    super.dispose();
  }

  Future<void> _initializeChat() async {
    // It can be helpful to wait for the end of the frame
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    // Fetch the user ID safely within the widget itself
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      // Handle the error, maybe show a message or pop the screen
      print("FATAL: GeneralChat loaded without a logged-in user.");
      if (mounted) setState(() => _isInitializing = false);
      return;
    }

    // Now that you have the ID, initialize everything that depends on it
    setState(() {
      _userId = userId;
      _reactionsController = ReactionsController(currentUserId: _userId);
      _initializeAndSubscribe();
      _isInitializing = false; // Turn off the loading indicator
    });
  }
  Future<void> _initializeAndSubscribe() async {
    try {
      final response = await supabase
          .from('channels')
          .select('id')
          .eq('compound_id', widget.compoundId) // Use the passed-in compoundId
          .eq('type', 'COMPOUND_GENERAL') // As defined in the schema
          .single(); // Assuming one general channel per compound

      setState(() {
        _channelId = response['id'];
      });

      // Now that we have the channel ID, we can load messages and subscribe
      _loadMessagesFromCacheAndFetchLatest();
      _subscribeToRealtime();

    } catch (error) {
      print('Error fetching channel ID: $error');
      // Handle the error, maybe show a message to the user
    }
  }
  void _subscribeToRealtime() {
    if (_channelId == null) return;

    _realtimeChannel = supabase
        .channel('public:messages:channel_id=eq.$_channelId')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'channel_id',
          value: _channelId,
        ),
      callback: (payload) {
        // ADD LOGIC TO HANDLE DIFFERENT EVENT TYPES
        if (payload.eventType == PostgresChangeEvent.insert) {
          final newMessageMap = payload.newRecord;
          final localId = newMessageMap['metadata']?['localId'];

          if (localId != null) {
            try {
              final placeholder = _chatController.messages.firstWhere((m) =>
              m.id == localId);
              _chatController.removeMessage(placeholder);
            } catch (e) {
              print('Could not find placeholder to remove: $e');
            }
          }
          final newMessage = _mapToMessage(newMessageMap);
          if (newMessage is types.AudioMessage && newMessage.metadata?['status'] == 'processing') {
            _startPollingForMessage(newMessage);
          }
          if (!_chatController.messages.any((m) => m.id == newMessage.id)) {
            _chatController.insertMessage(newMessage);
          }
        } else if (payload.eventType == PostgresChangeEvent.update) {
          // THIS IS THE NEW LOGIC FOR UPDATES
          final updatedMessageMap = payload.newRecord;
          final updatedMessage = _mapToMessage(updatedMessageMap);

          try{
            final originalMessage  = _chatController.messages.firstWhere(
                    (msg) => msg.id == updatedMessage.id
            );

            // This finds and replaces the message in the chat list, triggering a UI refresh.
            _chatController.updateMessage(originalMessage , updatedMessage);
          } catch (e){
            print('Could not find the original message to update: ${updatedMessage.id}');
          }
        }

        _saveMessagesToCache(
            _chatController.messages); // Save cache on any change
      },
    )
        .subscribe();
  }

  void _startPollingForMessage(types.AudioMessage message) {
    // Prevent starting multiple timers for the same message
    if (_pollingTimers.containsKey(message.id)) return;

    final timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final isReadyNow = await _checkUrlIsReady(message.source);
      if (isReadyNow) {
        timer.cancel(); // Stop this timer
        _pollingTimers.remove(message.id); // Remove from tracking

        // Update the message in Supabase so everyone sees it as ready
        final currentMetadata = message.metadata ?? {};
        await supabase.from('messages').update({
          'metadata': {
            ...currentMetadata,
            'status': 'ready',
          }
        }).eq('id', message.id);
      }
    });

    _pollingTimers[message.id] = timer; // Track the new timer
  }

  Future<void> _deleteMessage(types.Message message) async {

    await supabase.from('messages').update({
      'text': "this message deleted by the user",
      'uri':null,
    'metadata': {
    'type': 'text',
    },


  }).eq('id', message.id);

  }
  // Helper function for checking the URL (can also be in this file)
  Future<bool> _checkUrlIsReady(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveMessagesToCache(List<types.Message> messages) async {

    if (_channelId == null) return;

    final prefs = await SharedPreferences.getInstance();

    // Create a dynamic cache key unique to this channel.
    final cacheKey = 'chat_messages_$_channelId';

    final List<String> encodedMessages = messages.map((msg) {
      // First, convert the message to a Map that flutter_chat_ui can work with
      // Unfortunately, flutter_chat_types doesn't have a built-in toJson for all message types.
      // We need to handle this manually.
      final messageMap = {
        'author_id': msg.authorId,
        'created_at':msg.createdAt?.toIso8601String(),
        'id': msg.id,
        'metadata': {
          ...?msg.metadata, // Use the spread operator to copy existing metadata
          if (msg.replyToMessageId != null) 'reply_to': msg.replyToMessageId,
        },

        'uri': msg is types.FileMessage
            ? msg.source
            : (msg is types.ImageMessage
            ? msg.source
            : (msg is types.AudioMessage ? msg.source : null)),
        'text': msg is types.TextMessage ? msg.text : null,
        'name': msg is types.FileMessage ? msg.name : null,
        'size': msg is types.FileMessage ? msg.size : (msg is types.ImageMessage ? msg.size : null),
        'height': msg is types.ImageMessage ? msg.height : null,
        'width': msg is types.ImageMessage ? msg.width : null,
        'type': msg.metadata?['type'] ?? (msg is types.ImageMessage
            ? 'image'
            : (msg is types.FileMessage
            ? 'file'
            : (msg is types.AudioMessage
            ? 'audio'
            : 'text'))),
      };
      return jsonEncode(messageMap);
    }).toList();
    // Use the new dynamic key to save the messages.
    await prefs.setStringList(cacheKey, encodedMessages);
  }

  Future<List<types.Message>> _loadMessagesFromCache() async {

    // Guard clause: Don't load from cache if we don't know the channel.
    if (_channelId == null) return [];


    final prefs = await SharedPreferences.getInstance();

    // Create the same dynamic cache key to find the right messages.
    final cacheKey = 'chat_messages_$_channelId';
    final encodedMessages = prefs.getStringList(cacheKey);
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
          'user_id': _userId,
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
          'p_channel_id': _channelId,
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

        // Save updated list to cache
        _saveMessagesToCache(_chatController.messages);
      }
    }
    AppCubit.get(context).chatController = _chatController;
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


        return types.ImageMessage(
          createdAt: DateTime.parse(map['created_at']),
          id: map['id'],
          text:metadata?['name'] ?? 'image',
          authorId:  map['author_id'],
          size: metadata?['size'] ?? 0,
          height: metadata?['height']?.toDouble(),
          width: metadata?['width']?.toDouble(),
          source: map['uri'],
          metadata: metadata,
          replyToMessageId: metadata?['reply_to']
        );
      case 'file':

        return types.FileMessage(
          createdAt: DateTime.parse(map['created_at']),
          id: map['id'],
          authorId:  map['author_id'],
          name: metadata?['name'] ?? 'File',
          size: metadata?['size'] ?? 0,
          mimeType: metadata?['mimeType'],
          source: map['uri'],
          metadata: metadata,
          replyToMessageId: metadata?['reply_to']
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
          metadata: metadata,
          replyToMessageId: metadata?['reply_to'],
        );
      default: // 'text'
        return types.TextMessage(
          createdAt: DateTime.parse(map['created_at']),
          id: map['id'],
          authorId:  map['author_id'],
          text: map['text'] ?? '',
          metadata: metadata,
          replyToMessageId: metadata?['reply_to'],
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


    final placeholderMessage = types.CustomMessage(
      id: localId,
      authorId: _userId,
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
        'author_id': _userId,
        'uri': driveLink, // The link from Google Drive
        'created_at': (await NTP.now()).toIso8601String(), // Use NTP UTC time
        'channel_id': _channelId,
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
      'channel_id': _channelId,
      'metadata': {
        'name': file.name,
        'size': file.size,
        'mimeType': lookupMimeType(file.path!),
      }
    });
  }



  void _handleSendPressed(text) async {
    if (_channelId == null) {
      print("Cannot send message, channel ID is not set.");
      return;
    }

    String id = const Uuid().v4();

    _chatController.insertMessage(types.TextMessage(
        id: id,
        authorId:_userId,
        text: text,
        createdAt: await NTP.now(),
      replyToMessageId: _repliedMessage?.id
    ));

    await supabase.from('messages').insert({
      'id': id,
      'author_id': _userId,
      'text': text,
      'channel_id': _channelId,
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
          width: MediaQuery.sizeOf(context).width*0.8,
          decoration: BoxDecoration(
              color:types.ChatColors
                  .light()
                  .surfaceContainerHigh
                  .withAlpha(100),
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
                width: MediaQuery.sizeOf(context).width*0.7,
                padding: EdgeInsets.symmetric(horizontal: 10,vertical: 2),
                decoration: BoxDecoration(
                    color:types.ChatColors
                        .light()
                        .surfaceContainerHigh
                        .withAlpha(200),
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

  Future<types.User?> _resolveUser(String id) async {
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
      setState(() {
        messageUser = user;
      });

      return user;
    } catch (error) {
      print("User not found in profiles table with id : "+id);
      // If any error occurs (e.g., profile not found), return an 'Unknown' user
      final unknownUser = types.User(id: id, name: 'Unknown');
      _userCache[id] = unknownUser; // Cache the unknown user too
      return unknownUser;
    }
  }

  void _handleTypingStatus() {
    // Determine the new typing state based on the text field's content.
    final bool isCurrentlyTyping = _chatTextController.text.isNotEmpty;

    // Only update the state if the new state is different from the old one.
    if (isCurrentlyTyping != _isTyping) {
      setState(() {
        _isTyping = isCurrentlyTyping;
      });

      // The logic for showing/hiding the mic is the inverse of the typing status.
      AppCubit.get(context).showHideMic(!isCurrentlyTyping);

      // Optional: A cleaner way to log the change.
      print(isCurrentlyTyping ? "User has started typing." : "User has stopped typing.");
    }
  }

  Widget chatWrapper (
      types.Message message ,
      int index ,
      String userNameString ,
      {String? fileId}
      ){
    return ChatMessageWrapper(
        messageId: message.id,
        controller:_reactionsController,
        config: const ChatReactionsConfig(
          // The default is EdgeInsets.all(20.0), which is too large.
          // Let's reduce it.
          dialogPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        ),
        onMenuItemTapped: (item){
          if(item.label == "Reply") {
            setState(() {
              _repliedMessage = message;
            });

          }
          if(item.isDestructive)
          {
            setState(() {
              _deleteMessage(message);
            });
          }
        },

        child: MessageWidget(
            message: message,
            controller: _reactionsController,
            messageIndex:index ,
            chatController: _chatController,
            userName :  userNameString,
            userCache: _userCache,
            fileId:fileId,

        ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: const Text("General Chat")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar:AppBar(
          title:Text("General Chat"),
      ),
      body: Stack(
        children: [
          Chat(
            chatController: _chatController,
            currentUserId: _userId,
            resolveUser: _resolveUser,
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

                    final user = _userCache[message.authorId];
                    final userNameString = user?.name ?? '...';
                    if (user == null) {
                      _resolveUser(message.authorId);
                    }


                    return VisibilityDetector(
                      key: Key(message.id),
                      onVisibilityChanged: (VisibilityInfo info) {
                        if (info.visibleFraction  >= 0.8 ) {

                          // Call a function to mark the message as seen
                         if(message.authorId != _userId) _markMessageAsSeen(message.id);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: isSentByMe?CrossAxisAlignment.start:CrossAxisAlignment.end,
                        children: [
                          chatWrapper(
                            message,
                            index,
                            userNameString,
                          ),
                          Avatar(userId: message.authorId)
                        ],
                      ),
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

          final user = _userCache[message.authorId];
          final userNameString = user?.name ?? '...';
          if (user == null) {
            _resolveUser(message.authorId);
          }
          return Stack(
            children: [
              VisibilityDetector(
                key: Key(message.id),
                onVisibilityChanged: (VisibilityInfo info) {
                  if (info.visibleFraction  >= 0.8 ) {

                    // Call a function to mark the message as seen
                    if(message.authorId != _userId) _markMessageAsSeen(message.id);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: isSentByMe?CrossAxisAlignment.start:CrossAxisAlignment.end,
                  children: [
                    chatWrapper(
                      message,
                      index,
                      userNameString,
                    ),
                    Avatar(userId: message.authorId)
                  ],
                ),
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


              imageMessageBuilder: (
                  context,
                  message,
                  index, {
                    required bool isSentByMe,
                    types.MessageGroupStatus? groupStatus,
                  }) {
                final bool isMe = message.authorId == supabase.auth.currentUser!.id?true:false;

                final user = _userCache[message.authorId];

                // Use the user's name if available, otherwise show a placeholder.
                final userNameString = user?.name ?? '...';

                // If the user wasn't in the cache, kick off a fetch.
                // This will update the cache and trigger a rebuild to show the correct name.
                if (user == null) {
                  _resolveUser(message.authorId);
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

                final fileId = extractDriveFileId((message).source);

                if (fileId == null) {
                  // Show an error icon if the URL is invalid
                  return const Center(child: Icon(Icons.error_outline, color: Colors.red));
                }

                // 2. Use a FutureBuilder to download and display the image
                return Stack(
                  children: [
                    VisibilityDetector(
                      key: Key(message.id),
                      onVisibilityChanged: (VisibilityInfo info) {
                        if (info.visibleFraction  >= 0.8 ) {

                          // Call a function to mark the message as seen
                          if(message.authorId != _userId) _markMessageAsSeen(message.id);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: isMe?CrossAxisAlignment.start:CrossAxisAlignment.end,
                        children: [
                          chatWrapper(
                            message,
                            index,
                            userNameString,
                            fileId: fileId
                          ),
                          Avatar(userId: message.authorId)
                        ],
                      ),
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
                        textEditingController: _chatTextController,
                        handleSafeArea: true,
                        sigmaX: 3,
                        sigmaY: 3,
                        sendButtonHidden:_chatTextController.text.isEmpty?true:false,

                      ),
                    );
                  }
                );
              }),


          ),
          //Used to render Replay toBar in case you click and hold the message
          Positioned(
              bottom: 65,
              left:MediaQuery.sizeOf(context).width*0.1,
              child: replyTopBar()),
        ],
      ),

    );
  }
}




Future fullScreenImageViewer (imageData , context) {
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
