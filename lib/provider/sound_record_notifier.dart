import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:social_media_recorder/audio_encoder_type.dart';
// import 'package:uuid/uuid.dart';

class SoundRecordNotifier extends ChangeNotifier {
  int _counter = 0;
  int _localCounterForMaxRecordTime = 0;
  GlobalKey key = GlobalKey();
  int? maxRecordTime;

  List<double> amplitudes = [];
  final ValueNotifier<List<double>> waveformNotifier = ValueNotifier([]);
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  /// This Timer Just For wait about 1 second until starting record
  Timer? _timer;

  /// This time for counter wait about 1 send to increase counter
  Timer? _timerCounter;

  /// Use last to check where the last draggable in X
  double last = 0;

  /// Used when user enter the needed path
  String initialStorePathRecord = "";

  /// recording mp3 sound Object
  AudioRecorder recordMp3 = AudioRecorder();

  /// recording mp3 sound to check if all permisiion passed
  bool _isAcceptedPermission = false;

  /// used to update state when user draggable to the top state
  double currentButtonHeihtPlace = 0;

  /// used to know if isLocked recording make the object true
  /// else make the object isLocked false
  bool isLocked = false;

  /// when pressed in the recording mic button convert change state to true
  /// else still false
  bool isShow = false;

  bool isPaused = false;

  /// to show second of recording
  late int second;

  /// to show minute of recording
  late int minute;

  /// to know if pressed the button
  late bool buttonPressed;

  /// Blocks double-invoke when pointer-up and drag-end both call [finishRecording].
  bool _recordingFinishHandled = false;

  /// used to update space when dragg the button to left
  late double edge;
  late bool loopActive;

  /// store final path where user need store mp3 record
  late bool startRecord;

  /// store the value we draggble to the top
  late double heightPosition;

  /// store status of record if lock change to true else
  /// false
  late bool lockScreenRecord;
  late String mPath;

  /// function called when start recording
  Function()? startRecording;
  Function(File soundFile, String time) sendRequestFunction;

  /// function called when stop recording, return the recording time (even if time < 1)
  Function(String time)? stopRecording;

  late AudioEncoderType encode;

  // ignore: sort_constructors_first

  SoundRecordNotifier({
    required this.stopRecording,
    required this.sendRequestFunction,
    required this.startRecording,
    this.edge = 0.0,
    this.minute = 0,
    this.second = 0,
    this.buttonPressed = false,
    this.loopActive = false,
    this.mPath = '',
    this.startRecord = false,
    this.heightPosition = 0,
    this.lockScreenRecord = false,
    this.encode = AudioEncoderType.AAC,
    this.maxRecordTime,
  }) {
    record(() {});
  }

  /// To increase counter after 1 sencond
  void _mapCounterGenerater() {
    _timerCounter = Timer(const Duration(seconds: 1), () {
      _increaseCounterWhilePressed();
      if (buttonPressed) _mapCounterGenerater();
    });
  }

  /// used to reset all value to initial value when end the record
  resetEdgePadding() async {
    _amplitudeSubscription?.cancel();
    amplitudes.clear();

    if (_initWidth == -33) {
      RenderBox box = key.currentContext?.findRenderObject() as RenderBox;
      Offset position = box.localToGlobal(Offset.zero);
      _initWidth = position.dx;
    }
    _localCounterForMaxRecordTime = 0;
    isLocked = false;
    edge = 0;
    buttonPressed = false;
    second = 0;
    minute = 0;
    isShow = false;
    key = GlobalKey();
    heightPosition = 0;
    lockScreenRecord = false;
    isPaused = false;
    if (_timer != null) _timer!.cancel();
    if (_timerCounter != null) _timerCounter!.cancel();
    final value = await recordMp3.isRecording();

    if (value == true) {
      recordMp3.stop().then((x) {
        recordMp3 = AudioRecorder();
        notifyListeners();
      });
      notifyListeners();
    }
    notifyListeners();
  }

  String _getSoundExtention() {
    if (encode == AudioEncoderType.AAC ||
        encode == AudioEncoderType.AAC_LD ||
        encode == AudioEncoderType.AAC_HE ||
        encode == AudioEncoderType.OPUS) {
      return ".m4a";
    } else if (encode == AudioEncoderType.OPUS) {
      return ".opus";
    } else {
      return ".wav"; // fallback for PCM
    }
  }

  /// used to get the current store path
  Future<String> getFilePath() async {
    if (kIsWeb) {
      final now = DateTime.now();
      final convertedDateTime =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}_${_counter++}';
      final storagePath = 'recording_$convertedDateTime${_getSoundExtention()}';
      mPath = storagePath;
      return storagePath;
    }

