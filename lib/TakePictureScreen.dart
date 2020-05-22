import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_awesome_alert_box/flutter_awesome_alert_box.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

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
  dynamic _isPressed = false;
  dynamic _useBackCamera = true;
  CameraDescription usedCamera;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  File _previewImage;

  @override
  void initState() {
    super.initState();

    // init the notifications
    var initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIos = IOSInitializationSettings();
    var initializationSettings = InitializationSettings(initializationSettingsAndroid, initializationSettingsIos);
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // To display the current output from the Camera,
    // create a CameraController.
    usedCamera = widget.backCamera;

    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      usedCamera,
      // Define the resolution to use.
      ResolutionPreset.medium
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

  Future _showNotification({String title='<b>Success</b>', String content}) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      '0',
      'main_channel',
      'main channel of the application',
      playSound: false,
      importance: Importance.Max,
      priority: Priority.High,
      styleInformation: DefaultStyleInformation(true, true)
    );
    var iOSPlatformChannelSpecifics =
        new IOSNotificationDetails(presentSound: false);
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      content,
      platformChannelSpecifics,
      payload: 'No_Sound',
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return Scaffold(
      appBar: AppBar(title: Text('BeautyFocus'),),
      body: Stack(
        children: <Widget>[
          // Wait until the controller is initialized before displaying the
          // camera preview. Use a FutureBuilder to display a loading spinner
          // until the controller has finished initializing.
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // If the Future is complete, display the preview.
                return CameraPreview(_controller);
              } else {
                // Otherwise, display a loading indicator.
                return Center(child: CircularProgressIndicator());
              }
            }
          ),
          DisplayPictureScreen(image: _previewImage),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.bottomCenter,
            child: FloatingActionButton(
              heroTag: 'savePicture',
              child: _isPressed ? CircularProgressIndicator(
                strokeWidth: 3.0,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ) : Icon(Icons.camera_alt),
              // Provide an onPressed callback.
              onPressed: _isPressed ? null : () async {
                setState(() {
                  _isPressed = true;
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
                    _previewImage = newImg;
                  });
                } catch (e) {
                  setState(() {
                    _isPressed = false;
                  });
                  DangerBgAlertBox(
                    context: context,
                    title: 'A problem occured',
                    infoMessage: 'Oops! Maybe try another time? sorry...'
                  );
                }
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Visibility(
              visible: _previewImage != null,
              child: FloatingActionButton(
                heroTag: 'savePicture',
                backgroundColor: Colors.deepOrange,
                child: Icon(Icons.save_alt),
                onPressed: () async {
                  try {
                    if (await Permission.storage.request().isGranted) { 
                      await ImageGallerySaver.saveImage(_previewImage.readAsBytesSync());
                      _showNotification(content: 'The image was saved in your library');
                      setState(() {
                        _previewImage = null;
                      });
                    }
                  } catch (e) {
                    print(e);
                  }
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Visibility(
              visible: _previewImage != null,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'discardImage',
                backgroundColor: Colors.red,
                child: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _previewImage = null;
                  });
                },
              ),
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

                    _controller = CameraController(usedCamera, ResolutionPreset.medium);
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
