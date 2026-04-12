// GeneralChat.dart (Final Version with Placeholder and Polling Logic Restored)

import 'dart:async'; // <<< Added for Timer
import 'dart:io';

import 'package:WhatsUnity/features/social/presentation/bloc/social_cubit.dart';
import 'package:WhatsUnity/features/social/presentation/bloc/social_state.dart';
import 'package:condition_builder/condition_builder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart' as http;

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:WhatsUnity/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:WhatsUnity/features/auth/presentation/bloc/auth_state.dart';
import 'package:WhatsUnity/features/chat/data/datasources/chat_local_data_source.dart';
import 'package:WhatsUnity/features/chat/presentation/bloc/chat_details_cubit.dart';
import 'package:WhatsUnity/core/config/supabase.dart';
import 'package:WhatsUnity/core/config/Enums.dart';
import 'package:WhatsUnity/core/constants/Constants.dart';
import 'package:WhatsUnity/features/chat/presentation/bloc/chat_cubit.dart';
import 'package:WhatsUnity/features/chat/presentation/bloc/chat_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mime/mime.dart';

import 'package:WhatsUnity/Layout/Cubit/cubit.dart';
import 'package:WhatsUnity/Layout/Cubit/states.dart';

import 'package:uuid/uuid.dart';
import 'package:ntp/ntp.dart';


import 'package:WhatsUnity/features/chat/presentation/widgets/chatWidget/BrainStorming.dart';
import 'package:WhatsUnity/features/chat/presentation/widgets/chatWidget/Details/ChatMember.dart';
import 'package:WhatsUnity/features/chat/presentation/widgets/chatWidget/Details/ChatDetails.dart';
import 'package:WhatsUnity/features/chat/presentation/widgets/chatWidget/MessageWidget.dart';
import 'ChatCacheService.dart';
import 'ReplyBar.dart';
import 'message_row_wrapper.dart';



class GeneralChat extends StatefulWidget {
  final int compoundId;
  final String channelName;
  const GeneralChat({super.key, required this.compoundId , required this.channelName});

  @override
  State<GeneralChat> createState() => _GeneralChatState();
}

class _VisibleMessage {
  final int index;
  final double fraction;
  final DateTime? createdAt;
  _VisibleMessage(this.index, this.fraction, this.createdAt);
}

class _GeneralChatState extends State<GeneralChat> with AutomaticKeepAliveClientMixin {
  // Services
  ChatCacheService? _cacheService;
  @override
  bool get wantKeepAlive => true;
  // State
  bool _isInitializing = true;
  bool _isUserScrolling = false;
  Timer? _scrollIdleTimer;
  bool _didInitialAutoScroll = false;
  int? channelId;


  double _stickyOpacity = 0.0;


  late String _userId;
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
  final Map<String, Timer> _pollingTimers = {}; // To manage polling timers

  // Pagination
  final int _pageSize = 20;
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  void _handleTypingStatus() {
    context.read<ChatCubit>().showHideMic(_chatTextController.text.isEmpty);
  }

  static int _compareCreatedAtAsc(types.Message a, types.Message b) {
    final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final c = at.compareTo(bt);
    if (c != 0) return c;
    return a.id.compareTo(b.id);
  }

  static List<types.Message> _sortedAsc(Iterable<types.Message> items) {
    final list = List<types.Message>.from(items);
    list.sort(_compareCreatedAtAsc);
    return list;
  }

  /// Merges server-backed cubit messages with controller-only rows (e.g. upload placeholders).
  Future<void> _applyCubitMessagesToController(List<types.Message> cubitMessages) async {
    final cubitIds = cubitMessages.map((m) => m.id).toSet();
    final onlyOnDevice = _chatController.messages
        .where((m) => !cubitIds.contains(m.id))
        .toList();
    final merged = _sortedAsc([...cubitMessages, ...onlyOnDevice]);
    await _chatController.setMessages(merged);
  }

  @override
  void initState() {
    super.initState();
    _chatController = types.InMemoryChatController();
    _chatTextController = TextEditingController();
    _chatTextController.addListener(_handleTypingStatus);
    _initializeChat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cacheService ??= ChatCacheService(context.read<ChatLocalDataSource>());
    // Safe place to read inherited widgets once (no listening)
    _appCubit ??= context.read<AppCubit>();
    // Attach once when cubit becomes available
    _appCubit!.attachChatController(_chatController);
  }

