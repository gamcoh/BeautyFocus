import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'constants.dart' as APP;

class Api {
  static Future<http.Response> sendImage (String path) async {
    File image = File(path);
    List<int> bytes = await FlutterImageCompress.compressWithList(image.readAsBytesSync());
    String imageb64 = base64Encode(bytes);
    String filename = path.split('/').last;

    const url = APP.api_url + '/postImage/';

    try {
      return http.post(
        url,
        body: <String, String>{
          'image': imageb64,
          'filename': filename
        }
      );
    } catch (e) {
      return Future.error(e);
    }
  } 
}