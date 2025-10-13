library social_media_recorder;

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:social_media_recorder/provider/sound_record_notifier.dart';

/// used to show mic and show dragg text when
/// press into record icon
class ShowMicWithText extends StatelessWidget {
  final bool shouldShowText;
  final String? slideToCancelText;
  final SoundRecordNotifier soundRecorderState;
  final TextStyle? slideToCancelTextStyle;
  final Color? backGroundColor;
  final Widget? recordIcon;
  final Color? counterBackGroundColor;
  final double fullRecordPackageHeight;
  final double initRecordPackageWidth;
  final double initialButtonWidth;
  final double initialButtonHight;
  final double finalButtonHight;
  final double finalButtonWidth;
  final Color? micBackgroundColor;
  final Widget Function(List<double> amplitudes)? waveformBuilder;


  // ignore: sort_constructors_first
  ShowMicWithText({
    required this.backGroundColor,
    required this.initRecordPackageWidth,
    required this.fullRecordPackageHeight,
    Key? key,
    required this.shouldShowText,
    required this.soundRecorderState,
    required this.slideToCancelTextStyle,
    required this.slideToCancelText,
    required this.recordIcon,
    required this.counterBackGroundColor,
    required this.initialButtonWidth,
    required this.initialButtonHight,
    required this.finalButtonHight,
    required this.finalButtonWidth,
    this.micBackgroundColor,
    this.waveformBuilder,
  }) : super(key: key);
  final colorizeColors = [
    Colors.black,
    Colors.grey.shade200,
    Colors.black,
  ];
  final colorizeTextStyle = const TextStyle(
    fontSize: 14.0,
    fontFamily: 'Horizon',
  );
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(-10, 5),
      child: Row(
        mainAxisAlignment: !soundRecorderState.buttonPressed
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Transform.scale(
                key: soundRecorderState.key,
                scale: soundRecorderState.buttonPressed ? 1.3 : 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(600),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeIn,
                    width: soundRecorderState.buttonPressed
                        ? finalButtonWidth
                        : initialButtonWidth,
                    height: soundRecorderState.buttonPressed
                        ? finalButtonHight
                        : initialButtonWidth,
                    child: Container(
                      color: micBackgroundColor ?? Colors.green,
                      child: Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: recordIcon ??
                            Icon(
                              Icons.mic,
                              size: 25,
                              color: Colors.white

                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (shouldShowText)
            Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Center(
                widthFactor:3.5,
                    child: DefaultTextStyle(
                      overflow: TextOverflow.clip,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 14.0,
                      ),
                      child: AnimatedTextKit(
                        animatedTexts: [
                          ColorizeAnimatedText(
                            slideToCancelText ?? "",
                            textStyle: slideToCancelTextStyle ?? colorizeTextStyle,
                            colors: colorizeColors,
                          ),
                        ],
                        isRepeatingAnimation: true,
                        onTap: () {},
                      ),
                    ),
                  ),

                  if (waveformBuilder != null)
                    Padding(
                      padding:EdgeInsetsGeometry.only(right: 12),
                      child:ValueListenableBuilder<List<double>>(
                        // 1. Listen to the dedicated notifier from your state object.
                        valueListenable: soundRecorderState.waveformNotifier,

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
                      ),)

                ],)

            ),
        ],
      ),
    );
  }
}
