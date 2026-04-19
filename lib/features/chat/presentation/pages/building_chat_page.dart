import 'package:WhatsUnity/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:WhatsUnity/features/auth/presentation/bloc/auth_state.dart';
import 'package:WhatsUnity/features/social/presentation/bloc/social_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:social_media_recorder/audio_encoder_type.dart';
import 'package:social_media_recorder/screen/social_media_recorder.dart';
import 'package:uuid/uuid.dart';

import 'package:WhatsUnity/core/constants/Constants.dart';
import 'package:WhatsUnity/core/config/supabase.dart';
import 'package:WhatsUnity/core/services/gumletService.dart';
import 'package:WhatsUnity/features/social/data/datasources/social_remote_data_source.dart';
import 'package:WhatsUnity/features/social/data/repositories/social_repository_impl.dart';
import 'package:WhatsUnity/features/chat/presentation/bloc/chat_cubit.dart';
import 'package:WhatsUnity/features/chat/presentation/bloc/chat_state.dart';
import 'package:WhatsUnity/features/chat/presentation/widgets/chatWidget/AudioWaveformPainter.dart';
import 'package:WhatsUnity/features/chat/presentation/widgets/chatWidget/GeneralChat/GeneralChat.dart';
import 'package:WhatsUnity/features/chat/presentation/widgets/chat_scope.dart';

/// Shell for the bottom-nav **Chats** tab only (`channelName: BUILDING_CHAT`).
///
/// Uses [ChatScope] so building chat has its own [ChatCubit] (and realtime
/// subscription) separate from compound general chat on Home.
class BuildingChat extends StatelessWidget {
  const BuildingChat({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is! Authenticated) {
      return const Center(child: CircularProgressIndicator());
    }
    final currentCompoundId = authState.selectedCompoundId;
    final userId = authState.user.id;

    if (currentCompoundId == null) {
      return const Center(child: Text("No community selected"));
    }

    return ChatScope(
      compoundId: currentCompoundId,
      channelScopeId: 'BUILDING_CHAT',
      userId: userId,
      child: Scaffold(
      body:Stack(
        children: [
          BlocProvider(
              create: (context) =>SocialCubit(
                  repository: SocialRepositoryImpl(remoteDataSource: SocialRemoteDataSourceImpl(client: supabase),
                    driveService: driveService,
                  )
              ),
              child: GeneralChat(compoundId: currentCompoundId, channelName: 'BUILDING_CHAT')),
          BlocBuilder<ChatCubit,ChatState>(
              builder: (context,state){
                final chatCubit = context.read<ChatCubit>();
                
                final bool isChatInputEmpty = (state is ChatMessagesLoaded) ? state.isChatInputEmpty : chatCubit.isChatInputEmpty;
                final bool isBrainStormingLocal = (state is ChatMessagesLoaded) ? state.isBrainStorming : chatCubit.isBrainStorming;
                final int? channelIdLocal = (state is ChatMessagesLoaded) ? state.channelId : chatCubit.channelId;
                final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;

                if(isChatInputEmpty && isBrainStormingLocal == false && channelIdLocal != null) {
                  return Positioned(
                    bottom: keyboardBottom,
                    right: 0,
                    child: SafeArea(
                      child: SocialMediaRecorder(
                        onButtonPress: () {
                          chatCubit.recordedAmplitudes.clear();
                          chatCubit.toggleRecording();
                        },
                        onButtonRelease: () {
                          if (chatCubit.isRecording) {
                            chatCubit.toggleRecording();
                          }
                        },
                        // This is called when the user finishes recording
                        sendRequestFunction: (soundFile, duration) async {
                          debugPrint("attempting to save");
                          final parts = duration.split(':');
                          final minutes = int.tryParse(parts[0]) ?? 0;
                          final seconds = int.tryParse(parts[1]) ?? 0;
                          final parsedDuration = Duration(minutes: minutes, seconds: seconds);

                          final amplitudesToUpload = chatCubit.recordedAmplitudes;

                          // 1. Upload to Google Drive (legacy logic repurposed for Clean Arch)
                          final fileName = 'voice_note_${const Uuid().v4()}.m4a';
                          final driveLink = await driveService.uploadFile(
                            soundFile,
                            fileName,
                            'audio',
                          );

                          if (driveLink != null) {
                            // 2. Upload to Gumlet
                            final gumletUrl = await uploadVoiceNoteGumlet(driveLink);

                            if (gumletUrl != null) {
                              // 3. Use ChatCubit to send the message
                              if (context.mounted) {
                                context.read<ChatCubit>().sendVoiceNote(
                                  uri: gumletUrl,
                                  duration: parsedDuration,
                                  waveform: amplitudesToUpload,
                                  channelId: channelIdLocal!,
                                  userId: userId,
                                );
                              }
                            }
                          }
                        },

                        fullRecordPackageHeight: 80,

                        // Customize the appearance to match your app

                        backGroundColor: types.ChatColors
                            .light()
                            .surfaceContainerHigh
                            .withAlpha(100),
                        initialButtonWidth: 40,
                        initialButtonHight: 40,
                        finalButtonWidth: 60,
                        finalButtonHight: 60,

                        encode: AudioEncoderType.AAC,
                        waveformBuilder: (amplitudes) {
                          chatCubit.recordedAmplitudes = amplitudes;
                          return CustomPaint(
                            painter: AudioWaveformPainter(
                              amplitudes: amplitudes,
                              waveColor: Colors.black,

                            ),
                          );
                        },

                        // You can add more customizations here
                        // lockButton: const Icon(Icons.lock, color: Colors.white),
                        // slideToCancelText: "Slide to Cancel",
                        // etc.
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              })
        ],
      ),
    ),
    );
  }
}
