// GeneralChat.dart (Final Version with Placeholder and Polling Logic Restored)

import 'dart:async';
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

class _GeneralChatState extends State<GeneralChat>
    with AutomaticKeepAliveClientMixin {
  // Keep the widget alive while the TabBarView is in the tree so that
  // switching away and back does not destroy/recreate the state, re-run
  // _initializeChat(), or spin up duplicate Supabase subscriptions.
  // The mixin only prevents deactivation *within* the TabBarView; when Social
  // removes the TabBarView during sign-out (BlocBuilder returns
  // CircularProgressIndicator) the entire subtree — including this widget — is
  // still properly disposed by Flutter, so sign-out teardown is unaffected.
  @override
  bool get wantKeepAlive => true;
  // Services
  ChatCacheService? _cacheService;

  // Dispose guard — set true before super.dispose() so any in-flight async
  // work can bail out immediately without touching dead objects.
  bool _disposed = false;

  // Teardown guard — raised as soon as we detect a non-Authenticated auth
  // state, stopping ALL _chatController mutations before the Chat widget's
  // SliverAnimatedList is removed from the tree and its currentState → null.
  // This MUST be raised via the AuthCubit stream subscription (see initState),
  // not only in build(), because build() runs one frame after the emit whereas
  // ChatCubit real-time events can fire in the same microtask as the emit.
  bool _tearingDown = false;

  // Direct subscription to AuthCubit so _tearingDown is raised the INSTANT
  // the cubit emits — before the scheduler runs the next build frame.
  StreamSubscription<AuthState>? _authStateSubscription;

  // Serialise sync calls: only one _syncChatFromCubit at a time; if a newer
  // cubit state arrives while one is in-flight, the older one is discarded.
  int _syncVersion = 0;
  bool _syncActive = false;
  ChatMessagesLoaded? _pendingSync;

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
  // Initialised in initState (not _initializeChat) so it is always ready before
  // build() runs and, critically, is always disposed in dispose() even when
  // _initializeChat exits early. Declaring it late final guarantees a single
  // initialisation with no null-check overhead in build().
  late final ReactionsController _reactionsController;
  /// New [Chat] subtree each mount so flutter_chat_ui list internals (GlobalKeys)
  /// cannot collide after sign-out / sign-in.
  late final Key _chatSurfaceKey;
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
    if (_disposed || _tearingDown) return;

    // Deduplicate cubitMessages by ID (last-wins) — Supabase realtime can deliver
    // the same message twice when a subscription reconnects, and
    // InMemoryChatController.setMessages() asserts unique IDs which would crash.
    final seen = <String>{};
    final deduped = cubitMessages.reversed
        .where((m) => seen.add(m.id))
        .toList()
        .reversed
        .toList();

    final cubitIds = deduped.map((m) => m.id).toSet();
    final onlyOnDevice = _chatController.messages
        .where((m) => !cubitIds.contains(m.id))
        .toList();
    final merged = _sortedAsc([...deduped, ...onlyOnDevice]);
    try {
      await _chatController.setMessages(merged);
    } catch (e) {
      // ChatAnimatedList / SliverAnimatedList can throw an assertion error
      // ("child == null || indexOf(child) > index") when setMessages triggers
      // a removeItem/insertItem on a list that is mid-animation from a previous
      // call, or when the widget is being deactivated.  Catching here is safe:
      // the controller's internal message list has already been updated; the
      // next sync emission will reconcile the visual state automatically.
      debugPrint('GeneralChat._applyCubitMessagesToController: '
          'setMessages threw during animated-list operation — '
          'will recover on next sync. ($e)');
    }
  }

  @override
  void initState() {
    super.initState();
    _chatSurfaceKey = UniqueKey();
    _chatController = types.InMemoryChatController();
    _chatTextController = TextEditingController();
    _chatTextController.addListener(_handleTypingStatus);

    // Initialise ReactionsController here — before the first build — so it is
    // never null and is always paired with a matching dispose() call below.
    // GeneralChat is only inserted while the user is Authenticated (Social.dart
    // guards on authState), so context.read is safe in initState.
    final authState = context.read<AuthCubit>().state;
    final initUserId = (authState is Authenticated) ? authState.user.id : '';
    _userId = initUserId;
    _reactionsController = ReactionsController(currentUserId: initUserId);

    // Subscribe to AuthCubit directly so _tearingDown is raised the SAME
    // instant the cubit emits a non-Authenticated state — before the Flutter
    // scheduler calls build().  Without this, ChatCubit's Supabase realtime
    // events can fire in the same microtask as the auth-state change and reach
    // _chatController.setMessages() while _tearingDown is still false,
    // triggering the SliverAnimatedList "child == null || indexOf > index"
    // assertion one full frame before build() ever gets a chance to set the flag.
    _authStateSubscription = context.read<AuthCubit>().stream.listen((s) {
      if (s is! Authenticated) _raiseTeardownGuard();
    });

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
    // Raise both guards FIRST so every in-flight async continuation bails out
    // before it can touch _chatController or _reactionsController.
    _disposed = true;
    _tearingDown = true;
    _syncVersion++;
    _pendingSync = null;

    // Cancel the auth-state subscription before any other teardown so the
    // listener cannot fire after _chatController has been disposed.
    _authStateSubscription?.cancel();
    _authStateSubscription = null;

    for (var timer in _pollingTimers.values) {
      timer.cancel();
    }
    _pollingTimers.clear();

    if (channelId != null) {
      _cacheService?.saveMessages(channelId!, _chatController.messages);
    }

    _chatController.dispose();
    _appCubit?.detachChatController();

    // CRITICAL: dispose the ReactionsController so it removes any OverlayEntry
    // widgets (and their GlobalKeys) it registered. Failing to do this leaves
    // stale GlobalKeys in the global overlay that collide with the keys created
    // by the ReactionsController of the next session's GeneralChat.
    _reactionsController.dispose();

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

  /// Raises the teardown guard and cancels every pending controller mutation.
  /// Called by build() the first time it sees a non-Authenticated auth state.
  void _raiseTeardownGuard() {
    if (_tearingDown) return;
    _tearingDown = true;
    _syncVersion++;      // invalidate any in-flight _syncChatFromCubit
    _pendingSync = null; // drop queued work so _drainSyncQueue exits cleanly
  }

  /// Enqueues a sync from the cubit. Only one sync runs at a time; if a newer
  /// state arrives while one is in-flight, the older one is replaced so only
  /// the latest data is ever committed to the SliverAnimatedList.
  void _enqueueSyncFromCubit(ChatMessagesLoaded loaded) {
    // Hard gate: never touch _chatController once we are tearing down.
    // The Chat widget may have already been removed from the tree, meaning
    // its SliverAnimatedList GlobalKey.currentState is null.
    if (_disposed || _tearingDown) return;
    _pendingSync = loaded;
    if (!_syncActive) {
      _drainSyncQueue();
    }
  }

  Future<void> _drainSyncQueue() async {
    _syncActive = true;
    while (_pendingSync != null && !_disposed && !_tearingDown) {
      final loaded = _pendingSync!;
      _pendingSync = null;
      await _syncChatFromCubit(loaded);
    }
    _syncActive = false;
  }

  Future<void> _syncChatFromCubit(ChatMessagesLoaded loaded) async {
    if (_disposed || _tearingDown || !mounted) return;

    // Capture version at entry; any dispose() or _raiseTeardownGuard() call
    // will have incremented _syncVersion, causing stale continuations to bail.
    final version = _syncVersion;

    for (final message in loaded.messages) {
      if (message is types.AudioMessage &&
          message.metadata?['status'] == 'processing') {
        _startPollingForMessage(message);
      }
    }

    await _applyCubitMessagesToController(loaded.messages);

    // After every await: bail out if torn down or a newer sync has superseded us.
    if (_disposed || _tearingDown || !mounted || _syncVersion != version) return;

    final localIdsToRemove = <String>[];
    for (final message in loaded.messages) {
      final localId = message.metadata?['localId'];
      if (localId != null && message.id != localId) {
        localIdsToRemove.add(localId);
      }
    }

    for (final id in localIdsToRemove) {
      if (_disposed || _tearingDown || !mounted || _syncVersion != version) return;
      try {
        final messageToRemove =
            _chatController.messages.firstWhere((m) => m.id == id);
        await _chatController.removeMessage(messageToRemove);
      } catch (_) {}
    }
  }


  Future<void> _handleSendPressed(String text) async {
    // Composer never unfocuses on send; on iOS the keyboard stays up after the send icon.
    FocusManager.instance.primaryFocus?.unfocus();
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
    // _userId and _reactionsController were already set in initState.
    // Update _userId in case the auth state resolved to a different value
    // (token refresh edge-case) — no setState needed here, _isInitializing
    // being true means we're still behind the loading spinner.
    _userId = userId;
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

      if (!mounted) return;

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
    // Required by AutomaticKeepAliveClientMixin — must be the first call.
    super.build(context);
    final authState = context.watch<AuthCubit>().state;

    if (authState is! Authenticated) {
      // The auth session is ending (sign-out, token expiry, etc.).
      // Raise the teardown guard NOW, before Flutter removes the Chat widget
      // from the tree.  Once Chat is gone, its SliverAnimatedList
      // GlobalKey.currentState becomes null; any _chatController mutation
      // after that point crashes with:
      //   "Null check operator used on a null value"
      //   "_childElements.containsKey(index) is not true"
      // _raiseTeardownGuard() increments _syncVersion and clears _pendingSync
      // so every in-flight / queued async operation exits on its next check.
      _raiseTeardownGuard();
      // Return an empty box — do NOT show a spinner because CircularProgressIndicator
      // still triggers a frame that can race against the dying animated list.
      return const SizedBox.shrink();
    }

    // Auth is healthy — reset the teardown flag in case we recovered from a
    // transient non-authenticated state (e.g. token refresh blip).
    _tearingDown = false;

    final currentUserMember = authState.chatMembers.firstWhere((member) => member.id.trim() == authState.user.id, orElse: () => ChatMember(id: authState.user.id, displayName: "Unknown", building: "Unknown", apartment: "Unknown", userState: UserState.approved, phoneNumber: "", ownerType: OwnerTypes.owner));


    return BlocListener<ChatCubit, ChatState>(
      listenWhen: (previous, current) {
        if (current is! ChatMessagesLoaded) return false;
        if (previous is! ChatMessagesLoaded) return true;
        return !identical(previous.messages, current.messages);
      },
      listener: (context, state) {
        if (_disposed || _tearingDown || !mounted) return;
        _enqueueSyncFromCubit(state as ChatMessagesLoaded);
      },
      child: BlocBuilder<ChatCubit, ChatState>(
        buildWhen: (previous, current) {
          if (previous is ChatMessagesLoaded && current is ChatMessagesLoaded) {
            return previous.isBrainStorming != current.isBrainStorming;
          }
          return previous.runtimeType != current.runtimeType;
        },
        builder: (context, state) {
          // Hard guard: BlocBuilder<ChatCubit> has its own State and can be
          // called by Flutter independently of _GeneralChatState.build().
          // If auth is gone or we are disposed, never build Chat or
          // ChatAnimatedList — doing so with a dead _chatController or a
          // cleared message list is what triggers:
          //   "_childElements.containsKey(index): is not true"
          //   "Null check operator used on a null value"  (line 1130)
          if (_tearingDown || _disposed) return const SizedBox.shrink();

          return BlocBuilder<SocialCubit, SocialState>(
            builder: (context, socialState) {
              // Same guard for SocialCubit's independent rebuild path.
              if (_tearingDown || _disposed) return const SizedBox.shrink();

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
                                    key: _chatSurfaceKey,
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
