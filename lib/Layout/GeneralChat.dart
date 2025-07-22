import 'dart:math';

import 'package:file_picker/file_picker.dart' show FilePicker, FileType;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flyer_chat_image_message/flyer_chat_image_message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import 'package:super_app/Layout/Cubit/cubit.dart';
import 'package:super_app/Layout/Cubit/states.dart';
import 'package:uuid/uuid.dart';

class Generalchat extends StatefulWidget {
  const Generalchat({super.key});

  @override
  State<Generalchat> createState() => _GeneralchatState();
}

class _GeneralchatState extends State<Generalchat> {
  final _chatController = InMemoryChatController();



  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = ImageMessage(
        createdAt: DateTime.now(),
        height: image.height.toDouble(),
        id: const Uuid().v4(),
        size: bytes.length,
        width: image.width.toDouble(),
        authorId: 'user1',
        source: result.path,
      );

    _chatController.insertMessage(message);
    }
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final message = FileMessage(

        createdAt: DateTime.now(),
        id: const Uuid().v4(),
        mimeType: lookupMimeType(result.files.single.path!),
        name: result.files.single.name,
        size: result.files.single.size,
        source: result.files.single.path!,
        authorId: 'user1',

      );

      _chatController.insertMessage(message);
    }
  }

  @override
  Widget build(BuildContext context) {

    return BlocBuilder<AppCubit, AppCubitStates>(
      builder: (context, states) {
        return Scaffold(
          appBar:AppBar(
              title:Text("General Chat"),
          ),
          body: Chat(

              currentUserId: 'user1',
            resolveUser: (id) async{
                return User(
                    id:id,
                    name: "John",
                createdAt: DateTime.now());
            },

            onMessageSend: (text) {
              _chatController.insertMessage(
                TextMessage(
                  // Better to use UUID or similar for the ID - IDs must be unique.
                  id: '${Random().nextInt(1000) + 1}',
                  authorId: 'user1',
                  createdAt: DateTime.now().toUtc(),
                  text: text,

                ),
              );
            },
            chatController: _chatController,
              onAttachmentTap:_handleAttachmentPressed,
            builders: Builders(

              imageMessageBuilder: (context, message, index, {
                required bool isSentByMe,
                MessageGroupStatus? groupStatus,
              }) =>
                  FlyerChatImageMessage(message: message, index: index),
            ),


          ),
        );
      },
    );
  }
}
