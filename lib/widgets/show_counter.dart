library social_media_recorder;

import 'package:flutter/material.dart';
import 'package:social_media_recorder/provider/sound_record_notifier.dart';

/// Used this class to show counter and mic Icon
class ShowCounter extends StatelessWidget {
  final SoundRecordNotifier soundRecorderState;
  final TextStyle? counterTextStyle;
  final Color? counterBackGroundColor;
  final double fullRecordPackageHeight;
  // ignore: sort_constructors_first
  const ShowCounter({
    required this.soundRecorderState,
    required this.fullRecordPackageHeight,
    Key? key,
    this.counterTextStyle,
    required this.counterBackGroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: fullRecordPackageHeight,
      child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                soundRecorderState.second.toString().padLeft(2, '0'),
                style: counterTextStyle ??
                    const TextStyle(fontSize: 13),
              ),

              const Text(" : ",style:TextStyle(fontSize: 13)),
              Text(
                soundRecorderState.minute.toString().padLeft(2, '0'),
                style: counterTextStyle ??
                    const TextStyle(color: Colors.black ,fontSize: 13),
              ),
              AnimatedOpacity(
                duration: const Duration(seconds: 1),
                opacity: soundRecorderState.second % 2 == 0 ? 1 : 0,
                child: const Icon(
                  Icons.mic,
                  color: Colors.red,
                ),
              ),
            ],
          ),


    );
  }
}
