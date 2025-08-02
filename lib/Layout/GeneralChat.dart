import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../Components/Constants.dart';
import '../Confg/supabase.dart';
import '../sevices/GoogleDriveService.dart';
import 'chatWidget/MessageWidget.dart';


final supabase = Supabase.instance.client;

class Generalchat extends StatefulWidget {
  const Generalchat({super.key});

  @override
  State<Generalchat> createState() => _GeneralchatState();
}

class _GeneralchatState extends State<Generalchat> {

  types.Message? _repliedMessage;
  late types.InMemoryChatController _chatController;
  late final ScrollController _scrollController;
  late final ReactionsController _reactionsController;

  final int _pageSize = 20;
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  final _currentUser = types.User(id: supabase.auth.currentUser!.id, name: UserData?.userMetadata?['display_name'].toString());
  String? _lastMessageId;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _chatController = types.InMemoryChatController();
    _scrollController = ScrollController();
    _reactionsController = ReactionsController(currentUserId: _currentUser.id);
    _loadMessages();
    _subscribeToRealtime();

    // Add this to try and sign in silently on start
    driveService.signInSilently().then((_) {
      if (driveService.currentUser != null) {
        setState(() {
          googleUser = driveService.currentUser;
        });
      }
    });

  }
  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? _extractDriveFileId(String url) {
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

  void _subscribeToRealtime() {
    _realtimeChannel = supabase
        .channel('public:messages')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        final newMessage = _mapToMessage(payload.newRecord);
        if (!_chatController.messages.any((m) => m.id == newMessage.id)) {

          _chatController.insertMessage(newMessage);
        }
      },
    )
        .subscribe();
  }

  void _markMessageAsSeen(String messageId) async {
    // We don't need to await this, it can run in the background.
    // Using upsert with 'ignoreDuplicates: true' is efficient.
    // It attempts an INSERT, and if it conflicts (violates the primary key), it does nothing.
    supabase.from('message_receipts').upsert({
      'message_id': messageId,
      'user_id': _currentUser.id,
      'seen_at': DateTime.now().toIso8601String(),
    }, onConflict: 'message_id, user_id'); // Use the primary key for conflict resolution
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
      }
    }
    setState(() => _isLoading = false);
  }


  types.Message _mapToMessage(Map<String, dynamic> map) {
    final seenAtTimestamp = map['latest_seen_at'] != null
        ? DateTime.parse(map['latest_seen_at'])
        : null;
    final messageType = map['type'];
    final author = types.User(id: map['author_id'] ?? 'unknown');

    switch (messageType) {
      case 'image':
        final metadata = map['metadata'] as Map<String, dynamic>?;
        return types.ImageMessage(
          createdAt: DateTime.parse(map['created_at']),
          id: map['id'],
          text:metadata?['name'] ?? 'Image',
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
          source: map['source'],
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
    final fileName = '${const Uuid().v4()}.${result.path.split('.').last}';
    // TODO: Consider showing a loading indicator to the user here

    // 2. Upload the file to Google Drive
    final driveLink = await driveService.uploadFile(file, fileName);

    if (driveLink != null) {

      final bytes = await file.readAsBytes();
      final image = await decodeImageFromList(bytes);

      // 4. Insert one message record with the Google Drive link
      await supabase.from('messages').insert({
        'id': const Uuid().v4(),
        'author_id': _currentUser.id,
        'uri': driveLink, // The link from Google Drive
        'type': 'image',
        'created_at': DateTime.now().toIso8601String(),
        'metadata': {
          'name': result.name, // Use the original file name for display
          'size': bytes.length,
          'height': image.height.toDouble(),
          'width': image.width.toDouble(),
        }
      });
    } else {
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
      'author_id': _currentUser.id,
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

    await supabase.from('messages').insert({
      'id': const Uuid().v4(),
      'author_id': _currentUser.id,
      'text': text,
      'type': 'text',
      'metadata': {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
          title:Text("General Chat"),
      ),
      body: Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children: [
          Chat(
            chatController: _chatController,
            currentUserId: supabase.auth.currentUser!.id,
            resolveUser: (id) async{
              return types.User(
                  id:id,
                  name: "John");
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
                            if (info.visibleFraction == 1 && !isSentByMe) {
                              // Call a function to mark the message as seen
                              _markMessageAsSeen(message.id);
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
                              child: MessageWidget(message: message,controller: _reactionsController,messageIndex:index , chatController: _chatController,)),
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
              chatAnimatedListBuilder: (context,itemBuilder){
                return ChatAnimatedList(
                  itemBuilder: itemBuilder,
                  onEndReached: _loadMessages,
                  scrollController: _scrollController,
                  initialScrollToEndMode:InitialScrollToEndMode.none,
                );
              },
              imageMessageBuilder: (
                  context,
                  message,
                  index, {
                    required bool isSentByMe,
                    types.MessageGroupStatus? groupStatus,
                  }) {
                // 1. Extract the file ID from the message's URI
                final fileId = _extractDriveFileId((message).source);

                if (fileId == null) {
                  // Show an error icon if the URL is invalid
                  return const Center(child: Icon(Icons.error_outline, color: Colors.red));
                }

                // 2. Use a FutureBuilder to download and display the image
                return DriveImageMessage(
                  fileId: fileId,
                  driveService: driveService, // Pass your drive service instance
                );
              },
            ),


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
