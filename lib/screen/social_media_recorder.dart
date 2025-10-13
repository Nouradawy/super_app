library social_media_recorder;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media_recorder/provider/sound_record_notifier.dart';
import 'package:social_media_recorder/widgets/lock_record.dart';
import 'package:social_media_recorder/widgets/show_counter.dart';
import 'package:social_media_recorder/widgets/show_mic_with_text.dart';
import 'package:social_media_recorder/widgets/sound_recorder_when_locked_design.dart';

import '../audio_encoder_type.dart';

class SocialMediaRecorder extends StatefulWidget {
  /// use it for change back ground of cancel
  final Color? cancelTextBackGroundColor;

  /// function return the recording sound file and the time
  final Function(File soundFile, String time) sendRequestFunction;

  /// function called when start recording
  final Function()? startRecording;

  /// function called when stop recording, return the recording time (even if time < 1)
  final Function(String time)? stopRecording;

  /// recording Icon That pressesd to start record
  final Widget? recordIcon;

  /// recording Icon when user locked the record
  final Widget? recordIconWhenLockedRecord;

  /// use to change the backGround Icon when user recording sound
  final Color? recordIconBackGroundColor;

  /// use to change the Icon backGround color when user locked the record
  final Color? recordIconWhenLockBackGroundColor;

  /// use to change all recording widget color
  final Color? backGroundColor;

  /// use to change the counter style
  final TextStyle? counterTextStyle;

  /// text to know user should drag in the left to cancel record
  final String? slideToCancelText;

  /// use to change slide to cancel textstyle
  final TextStyle? slideToCancelTextStyle;

  /// this text show when lock record and to tell user should press in this text to cancel recod
  final String? cancelText;

  /// use to change cancel text style
  final TextStyle? cancelTextStyle;

  /// put you file directory storage path if you didn't pass it take deafult path
  final String? storeSoundRecoringPath;

  /// Chose the encode type
  final AudioEncoderType encode;

  /// use if you want change the raduis of un record
  final BorderRadius? radius;

  // use to change the counter back ground color
  final Color? counterBackGroundColor;

  // use to change lock icon to design you need it
  final Widget? lockButton;

  // use it to change send button when user lock the record
  final Widget? sendButtonIcon;

  // this function called when cancel record function

  // use to set max record time in second
  final int? maxRecordTimeInSecond;

  // use to change full package Height
  final double fullRecordPackageHeight;

  final double initRecordPackageWidth;

  // use to change Initial Mic Button background width
  final double initialButtonWidth;
  // use to change Initial Mic Button background Hight
  final double initialButtonHight;

  // use to change Final Mic Button background Hight
  final double finalButtonHight;

  // use to change Final Mic Button background width
  final double finalButtonWidth;

  final Color? micBackgroundColor;


  /// Function called when the record button is pressed down.
  final Function()? onButtonPress;

  /// Function called when the record button is released.
  final Function()? onButtonRelease;

  /// A builder that provides the current list of amplitudes to render a waveform.
  final Widget Function(List<double> amplitudes)? waveformBuilder;

  // ignore: sort_constructors_first
  const SocialMediaRecorder({
    this.sendButtonIcon,
    this.initRecordPackageWidth = 40,
    this.fullRecordPackageHeight = 50,
    this.maxRecordTimeInSecond,
    this.storeSoundRecoringPath = "",
    required this.sendRequestFunction,
    this.startRecording,
    this.stopRecording,
    this.recordIcon,
    this.lockButton,
    this.counterBackGroundColor,
    this.recordIconWhenLockedRecord,
    this.recordIconBackGroundColor = Colors.blue,
    this.recordIconWhenLockBackGroundColor = Colors.blue,
    this.backGroundColor,
    this.cancelTextStyle,
    this.counterTextStyle,
    this.slideToCancelTextStyle,
    this.slideToCancelText = " Slide to Cancel >",
    this.cancelText = "Cancel",
    this.encode = AudioEncoderType.AAC,
    this.cancelTextBackGroundColor,
    this.radius,
    this.waveformBuilder,
    required this.initialButtonWidth,
    required this.initialButtonHight,
    required this.finalButtonHight,
    required this.finalButtonWidth,
    this.micBackgroundColor,
    this.onButtonPress,
    this.onButtonRelease,
    Key? key,
  }) : super(key: key);

  @override
  _SocialMediaRecorder createState() => _SocialMediaRecorder();
}

class _SocialMediaRecorder extends State<SocialMediaRecorder> {
  late SoundRecordNotifier soundRecordNotifier;

