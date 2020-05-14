import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'TakePictureScreen.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final backCamera = cameras.firstWhere((element) => element.lensDirection == CameraLensDirection.back);
  final frontCamera = cameras.firstWhere((element) => element.lensDirection == CameraLensDirection.front);

  runApp(
    MaterialApp(
      theme: ThemeData.light(),
      home: TakePictureScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        backCamera: backCamera,
        frontCamera: frontCamera
      ),
    ),
  );
}
