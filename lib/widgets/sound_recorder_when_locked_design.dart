library social_media_recorder;

import 'package:flutter/material.dart';
import 'package:social_media_recorder/provider/sound_record_notifier.dart';
import 'package:social_media_recorder/widgets/show_counter.dart';

// ignore: must_be_immutable
class SoundRecorderWhenLockedDesign extends StatelessWidget {
  final double fullRecordPackageHeight;
  final SoundRecordNotifier soundRecordNotifier;
  final String? cancelText;
  final Function sendRequestFunction;
  final Function(String time)? stopRecording;
  final Widget? recordIconWhenLockedRecord;
  final TextStyle? cancelTextStyle;
  final TextStyle? counterTextStyle;
  final Color recordIconWhenLockBackGroundColor;
  final Color? counterBackGroundColor;
  final Color? cancelTextBackGroundColor;
  final Widget? sendButtonIcon;
  final Widget Function(List<double> amplitudes)? waveformBuilder;
  // ignore: sort_constructors_first
  const SoundRecorderWhenLockedDesign({
    Key? key,
    required this.fullRecordPackageHeight,
    required this.sendButtonIcon,
    required this.soundRecordNotifier,
    required this.cancelText,
    required this.sendRequestFunction,
    this.stopRecording,
    required this.recordIconWhenLockedRecord,
    required this.cancelTextStyle,
    required this.counterTextStyle,
    required this.recordIconWhenLockBackGroundColor,
    required this.counterBackGroundColor,
    required this.cancelTextBackGroundColor,
    this.waveformBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: cancelTextBackGroundColor ?? Colors.blue,

      ),
      child:Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,

        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (waveformBuilder != null)
                ValueListenableBuilder<List<double>>(
                  // 1. Listen to the dedicated notifier from your state object.
                  valueListenable: soundRecordNotifier.waveformNotifier,

                  // 2. This builder will now be the ONLY part that
                  //    rebuilds at high frequency.
                  builder: (context, amplitudes, child) {
                    return SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: 50,
                      // 3. Call your waveformBuilder with the new data.
                      child: waveformBuilder!(amplitudes),
                    );
                  },
                ),

              ShowCounter(
                soundRecorderState: soundRecordNotifier,
                counterTextStyle: counterTextStyle,
                counterBackGroundColor: counterBackGroundColor,
                fullRecordPackageHeight: fullRecordPackageHeight,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: (){
                soundRecordNotifier.resetEdgePadding();

              }, icon: Icon(Icons.delete)),
              IconButton(onPressed: (){
                if(soundRecordNotifier.isPaused){
                  soundRecordNotifier.resumeRecording();
                } else
                soundRecordNotifier.pauseRecording();

              }, icon: Icon(soundRecordNotifier.isPaused ? Icons.play_arrow : Icons.pause,)),
              IconButton(onPressed: (){

                soundRecordNotifier.isShow = false;
                soundRecordNotifier.finishRecording();

              }, icon: Icon(Icons.send , textDirection: TextDirection.ltr,)),
            ].reversed.toList(),
          ),
        ],
      ),)


    );
  }
}
