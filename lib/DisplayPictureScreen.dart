import 'dart:io';

import 'package:flutter/material.dart';

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final File image;

  const DisplayPictureScreen({Key key, this.image}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return Image.file(image);
    }
    return Container();
  }
}