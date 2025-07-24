import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart' show FilePicker, FileType;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flyer_chat_image_message/flyer_chat_image_message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import 'package:super_app/Layout/Cubit/cubit.dart';
import 'package:super_app/Layout/Cubit/states.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';


final supabase = Supabase.instance.client;

class Generalchat extends StatefulWidget {
  const Generalchat({super.key});

  @override
  State<Generalchat> createState() => _GeneralchatState();
}

class _GeneralchatState extends State<Generalchat> {
  late final Stream<List<types.Message>> _messagesStream;

  final _chatController = types.InMemoryChatController();
  final _currentUser = types.User(id: supabase.auth.currentUser!.id, name: "John");


  @override
  void initState() {
    // 2. Map the Supabase stream to a stream of `types.Message`
    _messagesStream = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((maps) => maps
        .map((map) => _mapToMessage(map))
        .toList());
    super.initState();
  }

  types.Message _mapToMessage(Map<String, dynamic> map) {
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
          source: map['source'],
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
        );
      default: // 'text'
        return types.TextMessage(

          createdAt: DateTime.parse(map['created_at']),
          id: map['id'],
          authorId:  map['author_id'],
          text: map['text'] ?? '',
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

    final bytes = await result.readAsBytes();
    final image = await decodeImageFromList(bytes);
    final fileExt = result.path.split('.').last;
    final fileName = '${const Uuid().v4()}.$fileExt';

    // Upload to Supabase Storage
    await supabase.storage.from('chat_attachments').uploadBinary(
      fileName,
      bytes,
      fileOptions: FileOptions(contentType: result.mimeType),
    );

    // Get the public URL
    final imageUrl = supabase.storage.from('chat_attachments').getPublicUrl(fileName);

    // Insert message record into the database
    await supabase.from('messages').insert({
      'id': const Uuid().v4(),
      'author_id': _currentUser.id,
      'uri': imageUrl,
      'type': 'image',
      'created_at': DateTime.now().toIso8601String(),
      'metadata': {
        'name': result.name,
        'size': bytes.length,
        'height': image.height.toDouble(),
        'width': image.width.toDouble(),
      }
    });
  }

  void _handleAttachmentPressed() {
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
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {

    return BlocBuilder<AppCubit, AppCubitStates>(
      builder: (context, states) {
        return Scaffold(
          appBar:AppBar(
              title:Text("General Chat"),
          ),
          body: StreamBuilder<List<types.Message>>(
            stream: _messagesStream,
            builder: (context,snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              _chatController.insertAllMessages(snapshot.data ?? []);

              return Chat(
                chatController: _chatController,
                currentUserId: supabase.auth.currentUser!.id,
                resolveUser: (id) async{
                    return types.User(
                        id:id,
                        name: "John",
                    createdAt: DateTime.now());
                },

                onMessageSend: (text) {
                  _handleSendPressed(text);
                },

                onAttachmentTap:_handleAttachmentPressed,
                builders: types.Builders(

                  imageMessageBuilder: (context, message, index, {
                    required bool isSentByMe,
                    types.MessageGroupStatus? groupStatus,
                  }) =>
                      FlyerChatImageMessage(message: message, index: index),
                ),


              );
            }
          ),
        );
      },
    );
  }
}
