// uploading files to cloudinary

import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

Future<bool> uploadToCloudinary(XFile? image) async {
  if (image == null) {
    print("No Image selected");
    return false;
  }

  File file = File(image.path);

  String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';

  // Creates a multipart Request to upload a file
  var uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
  var request = http.MultipartRequest("POST", uri);

  // Read the file as bytes
  var fileBytes = await file.readAsBytes();

  var multipartFile = http.MultipartFile.fromBytes('file', fileBytes,
      filename: file.path.split("/").last);

  // Add the file part to the request
  request.files.add(multipartFile);

  request.fields['upload_preset'] = "upload_file";
  request.fields['resource_type'] = "image";

  // Send the request and await the response
  var response = await request.send();

  var responseBody = await response.stream.bytesToString();

  print(responseBody);

  if (response.statusCode == 200) {
    print("Upload successfully");
    return true;
  } else {
    print("Upload failed with status: ${response.statusCode}");
    return false;
  }
}