import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:social_media_recorder/audio_encoder_type.dart';
import 'package:social_media_recorder/screen/social_media_recorder.dart';

import '../Components/Constants.dart';
import 'Cubit/cubit.dart';
import 'Cubit/states.dart';
import 'chatWidget/AudioWaveformPainter.dart';
import 'chatWidget/GeneralChat/GeneralChat.dart';


class BuildingChat extends StatelessWidget {
  const BuildingChat({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body:Stack(
        children: [
          GeneralChat(compoundId: selectedCompoundId!, channelName: 'BUILDING_CHAT'),
          BlocBuilder<AppCubit,AppCubitStates>(
              buildWhen: (prev , current)=>current  is ShowHideMicStates  || current is BottomNavIndexChangeStates,
              builder: (context,state){
                if(AppCubit.get(context).isChatInputEmpty && isBrainStorming ==false) {
                  return Positioned(
                    bottom: 0 + AppCubit.get(context).micPadding,
                    right: 0,
                    child: SafeArea(
                      child: SocialMediaRecorder(
                        onButtonPress: () {
                          AppCubit.get(context).recordedAmplitudes.clear();
                          AppCubit.get(context).micOnPressed();
                        },
                        onButtonRelease: () {
                          if (AppCubit
                              .get(context)
                              .isRecording) {
                            AppCubit.get(context).micOnPressed();
                          }
                        },
                        // This is called when the user finishes recording
                        sendRequestFunction: (soundFile, duration) async {
                          debugPrint("attempting to save");
                          final parts = duration.split(':');
                          final minutes = int.tryParse(parts[0]) ?? 0;
                          final seconds = int.tryParse(parts[1]) ?? 0;
                          final parsedDuration = Duration(minutes: minutes, seconds: seconds);

                          final amplitudesToUpload = AppCubit.get(context).recordedAmplitudes;
                          AppCubit.get(context).uploadVoiceNote(soundFile, parsedDuration ,amplitudesToUpload ,selectedCompoundId!);

                        },

                        fullRecordPackageHeight: 80,

                        // Customize the appearance to match your app

                        backGroundColor: ChatColors
                            .light()
                            .surfaceContainerHigh
                            .withAlpha(100),
                        initialButtonWidth: 40,
                        initialButtonHight: 40,
                        finalButtonWidth: 60,
                        finalButtonHight: 60,

                        encode: AudioEncoderType.AAC,
                        waveformBuilder: (amplitudes) {
                          AppCubit.get(context).recordedAmplitudes = amplitudes;
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
    );
  }
}