  @override
  void initState() {
    soundRecordNotifier = SoundRecordNotifier(
      maxRecordTime: widget.maxRecordTimeInSecond,
      startRecording: widget.startRecording ?? () {},
      stopRecording: widget.stopRecording ?? (String x) {},
      sendRequestFunction: widget.sendRequestFunction,
    );

    soundRecordNotifier.initialStorePathRecord =
        widget.storeSoundRecoringPath ?? "";
    soundRecordNotifier.isShow = false;

    soundRecordNotifier.voidInitialSound();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    soundRecordNotifier.maxRecordTime = widget.maxRecordTimeInSecond;
    soundRecordNotifier.startRecording = widget.startRecording ?? () {};
    soundRecordNotifier.stopRecording = widget.stopRecording ?? (String x) {};
    soundRecordNotifier.sendRequestFunction = widget.sendRequestFunction;



    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => soundRecordNotifier),
        ],
        child: Consumer<SoundRecordNotifier>(
          builder: (context, value, _) {
            return Directionality(
                textDirection: TextDirection.rtl, child: makeBody(value));
          },
        ));
  }

  Widget makeBody(SoundRecordNotifier state) {
    return Column(
      children: [
        GestureDetector(
          onHorizontalDragUpdate: (scrollEnd) {
            state.updateScrollValue(scrollEnd.globalPosition, context);
          },
          onHorizontalDragEnd: (x) {
            if (state.buttonPressed && !state.isLocked) state.finishRecording();
          },
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: recordVoice(state),
          ),
        )
      ],
    );
  }

  Widget recordVoice(SoundRecordNotifier state) {

    if (state.lockScreenRecord == true) {
      return SoundRecorderWhenLockedDesign(
        cancelText: widget.cancelText,
        fullRecordPackageHeight: widget.fullRecordPackageHeight,
        // cancelRecordFunction: widget.cacnelRecording ?? () {},
        sendButtonIcon: widget.sendButtonIcon,
        cancelTextBackGroundColor: widget.cancelTextBackGroundColor,
        cancelTextStyle: widget.cancelTextStyle,
        counterBackGroundColor: widget.counterBackGroundColor != null?widget.counterBackGroundColor:widget.backGroundColor,
        recordIconWhenLockBackGroundColor: widget.recordIconWhenLockBackGroundColor ?? Colors.blue,
        counterTextStyle: widget.counterTextStyle,
        recordIconWhenLockedRecord: widget.recordIconWhenLockedRecord,
        sendRequestFunction: widget.sendRequestFunction,
        soundRecordNotifier: state,
        stopRecording: widget.stopRecording,
        waveformBuilder: widget.waveformBuilder,
      );
    }

    return Listener(
      onPointerDown: (details) async {
        state.setNewInitialDraggableHeight(details.position.dy);
        state.resetEdgePadding();
        soundRecordNotifier.isShow = true;

        if (widget.onButtonPress != null) {
          widget.onButtonPress!();
        }
        state.record(widget.startRecording);
      },
      onPointerUp: (details) async {
        if (widget.onButtonRelease != null) {
          widget.onButtonRelease!();
        }
        if (!state.isLocked) {
          state.finishRecording();

        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: soundRecordNotifier.isShow ? 0 : 300),
        height: widget.fullRecordPackageHeight,
        width: (soundRecordNotifier.isShow)
            ? MediaQuery.of(context).size.width
            : widget.initRecordPackageWidth,
        child: Stack(
          children: [

            Center(
              child: Padding(
                padding: EdgeInsets.only(right: state.edge),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: soundRecordNotifier.isShow
                        ? BorderRadius.circular(12)
                        : widget.radius != null && !soundRecordNotifier.isShow
                            ? widget.radius
                            : BorderRadius.circular(0),
                    color: soundRecordNotifier.isShow?  widget.backGroundColor : Colors.transparent
                  ),
                  child: Stack(

                    children: [
                      Center(
                        child: ShowMicWithText(
                          initRecordPackageWidth: widget.initRecordPackageWidth,
                          counterBackGroundColor: widget.counterBackGroundColor,
                          backGroundColor: widget.recordIconBackGroundColor,
                          fullRecordPackageHeight:
                              widget.fullRecordPackageHeight,
                          recordIcon: widget.recordIcon,
                          shouldShowText: soundRecordNotifier.isShow,
                          soundRecorderState: state,
                          slideToCancelTextStyle: widget.slideToCancelTextStyle,
                          slideToCancelText: widget.slideToCancelText,
                          initialButtonHight: widget.initialButtonHight,
                          initialButtonWidth: widget.initialButtonWidth,
                          finalButtonHight: widget.finalButtonHight,
                          finalButtonWidth: widget.finalButtonWidth,
                          micBackgroundColor:widget.micBackgroundColor,
                          waveformBuilder: widget.waveformBuilder,
                        ),
                      ),
                      if (soundRecordNotifier.isShow)
                        Positioned(
                          left:10,
                          top:soundRecordNotifier.isShow?6:0,
                          bottom: soundRecordNotifier.isShow?0:13,
                          child: ShowCounter(
                              counterBackGroundColor:
                                  widget.counterBackGroundColor!=null?widget.counterBackGroundColor:widget.backGroundColor,
                              soundRecorderState: state,
                              fullRecordPackageHeight:
                                  widget.fullRecordPackageHeight),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: LockRecord(
                soundRecorderState: state,
                lockIcon: widget.lockButton,
              ),
            )
          ],
        ),
      ),
    );
  }
}
