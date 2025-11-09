// GeneralChat.dart (Final Version with Placeholder and Polling Logic Restored)

import 'dart:async'; // <<< Added for Timer
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_polls/flutter_polls.dart';
import 'package:flyer_chat_system_message/flyer_chat_system_message.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase/supabase.dart';

import 'package:super_app/Layout/Cubit/cubit.dart';
import 'package:super_app/Layout/Cubit/states.dart';
import 'package:uuid/uuid.dart';
import 'package:ntp/ntp.dart';

import '../../../Components/Constants.dart';
import '../../../Confg/supabase.dart';
import '../../Cubit/ChatDetailsCubit/cubit.dart';
import '../BrainStorming.dart';
import '../Details/ChatDetails.dart';
import '../Details/ChatMember.dart';
import '../MessageWidget.dart';
import '../UploadProgressMessage.dart';
import 'ChatCacheService.dart';
import 'ChatService.dart';
import 'ReplyBar.dart';
import 'chat_mapper.dart';
import 'message_row_wrapper.dart';



class GeneralChat extends StatefulWidget {
  final int compoundId;
  const GeneralChat({super.key, required this.compoundId});

  @override
  State<GeneralChat> createState() => _GeneralChatState();
}

class _VisibleMessage {
  final int index;
  final double fraction;
  final DateTime? createdAt;
  _VisibleMessage(this.index, this.fraction, this.createdAt);
}

class _GeneralChatState extends State<GeneralChat> {
  // Services
  late final ChatService _chatService;
  late final ChatCacheService _cacheService;

  // State
  bool _isInitializing = true;

  int? _channelId;
  late final String _userId;
  List<types.Message> _messages = [];
  final Map<String, types.User> _userCache = {};
  final Map<String, double> _uploadProgress = {};
  types.Message? _repliedMessage;

  // Sticky header state
  DateTime? _stickyDate;
  final Map<String, _VisibleMessage> _visibleForHeader = {};

  // Controllers
  late final TextEditingController _chatTextController;
  late final types.InMemoryChatController _chatController;
  late final ReactionsController _reactionsController;
  AppCubit? _appCubit;

  // Realtime
  RealtimeChannel? _realtimeChannel;
  final Map<String, Timer> _pollingTimers = {}; // To manage polling timers

