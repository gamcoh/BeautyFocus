import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';

import 'api.dart';
import 'DisplayPictureScreen.dart';

class TakePictureScreen extends StatefulWidget {
  final CameraDescription backCamera;
  final CameraDescription frontCamera;

  const TakePictureScreen({
    Key key,
    @required this.backCamera,
    @required this.frontCamera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  Widget _btnIcon = Icon(Icons.camera_alt);
  dynamic _isPressed = false;
  dynamic _useBackCamera = true;
  CameraDescription usedCamera;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    usedCamera = widget.backCamera;

    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      usedCamera,
      // Define the resolution to use.
      ResolutionPreset.ultraHigh,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return Scaffold(
      appBar: AppBar(title: Text('BeautyFocus')),
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.bottomCenter,
            child: FloatingActionButton(
              heroTag: 'takePicture',
              child: _btnIcon,
              // Provide an onPressed callback.
              onPressed: _isPressed ? null : () async {

                setState(() {
                  _isPressed = true;
                  _btnIcon = CircularProgressIndicator(
                    strokeWidth: 3.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  );
                });

                // Take the Picture in a try / catch block. If anything goes wrong,
                // catch the error.
                try {
                  // Ensure that the camera is initialized.
                  await _initializeControllerFuture;

                  // Construct the path where the image should be saved using the
                  // pattern package.
                  final path = join(
                    // Store the picture in the temp directory.
                    // Find the temp directory using the `path_provider` plugin.
                    (await getTemporaryDirectory()).path,
                    '${DateTime.now()}.png',
                  );

                  // Attempt to take a picture and log where it's been saved.
                  await _controller.takePicture(path);

                  final resp = await Api.sendImage(path);
                  final newImgPath = join(
                    // Store the picture in the temp directory.
                    // Find the temp directory using the `path_provider` plugin.
                    (await getTemporaryDirectory()).path,
                    '${DateTime.now()}_result.png',
                  );
                  File newImg = File(newImgPath);
                  newImg.writeAsBytesSync(resp.bodyBytes);

                  setState(() {
                    _isPressed = false;
                    _btnIcon = Icon(Icons.camera_alt);
                  });

                  // If the picture was taken, display it on a new screen.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DisplayPictureScreen(imagePath: newImgPath),
                    ),
                  );
                } catch (e) {
                  // If an error occurs, log the error to the console.
                  print(e);
                }
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: FloatingActionButton(
                heroTag: 'reverseCamera',
                mini: true,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.grey,
                child: Icon(Icons.switch_camera),
                onPressed: () {
                  setState(() {
                    _useBackCamera = !_useBackCamera;
                    usedCamera = _useBackCamera
                      ? widget.backCamera
                      : widget.frontCamera;

                    _controller = CameraController(usedCamera, ResolutionPreset.ultraHigh);
                    _initializeControllerFuture = _controller.initialize();
                  });
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}