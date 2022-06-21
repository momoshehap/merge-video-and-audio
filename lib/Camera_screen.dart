import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:better_player/better_player.dart';
import 'package:camera/camera.dart';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  List<CameraDescription> cameras;

  CameraScreen(
    this.cameras,
  );

  @override
  State<StatefulWidget> createState() {
    return _CameraScreenState();
  }
}

class _CameraScreenState extends State<CameraScreen> {
  bool _toggleCamera = false;
  CameraController? controller;
  bool isVideoaudio = false;
  String? videoPath;
  String? videoaudioPath;
  int currentPageSound = 0;
  bool isRecording = false;
  bool recorded = false;
  AudioPlayer player = AudioPlayer();
  bool btnAppear = false;

  String choose = "";

  String videoSource = "camera";
  String audioPath = "";

  List<String> sounds = [
    "null",
    "upload from library",
  ];

  Timer? _timer;
  double seconds = 00;
  int minutes = 00;

  @override
  void initState() {
    super.initState();
    try {
      onCameraSelected(widget.cameras[0]);
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  void dispose() {
    super.dispose();
    player.pause();
    player.stop();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cameras.isEmpty) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16.0),
        child: const Text(
          'No Camera Found!',
          style: TextStyle(
            fontSize: 16.0,
            color: Colors.white,
          ),
        ),
      );
    }

    if (!controller!.value.isInitialized) {
      return Container();
    }

    return WillPopScope(
      onWillPop: () {
        return Future.value(true);
      },
      child: Scaffold(
        body: SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: (videoPath == null)
                ? CameraPreview(
                    controller!,
                    child: Stack(
                      children: [
                        (videoPath == null)
                            ? Positioned(
                                top: 18,
                                right: 17,
                                child: InkWell(
                                  child: Container(
                                      padding: const EdgeInsets.fromLTRB(
                                          12, 16, 12, 16),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(29)),
                                      child: const Text(
                                        "+Upload from library",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      )),
                                  onTap: () async {
                                    FilePickerResult? myFile =
                                        await FilePicker.platform.pickFiles(
                                      type: FileType.video,
                                    );
                                    final videoInfo = FlutterVideoInfo();

                                    if (myFile != null) {
                                      isRecording = false;

                                      player.stop();
                                      var a = await videoInfo.getVideoInfo(
                                          myFile.files.single.path!);

                                      seconds = a!.duration! / 1000;

                                      if (a.duration! ~/ 1000 > 90) {
                                      } else {
                                        Timer.run(() {
                                          setState(() {
                                            recorded = true;
                                            videoPath =
                                                myFile.files.single.path;
                                            print("videoPath  $videoPath");

                                            videoSource = "gallery";
                                          });
                                        });
                                      }

                                      if (audioPath != "") {
                                        videoAudioTogether();
                                      }
                                    }
                                  },
                                ))
                            : const SizedBox.shrink(),
                        Positioned(
                            left: 27,
                            bottom: MediaQuery.of(context).size.height * .35,
                            child: Container(
                              width: 55,
                              padding:
                                  const EdgeInsets.fromLTRB(12, 20, 12, 20),
                              decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(29)),
                              child: Column(
                                children: [
                                  InkWell(
                                      child: SvgPicture.asset(
                                          "assets/images/iconMusic.svg"),
                                      onTap: () {
                                        setState(() {
                                          choose = "sounds";
                                        });
                                      }),
                                ],
                              ),
                            )),
                        (videoPath == null)
                            ? Positioned(
                                bottom: 100,
                                left: 15,
                                right: 15,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const SizedBox(
                                      width: 14,
                                    ),
                                    (btnAppear)
                                        ? Row(
                                            children: [
                                              const CircleAvatar(
                                                backgroundColor: Colors.red,
                                                radius: 4,
                                              ),
                                              const SizedBox(
                                                width: 3,
                                              ),
                                              Text(
                                                "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
                                                style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14),
                                              ),
                                            ],
                                          )
                                        : const SizedBox.shrink(),
                                    const SizedBox(
                                      width: 14,
                                    ),
                                  ],
                                ))
                            : const SizedBox.shrink(),
                        (videoPath == null)
                            ? Positioned(
                                bottom: 15,
                                left: 15,
                                right: 15,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const SizedBox(
                                      width: 14,
                                    ),
                                    InkWell(
                                      child: SvgPicture.asset(
                                        (btnAppear)
                                            ? "assets/images/stopIcon.svg"
                                            : "assets/images/playIcon.svg",
                                        height: 84,
                                        width: 64,
                                      ),
                                      onTap: () {
                                        if (null == controller) return;
                                        if (!isRecording) {
                                          onVideoRecordButtonPressed();
                                        } else {
                                          onStopButtonPressed();
                                        }
                                      },
                                    ),
                                    const SizedBox(
                                      width: 14,
                                    ),
                                  ],
                                ))
                            : const SizedBox.shrink(),
                        (videoPath == null)
                            ? Positioned(
                                bottom: 25,
                                right: 15,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const SizedBox(
                                      width: 14,
                                    ),
                                    InkWell(
                                        child: Container(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Image.asset(
                                            'assets/images/ic_switch_camera_3.png',
                                            color: Colors.white,
                                            width: 42.0,
                                            height: 42.0,
                                          ),
                                        ),
                                        onTap: () {
                                          !_toggleCamera
                                              ? onCameraSelected(
                                                  widget.cameras[1])
                                              : onCameraSelected(
                                                  widget.cameras[0]);
                                          setState(() {
                                            _toggleCamera = !_toggleCamera;
                                          });
                                        }),
                                    const SizedBox(
                                      width: 14,
                                    ),
                                  ],
                                ))
                            : const SizedBox.shrink(),
                        (choose == "" || choose.isEmpty)
                            ? const SizedBox.shrink()
                            : Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  height: 100,
                                  decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      )),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SingleChildScrollView(
                                            padding: const EdgeInsets.all(6),
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: List.generate(
                                                  sounds.length, (p) {
                                                bool active =
                                                    currentPageSound == p;
                                                return GestureDetector(
                                                  onTap: () {
                                                    currentPageSound = p;

                                                    setState(() {
                                                      active =
                                                          currentPageSound == p;
                                                      choose = "";
                                                    });

                                                    if (sounds[p] ==
                                                        "upload from library") {
                                                      player.stop();

                                                      openAudioPicker();
                                                    } else if (sounds[p] ==
                                                        "None") {
                                                      player.stop();
                                                      audioPath = "";
                                                    } else {
                                                      player.stop();
                                                    }
                                                    setState(() {});
                                                  },
                                                  child: Container(
                                                      margin:
                                                          const EdgeInsets.all(
                                                              5),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      decoration: BoxDecoration(
                                                          color: active
                                                              ? Colors.blue
                                                              : Colors
                                                                  .grey[400],
                                                          borderRadius:
                                                              const BorderRadius
                                                                      .all(
                                                                  Radius
                                                                      .circular(
                                                                          10))),
                                                      child: Text(
                                                        (choose == "sounds")
                                                            ? (sounds[p] ==
                                                                    "null"
                                                                ? "None"
                                                                : sounds[p])
                                                            : "",
                                                        style: TextStyle(
                                                            fontSize: active
                                                                ? 16
                                                                : 14,
                                                            color:
                                                                Colors.white),
                                                      )),
                                                );
                                              }),
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: IconButton(
                                                    onPressed: () {
                                                      Timer.run(() {
                                                        setState(() {
                                                          choose = "";
                                                        });
                                                      });
                                                    },
                                                    icon: const Icon(
                                                      Icons.clear,
                                                      size: 30,
                                                      color: Colors.cyan,
                                                    )),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  )
                : SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: Stack(
                      children: [
                        audioPath == ""
                            ? BetterPlayer.file(
                                videoPath!,
                                betterPlayerConfiguration:
                                    BetterPlayerConfiguration(
                                  fit: BoxFit.fill,
                                  looping: false,
                                  autoPlay: false,
                                  aspectRatio:
                                      16 / MediaQuery.of(context).size.width,
                                ),
                              )
                            : ConditionalBuilder(
                                condition: isVideoaudio,
                                builder: (context) {
                                  return BetterPlayer.file(
                                    videoaudioPath!,
                                    betterPlayerConfiguration:
                                        BetterPlayerConfiguration(
                                      fit: BoxFit.fill,
                                      looping: false,
                                      autoPlay: false,
                                      aspectRatio: 16 /
                                          MediaQuery.of(context).size.width,
                                    ),
                                  );
                                },
                                fallback: (context) => const Center(
                                    child: CircularProgressIndicator(
                                  color: Color(0xff155079),
                                )),
                              ),
                        (videoPath != null)
                            ? Positioned(
                                bottom: 50,
                                left: 15,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      child: Container(
                                          width: 125,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(29)),
                                          child: const Center(
                                            child: Text(
                                              "Discard",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          )),
                                      onTap: () {
                                        setState(() {
                                          videoPath = null;
                                          recorded = false;
                                          videoSource = "";
                                          isVideoaudio = false;
                                          videoaudioPath = "";
                                          isRecording = false;
                                          seconds = 00;
                                          minutes = 00;
                                          // hours = 00;
                                        });
                                      },
                                    ),
                                  ],
                                ))
                            : const SizedBox.shrink(),
                        (videoPath != null)
                            ? Positioned(
                                bottom: 50,
                                right: 15,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                        onTap: saveVideo(audioPath == ""
                                            ? videoPath
                                            : videoaudioPath),
                                        child: Container(
                                            width: 125,
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(29)),
                                            child: const Text(
                                              "Save",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14),
                                              textAlign: TextAlign.center,
                                            )))
                                  ],
                                ))
                            : const SizedBox.shrink(),
                      ],
                    )),
          ),
        ),
      ),
    );
  }

  void openAudioPicker() async {
    FilePickerResult? path = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if (path != null) {
      playRemoteFile(path.files.single.path!);
    }
  }

  void onCameraSelected(CameraDescription cameraDescription) async {
    controller = CameraController(cameraDescription, ResolutionPreset.high,
        enableAudio: (audioPath != "") ? false : true);

    controller!.addListener(() {
      if (mounted) setState(() {});
      if (controller!.value.hasError) {
        print('Camera Error: ${controller!.value.errorDescription}');
      }
    });

    try {
      await controller!.initialize();
    } on CameraException catch (e) {
      print('Error: ${e.code}\nMessage: ${e.description}');
    }

    if (mounted) setState(() {});
  }

  String timestamp() => new DateTime.now().millisecondsSinceEpoch.toString();

  void onVideoRecordButtonPressed() {
    print('onVideoRecordButtonPressed()');
    startVideoRecording(true).then((String? filePath) {
      // if (mounted) setState(() {});
      startTimer();
      print("audiooooooooooooo $audioPath");
      if (audioPath != "") {
        print("audiooooooooooooo $audioPath");
        player.play(
          audioPath,
          isLocal: true,
        );
      }
      setState(() {
        isRecording = true;
        btnAppear = true;
      });
      if (filePath != null) print('Saving video to $filePath');
    });
  }

  void onStopButtonPressed() {
    stopVideoRecording().then((_) {
      print("plater ${player.state.name}");
      if (mounted) setState(() {});
      _timer!.cancel();
      player.stop();
      setState(() {
        isRecording = false;
        btnAppear = false;
      });
      print('Video recorded to: $videoPath');
    });
  }

  Future<String?> startVideoRecording(bool camera) async {
    if (!controller!.value.isInitialized) {
      print('Error: select a camera first.');
      return null;
    }
    if (controller!.value.isRecordingVideo) {
      return null;
    }
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Videos';
    await new Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.mp4';

    print("path $filePath");

    if (camera) {
      try {
        await controller!.startVideoRecording();
        print("1 nullllllllllll");
      } on CameraException catch (e) {
        print('Error: ${e.code}\nMessage: ${e.description}');
        return null;
      }
    }
    return filePath;
  }

  Future<void> stopVideoRecording() async {
    if (!controller!.value.isRecordingVideo) {
      print("nulllllllllllllll");
      return null;
    }

    try {
      final file = await controller!.stopVideoRecording();

      File video = File(file.path);
      print("vvvvvvvvvv  ${video.path}  ${file.path}");

      _timer!.cancel();
      isRecording = false;
      setState(() {
        btnAppear = false;
        videoPath = video.path;
        videoSource = "camera";
      });
      if (audioPath != "") {
        videoAudioTogether();
      }
    } on CameraException catch (e) {
      print("cccccccccccccc   $e");
      return null;
    }
  }

  videoAudioTogether() async {
    startVideoRecording(false).then((String? output) async {
      int secs = (int.parse(minutes.toString()) * 60) +
          (int.parse(seconds.round().toString()));
      await FFmpegKit.executeAsync(
        "-y -i $videoPath -i $audioPath -map 0:v -map 1:a -ss 0 -to $secs -c:v copy $output",
        (session) async {
          final state = await session.getState();
          final returnCode = await session.getReturnCode();

          if (returnCode!.isValueSuccess()) {
            setState(() {
              videoaudioPath = output;
              isVideoaudio = true;
            });
          } else {
            print("some thing went erorr ..${state.toString()}");
          }
        },
      ).catchError((e) {
        print("some thing went erorr ..$e");
      });
    });
  }

  addVideo() async {
    if (videoPath != null || recorded) {
      Timer.run(() {
        setState(() {
          recorded = false;
          isRecording = false;
        });
      });
    } else {
      alertDialog(context, "Please, choose video to upload!!");
    }
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) => setState(
        () {
          if (seconds < 0) {
            timer.cancel();
          } else {
            seconds = seconds + 1;

            if (seconds == 30) {
              onStopButtonPressed();
            }

            if (seconds > 59) {
              minutes += 1;
              seconds = 00;
            }
          }
        },
      ),
    );
  }

  void playRemoteFile(String path) async {
    if (Platform.isAndroid || Platform.isIOS) {
      setState(() {
        audioPath = path;
      });
      onCameraSelected(widget.cameras[0]);
      Fluttertoast.showToast(msg: "Start recording to play music");

      print("jj ${player.state.toString()}");
    } else {}
  }

  alertDialog(BuildContext context, String text) {
    return showDialog(
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () {
            return Future.value(true);
          },
          child: CupertinoAlertDialog(
            content: Container(
              child: Text(
                text,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            title: const Text(
              "Spotkam",
              style: TextStyle(color: Colors.blue),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(color: Colors.blue),
                  )),
            ],
          ),
        );
      },
      context: context,
    );
  }

  saveVideo(String? recordedVideo) async {
    GallerySaver.saveVideo(recordedVideo).then((String path) {
      setState(() {
        print('video saved!');
      });
    });
  }
}