  // Pagination
  final int _pageSize = 20;
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(supabase);
    _cacheService = ChatCacheService();
    _chatController = types.InMemoryChatController();
    _chatTextController = TextEditingController();
    _chatTextController.addListener(_handleTypingStatus);
    _initializeChat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe place to read inherited widgets once (no listening)
    _appCubit ??= context.read<AppCubit>();
    // Attach once when cubit becomes available
    _appCubit!.attachChatController(_chatController);
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _pollingTimers.values.forEach((timer) => timer.cancel()); // Cancel all timers
    _chatController.dispose();
    if (_channelId != null) {
      _cacheService.saveMessages(_channelId!, _messages);
    }
    _appCubit?.detachChatController();
    _chatTextController.removeListener(_handleTypingStatus);
    _chatTextController.dispose();
    super.dispose();
  }

  void BrainStormingSwitch(){
    setState(() {
      isBrainStorming = !isBrainStorming;
    });
    AppCubit.get(context).showHideMicBrain();


  }

  void _addOrUpdateMessages(List<types.Message> newOrUpdatedMessages) {
    if (newOrUpdatedMessages.isEmpty) return;

    final messageMap = {for (var msg in _messages) msg.id: msg};
    for (final message in newOrUpdatedMessages) {
      messageMap[message.id] = message;
    }

    final sortedMessages = messageMap.values.toList();
    sortedMessages.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aDate.compareTo(bDate); // Sort ascending (oldest first)
    });

    if (mounted) {
      setState(() {
        _messages = sortedMessages;
      });
      // Sync _chatController with minimal changes to avoid clearing animations/flips.
      // If the controller is empty (first load), it's cheaper and less error-prone to insert all.
      if (_chatController.messages.isEmpty) {
        _chatController.insertAllMessages(sortedMessages);
      } else {
        _syncControllerWithMessages(sortedMessages);
      }
    }
  }

  /// Applies minimal diffs to the InMemoryChatController to avoid UI flip / jump.
  void _syncControllerWithMessages(List<types.Message> sortedMessages) {
    // Snapshot of current controller messages
    final existing = List<types.Message>.from(_chatController.messages);
    final existingById = {for (var m in existing) m.id: m};

    final newIds = sortedMessages.map((m) => m.id).toSet();
    final existingIds = existingById.keys.toSet();

    // 1. Remove messages that are no longer present
    final toRemove = existingIds.difference(newIds);
    for (final id in toRemove) {
      final msg = existingById[id];
      if (msg != null) {
        try {
          _chatController.removeMessage(msg);
        } catch (_) {
          // ignore individual failures to avoid breaking updates
        }
      }
    }
    // 2. Update existing messages and insert new ones in the correct order
    // We'll iterate sortedMessages (chronological) and ensure the controller has them.
    for (final msg in sortedMessages) {
      final existingMsg = existingById[msg.id];
      if (existingMsg != null) {
        // Compare by id; if metadata or other fields changed, update
        if (existingMsg != msg) {
          try {
            _chatController.updateMessage(existingMsg,msg);
          } catch (_) {
            // ignore update failure
          }
        }
      } else {
        // New message: insert
        try {
          _chatController.insertMessage(msg);
        } catch (_) {
          // ignore insert failure
        }
      }
    }
  }

  Future<void> _initializeChat() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isInitializing = false);
      return;
    }
    setState(() {
      _userId = userId;
      _reactionsController = ReactionsController(currentUserId: _userId);
    });
    try {
      final response = await supabase
          .from('channels')
          .select('id')
          .eq('compound_id', widget.compoundId)
          .eq('type', 'COMPOUND_GENERAL')
          .single();
      _channelId = response['id'];
      await _loadMessagesFromCacheAndFetchLatest();
      _subscribeToRealtime();
    } catch (error) {
      debugPrint('Error fetching channel ID: $error');
    }
    if (mounted) setState(() => _isInitializing = false);
  }

  Future<void> _loadMessagesFromCacheAndFetchLatest() async {
    final cachedMessages = await _cacheService.loadMessages(_channelId!);
    _addOrUpdateMessages(cachedMessages);
    await _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    final freshMessages = await _chatService.fetchMessages(
      channelId: _channelId!,
      currentUserId: _userId,
      pageSize: _pageSize,
      pageNum: _currentPage,
    );
    if (freshMessages.isEmpty) {
      setState(() => _hasMore = false);
    } else {
      _addOrUpdateMessages(freshMessages);
      _currentPage++;
    }
    setState(() => _isLoading = false);
  }

  void _subscribeToRealtime() {
    _realtimeChannel = _chatService.subscribeToChannel(
      channelId: _channelId!,
      onInsert: (payload) {
        final newMessage = mapToMessage(payload);
        final localId = newMessage.metadata?['localId'];

        if (localId != null) {
          final updatedList = _messages.where((m) => m.id != localId).toList();
          setState(() {
            _messages = updatedList;
          });
        }

        _addOrUpdateMessages([newMessage]);

        if (newMessage is types.AudioMessage && newMessage.metadata?['status'] == 'processing') {
          _startPollingForMessage(newMessage);
        }
      },
      onUpdate: (payload) {
        _addOrUpdateMessages([mapToMessage(payload)]);
      },
    );
  }

  void _startPollingForMessage(types.AudioMessage  message) {
    _pollingTimers[message.id]?.cancel();
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

  Future<bool> _checkUrlIsReady(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> _resolveUser(String id) async {
    if (_userCache.containsKey(id)) return;
    final user = await _chatService.resolveUser(id);
    if(mounted) {
      setState(() {
        _userCache[id] = user;
      });
    }
  }

  void _handleSendPressed(String text) {
    _chatService.sendTextMessage(
      text: text,
      channelId: _channelId!,
      userId: _userId,
      repliedMessage: _repliedMessage,
    );
    setState(() => _repliedMessage = null);
  }

  void _handleTypingStatus() {
    AppCubit.get(context).showHideMic(_chatTextController.text.isEmpty);
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
      isScrollControlled:true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black12,
      builder: (BuildContext context) {
        final width = MediaQuery.of(context).size.width;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: ()=>Navigator.pop(context),
          child: SafeArea(
            bottom: true,
            maintainBottomViewPadding : true,
          child: Stack(

            children: [
              Positioned(
                left:0,
                bottom: MediaQuery.of(context).padding.bottom+110,
                child: Padding(
                  padding: const EdgeInsets.only(left:12 , bottom: 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: width*0.5),
                    child: Material(
                      elevation: 0,
                      color:Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(
                        10
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children:[
                          ListTile(
                            leading: const Icon(Icons.image_outlined),
                            title:Text('Photo'),
                            onTap: (){
                              Navigator.pop(context);
                              _handleImageSelection();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.attach_file),
                            title: const Text('File'),
                            onTap: () {
                              Navigator.pop(context);
                              _handleFileSelection();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.how_to_vote_outlined),
                            title: const Text('Poll'),
                            onTap: () {
                              Navigator.pop(context);
                              _showPollComposer();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
                ),
        );
      },
    );
  }

  Future<void> _showPollComposer() async {
    final questionController = TextEditingController();
    final optionControllers = <TextEditingController>[
      TextEditingController(),
      TextEditingController(),
    ];
    int durationDays = 1;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create Poll'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: questionController,
                    decoration: const InputDecoration(labelText: 'Question'),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(optionControllers.length, (i) {
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: optionControllers[i],
                            decoration: InputDecoration(labelText: 'Option ${i + 1}'),
                          ),
                        ),
                        if (optionControllers.length > 2)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              setState(() {
                                optionControllers.removeAt(i).dispose();
                              });
                            },
                          ),
                      ],
                    );
                  }),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add option'),
                        onPressed: optionControllers.length >= 6
                            ? null
                            : () {
                          setState(() {
                            optionControllers.add(TextEditingController());
                          });
                        },
                      ),
                      const Spacer(),
                      DropdownButton<int>(
                        value: durationDays,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1 day')),
                          DropdownMenuItem(value: 7, child: Text('1 week')),
                          DropdownMenuItem(value: 30, child: Text('30 days')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => durationDays = v);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final question = questionController.text.trim();
                  final optionsList = <Map<String, dynamic>>[];
                  for (final controller in optionControllers) {
                    final title = controller.text.trim();
                    if (title.isEmpty) continue;
                    optionsList.add({
                      'id': optionsList.length, // contiguous index among non-empty options
                      'title': title,
                      'votes': 0,
                    });
                  }
                  if (question.isEmpty || optionsList.length < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a question and at least 2 options')),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  final expiresAt = (await NTP.now()).toUtc().add(Duration(days: durationDays));
                  await _createPollMessage(question, optionsList, expiresAt);
                  // dispose controllers
                  questionController.dispose();
                  for (var c in optionControllers) c.dispose();
                },
                child: const Text('Create'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _createPollMessage(String question, List<Map<String, dynamic>> options, DateTime expiresAt) async {
    final localId = const Uuid().v4();
    final now = await NTP.now();
    final nowUtc = now.toUtc();

    // Build metadata with poll structure. Votes map is empty initially.
    final pollMeta = {
      'type': 'poll',
      'localId': localId,
      'question': question,
      'options': options,
      'votes': {}, // e.g. { "optionIndex": { "userId": true } } — backend will manage actual votes
      'expiresAt': expiresAt.toIso8601String(),
      'createdAtMs': nowUtc.millisecondsSinceEpoch,
    };

    // Insert a local placeholder so UI shows instantly
    final placeholder = types.TextMessage(
      id: localId, // stable local id so matching works
      authorId: _userId,
      createdAt: now,
      text: question, // visible immediately
      metadata: pollMeta,
    );

    try {
      _chatController.insertMessage(placeholder);

      // Persist to Supabase
      await supabase.from('messages').insert({
        'id': const Uuid().v4(),
        'author_id': _userId,
        'created_at': nowUtc.toIso8601String(),
        'channel_id': _channelId,
        'metadata': pollMeta,
      });
      // Realtime subscription will deliver the canonical message and you may remove/replace placeholder there
    } catch (e) {
      // cleanup placeholder
      try {
        _chatController.removeMessage(placeholder);
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create poll: $e')),
        );
      }
    }
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
    final now = (await NTP.now()).toUtc();
    // Insert message record
    await supabase.from('messages').insert({
      'id': const Uuid().v4(),
      'author_id':UserData!.id,
      'uri': fileUrl,
      'type': 'file',
      'created_at': now.toIso8601String(),
      'channel_id': _channelId,
      'metadata': {
        'name': file.name,
        'size': file.size,
        'mimeType': lookupMimeType(file.path!),
        'created_at_ms': now.millisecondsSinceEpoch,
      }
    });
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
      final now = (await NTP.now()).toUtc();
      // 4. Insert one message record with the Google Drive link
      await supabase.from('messages').insert({
        'id': const Uuid().v4(),
        'author_id': _userId,
        'uri': driveLink, // The link from Google Drive
        'created_at': now.toIso8601String(), // Use NTP UTC time
        'channel_id': _channelId,
        'metadata': {
          'type': 'image',
          'localId': localId, // **IMPORTANT** link to the placeholder
          'name': result.name, // Use the original file name for display
          'size': bytes.length,
          'height': image.height.toDouble(),
          'width': image.width.toDouble(),
          'createdAtMs': now.millisecondsSinceEpoch,
        }
      });
    } else {
      // Handle failure: maybe update the placeholder to show a "failed" state
      debugPrint('Upload failed for local message ID: $localId');
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

  void _onVisibilityForHeader(
      String messageId,
      int index,
      double visibleFraction,
      DateTime? createdAt,
      ) {
    if (visibleFraction <= 0) {
      _visibleForHeader.remove(messageId);
    } else {
      _visibleForHeader[messageId] = _VisibleMessage(index, visibleFraction, createdAt);
    }

    if (_visibleForHeader.isEmpty) return;

    // Consider items that are at least 5% visible to avoid flicker
    final candidates = _visibleForHeader.entries
        .where((e) => e.value.fraction > 0.05)
        .toList();

    if (candidates.isEmpty) return;

    candidates.sort((a, b) => a.value.index.compareTo(b.value.index));
    final DateTime? top = candidates.first.value.createdAt;
    if (top == null) return;

    // Normalize by day to avoid redundant rebuilds
    final currentNorm = _stickyDate == null
        ? null
        : DateTime(_stickyDate!.year, _stickyDate!.month, _stickyDate!.day);
    final nextNorm = DateTime(top.year, top.month, top.day);

    if (currentNorm != nextNorm && mounted) {
      setState(() => _stickyDate = top);
    }
  }

  String _formatDayLabel(DateTime d) {
    final today = DateTime.now();
    final a = DateTime(today.year, today.month, today.day);
    final b = DateTime(d.year, d.month, d.day);
    final diff = b.difference(a).inDays;
    if (diff == 0) return 'Today';
    if (diff == -1) return 'Yesterday';
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Widget _buildStickyDateHeader() {
    if (_stickyDate == null) return const SizedBox.shrink();
    final label = _formatDayLabel(_stickyDate!.toLocal());
    return IgnorePointer(
      ignoring: true, // let touches through to the list
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _messageBuilder(BuildContext context, types.Message message, int index, {required bool isSentByMe}) {
    String? fileId;
    if (message is types.ImageMessage) {
      fileId = extractDriveFileId(message.source);
    }
    final messagesList = List<types.Message>.from(_chatController.messages);
    final controllerIndex = messagesList.indexWhere((m) => m.id == message.id);
    final bool isPreviousMessageFromSameUser =
        controllerIndex > 0 &&
        controllerIndex < messagesList.length &&
        messagesList[controllerIndex-1].authorId== message.authorId;

    return MessageRowWrapper(
      message: message,
      index: index,
      isSentByMe: isSentByMe,
      isPreviousMessageFromSameUser: isPreviousMessageFromSameUser,
      fileId: fileId,
      reactionsController: _reactionsController,
      onReply: (msg) => setState(() => _repliedMessage = msg),
      onDelete: (msg) => _chatService.deleteMessage(msg.id),
      onMessageVisible: (msgId) => _chatService.markMessageAsSeen(msgId, _userId),
      chatController: _chatController,
      userCache: _userCache,
      resolveUser: _resolveUser,
      onVisibilityForHeader: (messageId, itemIndex, fraction, createdAt) {
        _onVisibilityForHeader(messageId, itemIndex, fraction, createdAt);
      },
      localMessages: _messages,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: const Text("General Chat")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

   if(isBrainStorming ==false){
     return Scaffold(
       appBar: AppBar(
         title: MaterialButton(
             onPressed: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(
                   builder: (context) => BlocProvider(
                     create:(context) => ChatDetailsCubit(),
                     child: ChatDetails(
                       compoundId: widget.compoundId,
                     ),
                   ),
                 ),
               );
             },

             child: const Text("General Chat")),
         actions:[IconButton(onPressed: () {
           BrainStormingSwitch();
         }, icon: Icon(Icons.analytics_outlined),)],

       ),

       body: Stack(
         children: [
           Chat(
             chatController: _chatController,
             currentUserId: _userId,
             onMessageSend: (text) => _handleSendPressed(text),
             onAttachmentTap: _handleAttachmentPressed,
             resolveUser: (id) async {
               await _resolveUser(id);
               return _userCache[id];
             },
             builders: types.Builders(
               textMessageBuilder: (context, message, index, {required bool isSentByMe, groupStatus}) =>
                   _messageBuilder(context, message, index, isSentByMe: isSentByMe),
               imageMessageBuilder: (context, message, index, {required bool isSentByMe, groupStatus}) =>
                   _messageBuilder(context, message, index, isSentByMe: isSentByMe),
               audioMessageBuilder: (context, message, index, {required bool isSentByMe, groupStatus}) =>
                   _messageBuilder(context, message, index, isSentByMe: isSentByMe),
               customMessageBuilder: (context, message, index, {required bool isSentByMe, groupStatus})=>
                   _messageBuilder(context, message, index, isSentByMe: isSentByMe),
               systemMessageBuilder: (context, message, index, {
                 required bool isSentByMe,
                 types.MessageGroupStatus? groupStatus,
               }) => FlyerChatSystemMessage(message: message, index: index),

               chatAnimatedListBuilder: (context, itemBuilder) => ChatAnimatedList(
                 itemBuilder: itemBuilder,
                 initialScrollToEndMode: InitialScrollToEndMode.none,
               ),
               composerBuilder: (context) {
                 return BlocBuilder<AppCubit, AppCubitStates>(
                     buildWhen: (previous, current) => current is ShowHideMicStates,
                     builder: (context, state) {
                       return Visibility(
                         visible: !AppCubit.get(context).isRecording,
                         child: Composer(
                           gap: 0,
                           sendIcon: Icon(Icons.send),
                           textEditingController: _chatTextController,
                           handleSafeArea: true,
                           sigmaX: 3,
                           sigmaY: 3,
                           sendButtonHidden: AppCubit.get(context).isChatInputEmpty,
                         ),
                       );
                     });
               },
             ),
           ),
           // sticky date header overlay
           Positioned(
             top: 0,
             left: 0,
             right: 0,
             child: _buildStickyDateHeader(),
           ),

           if (_repliedMessage != null)
             Positioned(
               bottom: 65,
               left: MediaQuery.of(context).size.width * 0.1,
               child: ReplyBar(
                 repliedMessage: _repliedMessage!,
                 onCancel: () => setState(() => _repliedMessage = null),
               ),
             ),
         ],
       ),
     );
   } else {
     return BrainStorming(
       onClose: (){
         BrainStormingSwitch();
       },
     );
   }
  }
}



