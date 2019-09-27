import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file/memory.dart';
import 'package:camera/camera.dart';

import 'package:webcam_flutter/server.dart';

List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var pictureInterval = Duration(milliseconds: 100);

  CameraController controller;
  Directory pictureDir;
  Timer pictureTimer;
  int pictureTaken = 0;
  PreviewServer server;

  startTimer() async {
    var baseDir = await getTemporaryDirectory();

    pictureDir = await Directory('${baseDir.path}/webcam_flutter')
        .create(recursive: true);
    pictureTimer = Timer.periodic(pictureInterval, savePicture);
  }

  stopTimer() {
    pictureTimer?.cancel();
  }

  savePicture(Timer timer) async {
    if (controller == null) {
      return false;
    }

    pictureTaken += 1;
    try {
      var cPath = '${pictureDir.path}/preview_$pictureTaken.png';
      await controller.takePicture(cPath);

      server.preview = MemoryFileSystem().file('preview.jpeg')
        ..writeAsBytesSync((pictureDir.listSync().last as File).readAsBytesSync());

      pictureDir.listSync().forEach((f) => f.delete());
    } catch(e) {
    }
  }

  @override
  void initState() {
    super.initState();

    server = PreviewServer(port: 8080)..start();

    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }

      setState(() {});
    });

    startTimer();
  }

  @override
  void dispose() {
    controller?.dispose();
    stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: CameraPreview(controller),
    );
  }
}