  @override
  void dispose() {
    for (var timer in _pollingTimers.values) {
      timer.cancel();
    }
    _chatController.dispose();
    if (channelId != null) {
      _cacheService?.saveMessages(channelId!, _chatController.messages);
    }
    _appCubit?.detachChatController();
    _chatTextController.removeListener(_handleTypingStatus);
    _chatTextController.dispose();
    _scrollIdleTimer?.cancel();

    super.dispose();
  }

  void brainStormingSwitch(){
    context.read<ChatCubit>().toggleBrainStorming();
  }

  bool _onScrollNotification(ScrollNotification n) {
    if (n is ScrollUpdateNotification || n is UserScrollNotification) {
      if (!_isUserScrolling) {
        setState(() => _isUserScrolling = true);
      }
      if (_stickyOpacity != 1.0) {
        setState(() => _stickyOpacity = 1.0);
      }
      _scrollIdleTimer?.cancel();
      _scrollIdleTimer = Timer(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isUserScrolling = false;
            _stickyOpacity = 0.0; // triggers fade out
          });
        }
      });
    }
    return false; // allow other listeners
  }

  Future<void> _syncChatFromCubit(ChatMessagesLoaded loaded) async {
    for (final message in loaded.messages) {
      if (message is types.AudioMessage &&
          message.metadata?['status'] == 'processing') {
        _startPollingForMessage(message);
      }
    }

    await _applyCubitMessagesToController(loaded.messages);

    final localIdsToRemove = <String>[];
    for (final message in loaded.messages) {
      final localId = message.metadata?['localId'];
      if (localId != null && message.id != localId) {
        localIdsToRemove.add(localId);
      }
    }

    for (final id in localIdsToRemove) {
      try {
        final messageToRemove =
            _chatController.messages.firstWhere((m) => m.id == id);
        await _chatController.removeMessage(messageToRemove);
      } catch (_) {}
    }
  }


  Future<void> _handleSendPressed(String text) async {
    if (channelId == null) return;
    await context.read<ChatCubit>().sendMessage(
      text: text,
      channelId: channelId!,
      userId: _userId,
      repliedMessage: _repliedMessage,
    );
    setState(() => _repliedMessage = null);
  }

  void _handleAttachmentPressed() {
    final authState = context.read<AuthCubit>().state;
    final googleUser = (authState is Authenticated) ? authState.googleUser : null;
    if (googleUser == null) {
      // Prompt user to sign in if they haven't already
      // AuthCubit.get(context).googleSignin();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('looks like you arent signed in with google account we will try to log you in first.')),
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result == null || result.files.single.path == null) return;

    final file = result.files.single;

    await context.read<ChatCubit>().sendFileMessage(
      uri: file.path!,
      name: file.name,
      size: file.size,
      channelId: channelId!,
      userId: _userId,
      type: 'file',
      additionalMetadata: {
        'mimeType': lookupMimeType(file.path!),
      },
    );
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

      await context.read<ChatCubit>().sendFileMessage(
        uri: driveLink,
        name: result.name,
        size: bytes.length,
        channelId: channelId!,
        userId: _userId,
        type: 'image',
        additionalMetadata: {
          'height': image.height.toDouble(),
          'width': image.width.toDouble(),
          'localId': localId,
        },
      );
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

    if (_visibleForHeader.isEmpty) {
      if (mounted) setState(() => _stickyDate = null);
      return;
    }

    // Find message with largest index (latest/top) among those visible
    var latestIndex = -1;
    DateTime? bestDate;
    for (var vm in _visibleForHeader.values) {
      if (vm.index > latestIndex) {
        latestIndex = vm.index;
        bestDate = vm.createdAt;
      }
    }
    if (mounted && bestDate != _stickyDate) {
      setState(() => _stickyDate = bestDate);
    }
  }

  Widget _buildStickyDateHeader() {
    if (_stickyDate == null) return const SizedBox.shrink();

    final dateStr = formatMessageDate(_stickyDate!);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _stickyOpacity,
      child: Center(
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateStr,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _messageBuilder(BuildContext context, types.Message message, int index,
      {required bool isSentByMe}) {
    // Determine the user from cache or trigger resolution
    final author = _userCache[message.authorId];
    if (author == null) {
      _resolveUser(message.authorId);
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return const SizedBox.shrink();

    return MessageRowWrapper(
      message: message,
      index: index,
      isSentByMe: isSentByMe,
      reactionsController: _reactionsController,
      onReply: (m) => setState(() => _repliedMessage = m),
      onDelete: (m) => context.read<ChatCubit>().deleteMessage(m),
      onMessageVisible: (id) => context.read<ChatCubit>().markAsSeen(id, _userId),
      chatController: _chatController,
      isPreviousMessageFromSameUser: index > 0 &&
          _chatController.messages[index - 1].authorId == message.authorId,
      userCache: _userCache,
      resolveUser: _resolveUser,
      onVisibilityForHeader: _onVisibilityForHeader,
      localMessages: _chatController.messages,
      showDateHeaders: true,
      currentUserId: _userId,
      isUserScrolling: _isUserScrolling,
      chatMembers: authState.chatMembers,
      userRole: authState.role,
      uploadProgress: _uploadProgress[message.id],
    );
  }

  Future<void> _handlePollVote(String messageId, int optionIndex) async {
    // 1. Get the current message from state or controller
    final msg = _chatController.messages
        .firstWhere((m) => m.id == messageId);
    final metadata = Map<String, dynamic>.from(msg.metadata ?? {});
    final votes = Map<String, dynamic>.from(metadata['votes'] ?? {});

    // 2. Logic: User can only have one vote per poll
    // Remove their ID from all options first if they already voted
    votes.forEach((key, value) {
       if (value is Map) {
         value.remove(_userId);
       }
    });

    // 3. Add vote to the new option
    final optionKey = optionIndex.toString();
    votes[optionKey] ??= {};
    votes[optionKey][_userId] = true;

    // 4. Update locally and remotely
    metadata['votes'] = votes;
    final updatedMsg = (msg as types.TextMessage).copyWith(metadata: metadata);
    _chatController.updateMessage(msg, updatedMsg);

    await supabase.from('messages').update({'metadata': metadata}).eq('id', messageId);
  }


  Future<void> _resolveUser(String id) async {
    if (_userCache.containsKey(id)) return;
    try {
      final user = await context.read<ChatCubit>().resolveUser(id);
      if (mounted) {
        setState(() {
          _userCache[id] = user;
        });
      }
    } catch (e) {
      debugPrint('Error resolving user $id: $e');
    }
  }

  Future<void> _waitForCurrentUserMember(String userId, List<ChatMember> chatMembers,
      {Duration timeout = const Duration(seconds: 5)}) async {
    final start = DateTime.now();
    while (mounted) {
      final hasMember = chatMembers.any((m) => m.id.trim() == userId);
      if (hasMember) return;
      if (DateTime.now().difference(start) > timeout) {
        debugPrint('Timeout waiting for ChatMembers; proceeding without building filter.');
        return;
      }
      await Future.delayed(const Duration(milliseconds: 60));
    }
  }

  Future<void> _initializeChat() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      if (mounted) setState(() => _isInitializing = false);
      return;
    }

    final userId = authState.user.id;
    setState(() {
      _userId = userId;
      _reactionsController = ReactionsController(currentUserId: _userId);
    });
    try {
      if (widget.channelName != 'COMPOUND_GENERAL') {
        await _waitForCurrentUserMember(userId, authState.chatMembers);
      }
      final hasMember = authState.chatMembers.any((member) => member.id.trim() == userId);
      final ChatMember? member =
      hasMember ? authState.chatMembers.firstWhere((member) => member.id.trim() == userId) : null;
      final buildingNo = member?.building;
      debugPrint(buildingNo);

      var query = supabase
            .from('channels')
            .select('id')
            .eq('compound_id', widget.compoundId)
            .eq('type', widget.channelName);

      if (widget.channelName != 'COMPOUND_GENERAL' && buildingNo != null) {
        final buildingId = await supabase.from("buildings").select("id").eq("building_name", buildingNo).eq("compound_id",widget.compoundId).single();
        debugPrint("buildingId${buildingId['id']}");
        query = query.eq('building_id', buildingId['id']);
      }

      final response = await query.single();


      channelId = response['id'] as int?;

      if (channelId != null) {
        final chatCubit = context.read<ChatCubit>();
        chatCubit.channelId = channelId;
        chatCubit.initChat(channelId: channelId!, currentUserId: _userId);
        chatCubit.showHideMic(_chatTextController.text.isEmpty);
      } else {
        debugPrint('Channel ID not found.');
      }
    } catch (error) {
      debugPrint('Error fetching channel ID: $error');
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _loadMessages() async {
    context.read<ChatCubit>().loadMoreMessages(channelId: channelId!, currentUserId: _userId);
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

  void _showCreatePollDialog() {
    final questionController = TextEditingController();
    final List<TextEditingController> optionControllers = [
      TextEditingController(),
      TextEditingController(),
    ];
    int durationDays = 1;

    showDialog(
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
                  const SizedBox(height: 16),
                  ...List.generate(optionControllers.length, (index) {
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: optionControllers[index],
                            decoration: InputDecoration(labelText: 'Option ${index + 1}'),
                          ),
                        ),
                        if (optionControllers.length > 2)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              setState(() {
                                optionControllers.removeAt(index).dispose();
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
                  for (var c in optionControllers) {
                    c.dispose();
                  }
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
    _chatController.insertMessage(placeholder);

    await supabase.from('messages').insert({
      'channel_id': channelId,
      'author_id': _userId,
      'text': question,
      'metadata': pollMeta,
      'created_at': nowUtc.toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authState = context.watch<AuthCubit>().state;
    if (authState is! Authenticated) {
      return const Center(child: CircularProgressIndicator());
    }
    final currentUserMember = authState.chatMembers.firstWhere((member) => member.id.trim() == authState.user.id, orElse: () => ChatMember(id: authState.user.id, displayName: "Unknown", building: "Unknown", apartment: "Unknown", userState: UserState.approved, phoneNumber: "", ownerType: OwnerTypes.owner));


    return BlocListener<ChatCubit, ChatState>(
      listenWhen: (previous, current) {
        if (current is! ChatMessagesLoaded) return false;
        if (previous is! ChatMessagesLoaded) return true;
        return !identical(previous.messages, current.messages);
      },
      listener: (context, state) {
        unawaited(_syncChatFromCubit(state as ChatMessagesLoaded));
      },
      child: BlocBuilder<ChatCubit, ChatState>(
        buildWhen: (previous, current) {
          if (previous is ChatMessagesLoaded && current is ChatMessagesLoaded) {
            return previous.isBrainStorming != current.isBrainStorming;
          }
          return previous.runtimeType != current.runtimeType;
        },
        builder: (context, state) {
          return BlocBuilder<SocialCubit, SocialState>(
            builder: (context, socialState) {
              final chatCubit = context.read<ChatCubit>();
              final bool isBrainStormingLocal = (state is ChatMessagesLoaded)
                  ? state.isBrainStorming
                  : chatCubit.isBrainStorming;
              if (_isInitializing) {
                return Scaffold(
                  appBar: AppBar(
                    title: MaterialButton(
                        onPressed: () {},
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 10,
                          children: [
                            Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                    color: Colors.white70,
                                    shape: BoxShape.circle
                                ),
                                child: ClipOval(child: getCompoundPicture(context, widget.compoundId, 38))
                            ),
                            const Text("General Chat"),
                          ],
                        )),
                    actions: [IconButton(onPressed: () {
                      context.read<SocialCubit>().getBrainStorms(channelId!, widget.compoundId);
                      brainStormingSwitch();
                    }, icon: const Icon(Icons.analytics_outlined),
                    )],

                  ),
                  body: const Center(child: CircularProgressIndicator()),
                );
              }


              return ConditionBuilder<dynamic>.on(
                    () => currentUserMember.userState == UserState.banned,
                    () =>
                    Scaffold(
                      appBar: AppBar(),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.no_accounts,
                              color: Colors.redAccent,
                              size: 100,
                            ),
                            const SizedBox(height: 60),
                            SizedBox(
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.8,
                              child: const Text(
                                "Your account has been banned . For breaking Community Rules.",
                                style: TextStyle(fontSize: 16, color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              )
                  .on(
                    () => currentUserMember.userState == UserState.chatBanned,
                    () =>
                    Scaffold(
                      appBar: AppBar(),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Symbols.chat_error,
                              color: Colors.redAccent,
                              size: 100,
                            ),
                            const SizedBox(height: 60),
                            SizedBox(
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.8,
                              child: const Text(
                                "Your account has been banned . For breaking Community Rules.",
                                style: TextStyle(fontSize: 16, color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              )
                  .build(orElse: () {
                if (isBrainStormingLocal == false) {
                  return Scaffold(
                    resizeToAvoidBottomInset: true,
                    appBar: AppBar(
                      title: MaterialButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BlocProvider(
                                      create: (context) => ChatDetailsCubit(authCubit: context.read<AuthCubit>()),
                                      child: ChatDetails(
                                        compoundId: widget.compoundId,
                                      ),
                                    ),
                            ),
                            );
                          },

                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 10,
                            children: [
                              Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                      color: Colors.white70,
                                      shape: BoxShape.circle
                                  ),
                                  child: ClipOval(child: getCompoundPicture(context, widget.compoundId, 38))
                              ),
                              const Text("General Chat"),
                            ],
                          )),
                      actions: [IconButton(onPressed: () {
                        context.read<SocialCubit>().getBrainStorms(channelId!, widget.compoundId);
                        brainStormingSwitch();
                      }, icon: const Icon(Icons.analytics_outlined),
                      )],

                    ),

                    body: Stack(
                            fit: StackFit.expand,
                            children: [
                              Positioned.fill(
                                child: NotificationListener<ScrollNotification>(
                                  onNotification: _onScrollNotification,
                                  child: Chat(
                                    chatController: _chatController,
                                    currentUserId: _userId,
                                    onMessageSend: (text) => _handleSendPressed(text),
                                    onAttachmentTap: _handleAttachmentPressed,
                                    resolveUser: (id) async {
                                      await _resolveUser(id);
                                      return _userCache[id];
                                    },
                                    builders: types.Builders(
                                      textMessageBuilder: (context, message, index,
                                          {required bool isSentByMe, groupStatus}) =>
                                          _messageBuilder(context, message, index,
                                              isSentByMe: isSentByMe),
                                      imageMessageBuilder: (context, message, index,
                                          {required bool isSentByMe, groupStatus}) =>
                                          _messageBuilder(context, message, index,
                                              isSentByMe: isSentByMe),
                                      audioMessageBuilder: (context, message, index,
                                          {required bool isSentByMe, groupStatus}) =>
                                          _messageBuilder(context, message, index,
                                              isSentByMe: isSentByMe),
                                      customMessageBuilder: (context, message, index,
                                          {required bool isSentByMe, groupStatus}) =>
                                          _messageBuilder(context, message, index,
                                              isSentByMe: isSentByMe),

                                      chatAnimatedListBuilder: (context, itemBuilder) =>
                                          ChatAnimatedList(
                                            itemBuilder: itemBuilder,
                                            initialScrollToEndMode:
                                                InitialScrollToEndMode.jump,
                                          ),
                                      composerBuilder: (context) {
                                        return BlocBuilder<ChatCubit, ChatState>(
                                            buildWhen: (p, c) {
                                              if (p is ChatMessagesLoaded &&
                                                  c is ChatMessagesLoaded) {
                                                return p.isRecording !=
                                                        c.isRecording ||
                                                    p.isChatInputEmpty !=
                                                        c.isChatInputEmpty;
                                              }
                                              return true;
                                            },
                                            builder: (context, state) {
                                              final isRecording =
                                                  (state is ChatMessagesLoaded)
                                                      ? state.isRecording
                                                      : context
                                                          .read<ChatCubit>()
                                                          .isRecording;
                                              final isChatInputEmpty =
                                                  (state is ChatMessagesLoaded)
                                                      ? state.isChatInputEmpty
                                                      : context
                                                          .read<ChatCubit>()
                                                          .isChatInputEmpty;
                                              return Visibility(
                                                visible: !isRecording,
                                                child: Composer(
                                                  gap: 0,
                                                  sendIcon: const Icon(Icons.send),
                                                  textEditingController:
                                                      _chatTextController,
                                                  handleSafeArea: true,
                                                  sigmaX: 3,
                                                  sigmaY: 3,
                                                  sendButtonHidden:
                                                      isChatInputEmpty,
                                                ),
                                              );
                                            });
                                      },
                                    ),
                                  ),
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
                                  left: MediaQuery
                                      .of(context)
                                      .size
                                      .width * 0.1,
                                  child: ReplyBar(
                                    repliedMessage: _repliedMessage!,
                                    onCancel: () =>
                                        setState(() => _repliedMessage = null),
                                  ),
                                ),
                            ],
                          ),
                  );
                } else {
                  return BrainStorming(
                    channelId: channelId!,
                    onClose: () {
                      brainStormingSwitch();
                    },
                  );
                }
              });
            },
          );
        },
      ),
    );
  }
}