    String _sdPath = "";
    Directory tempDir = await getTemporaryDirectory();
    _sdPath =
        initialStorePathRecord.isEmpty ? tempDir.path : initialStorePathRecord;
    var d = Directory(_sdPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    final now = DateTime.now();
    // Avoid prefixing _counter onto year (was producing names like "02026-04-24-…").
    final convertedDateTime =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}_${_counter++}';
    final storagePath = '$_sdPath/$convertedDateTime${_getSoundExtention()}';
    mPath = storagePath;
    return storagePath;
  }

  /// used to change the draggable to top value
  setNewInitialDraggableHeight(double newValue) {
    currentButtonHeihtPlace = newValue;
  }

  double _initWidth = -33;

  /// used to change the draggable to top value
  /// or To The X vertical
  /// and update this value in screen
  updateScrollValue(Offset currentValue, BuildContext context) async {
    if (buttonPressed == true) {
      final x = currentValue;

      /// take the diffrent between the origin and the current
      /// draggable to the top place
      double hightValue = currentButtonHeihtPlace - x.dy;

      /// if reached to the max draggable value in the top
      if (hightValue >= 50) {
        isLocked = true;
        lockScreenRecord = true;
        hightValue = 50;
        notifyListeners();
      }
      if (hightValue < 0) hightValue = 0;
      heightPosition = hightValue;
      lockScreenRecord = isLocked;
      notifyListeners();

      /// this operation for update X oriantation
      /// draggable to the left or right place
      try {
        RenderBox box = key.currentContext?.findRenderObject() as RenderBox;
        Offset position = box.localToGlobal(Offset.zero);
        if (position.dx <= MediaQuery.of(context).size.width * 0.6) {
          String _time = minute.toString() + ":" + second.toString();
          if (stopRecording != null) stopRecording!(_time);
          resetEdgePadding();
        } else if (x.dx >= MediaQuery.of(context).size.width) {
          edge = 0;
          edge = 0;
        } else {
          edge = (_initWidth - x.dx) > 0 ? (_initWidth - x.dx) : 0;

          // if (x.dx <= MediaQuery.of(context).size.width * 0.5) {}
          // if (last < x.dx) {
          //   edge = edge -= x.dx / 200;
          //   if (edge < 0) {
          //     edge = 0;
          //   }
          // } else if (last > x.dx) {
          //   edge = edge += x.dx / 200;
          // }
          // last = x.dx;
        }
        // ignore: empty_catches
      } catch (e) {}
      notifyListeners();
    }
  }

  /// this function to manage counter value
  /// when reached to 60 sec
  /// reset the sec and increase the min by 1
  _increaseCounterWhilePressed() async {
    if (loopActive) {
      return;
    }

    loopActive = true;
    if (maxRecordTime != null) {
      if (_localCounterForMaxRecordTime >= maxRecordTime!) {
        loopActive = false;
        await finishRecording();
        return;
      }
      _localCounterForMaxRecordTime++;
    }
    second = second + 1;
    buttonPressed = buttonPressed;
    if (second == 60) {
      second = 0;
      minute = minute + 1;
    }

    notifyListeners();
    loopActive = false;
    notifyListeners();
  }

  /// this function to start record voice
  record(Function()? startRecord) async {
    if (!_isAcceptedPermission) {
      _isAcceptedPermission = true;
    } else {
      buttonPressed = true;
      _recordingFinishHandled = false;
      String recordFilePath = await getFilePath();
      if (_timer != null) {
        _timer?.cancel();
      }

      _timer = Timer(const Duration(milliseconds: 400), () {
        recordMp3.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            noiseSuppress: true,
          ),
          path: recordFilePath,
        );
        List<double> currentAmplitudes = [];
        _amplitudeSubscription = recordMp3
            .onAmplitudeChanged(const Duration(milliseconds: 50))
            .listen((amp) {
          currentAmplitudes.add(amp.current);
          if (currentAmplitudes.length > 60) {
            currentAmplitudes.removeAt(0);
          }
          // This updates the ValueNotifier with a new list
          waveformNotifier.value = List.from(currentAmplitudes);
        });
      });

      if (startRecord != null) {
        startRecord();
      }

      _mapCounterGenerater();
      notifyListeners();
    }
    notifyListeners();
  }

  /// Stops the encoder and finalizes the container **before** [sendRequestFunction].
  /// Uploading [mPath] while still recording yields an invalid .m4a and Gumlet rejects it.
  Future<void> finishRecording() async {
    if (buttonPressed && !isPaused) {
      if (second > 0 || minute > 0) {
        if (_recordingFinishHandled) return;
        _recordingFinishHandled = true;

        final time = '$minute:$second';
        var path = mPath;

        try {
          _amplitudeSubscription?.cancel();
          _amplitudeSubscription = null;

          if (await recordMp3.isRecording()) {
            final stoppedPath = await recordMp3.stop();
            if (stoppedPath != null && stoppedPath.isNotEmpty) {
              path = stoppedPath;
            }
          }

          if (path.isNotEmpty &&
              (kIsWeb || await File(path).exists())) {
            sendRequestFunction(File(path), time);
          }
          stopRecording?.call(time);
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint(
              'social_media_recorder: finishRecording failed: $e\n$st',
            );
          }
          _recordingFinishHandled = false;
        }
      }
    }
    await resetEdgePadding();
  }

  pauseRecording() async {
    if (buttonPressed) {
      if (await recordMp3.isRecording()) {
        await recordMp3.pause();
        isPaused = true;
        if (_timerCounter != null) _timerCounter!.cancel();
        _amplitudeSubscription?.pause();
        notifyListeners();
      }
    }
  }

  resumeRecording() async {
    if (buttonPressed) {
      try {
        await recordMp3.resume(); // <--- ADD 'await' here
        // The small delay is no longer needed but can be kept for robustness
        // await Future.delayed(const Duration(milliseconds: 100));

        isPaused = false;
        _mapCounterGenerater();
        _amplitudeSubscription?.resume();
        notifyListeners();
      } catch (e) {
        // You can add a print statement here for debugging
        print('Error resuming recording: $e');
      }
    }
  }

  /// to check permission
  voidInitialSound() async {
    startRecord = false;
    final micPermission = await Permission.microphone.request();
    _isAcceptedPermission = micPermission.isGranted;
  }
}
