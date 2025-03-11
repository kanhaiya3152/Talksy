import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Uint8List? _image;
  String? _imageUrl;
  bool _isUploading = false;

  String userId = FirebaseAuth.instance.currentUser!.uid;

  // Function to pick an image
  Future<Uint8List?> pickImage(ImageSource source) async {
    final ImagePicker imagePicker = ImagePicker();
    XFile? file = await imagePicker.pickImage(source: source);

    if (file != null) {
      return await file.readAsBytes();
    }

    print("No image selected");
    return null;
  }

  // Show options to pick an image
  Future<void> _selectImage() async {
    Uint8List? im = await pickImage(ImageSource.gallery);
    if (im != null) {
      setState(() {
        _image = im;
      });

      await _uploadImageToCloudinary(im);
    }
  }

  // Upload image to Cloudinary
  Future<void> _uploadImageToCloudinary(Uint8List fileBytes) async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Convert Uint8List to File
      final tempDir = await getTemporaryDirectory();
      final file =
          await File('${tempDir.path}/image.png').writeAsBytes(fileBytes);

      // Call the Cloudinary upload function
      String? imageUrl = await uploadImageToCloudinary(file);

      if (imageUrl != null) {
        setState(() {
          _imageUrl = imageUrl;
          _image = null; // Clear local image
        });
      } else {
        print("Image upload failed");
      }

      if (imageUrl != null) {
        setState(() {
          _imageUrl = imageUrl;
          _image = null; // Clear local image
        });
        // Save the URL to Firestore
        await saveImageUrlToFirestore(imageUrl);
      }
    } catch (e) {
      print("Error uploading image: $e");
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Upload file to Cloudinary
  Future<String?> uploadImageToCloudinary(File imageFile) async {
    String cloudName = "dn30ixuij"; // Replace with your Cloudinary cloud name
    String uploadPreset = "upload_file"; // Replace with your upload preset

    final cloudinaryUrl =
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

    var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl));
    request.fields['upload_preset'] = uploadPreset;
    request.files
        .add(await http.MultipartFile.fromPath('file', imageFile.path));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    var jsonResponse = json.decode(responseData);

    if (response.statusCode == 200) {
      return jsonResponse['secure_url']; // Cloudinary URL
    } else {
      print("Upload failed: ${jsonResponse['error']}");
      return null;
    }
  }

  // Save Image URL to Firestore
  Future<void> saveImageUrlToFirestore(String imageUrl) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'profilePic': imageUrl,
      }, SetOptions(merge: true));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Uploded")));
    } on FirebaseException catch (e) {
      // print(e.hashCode);
      debugPrint("Nhi chl rha h");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("nhi chal rha ??")));
    }
  }

  // Fetch Image URL from Firestore
  Future<void> _fetchProfileImage() async {
  try {
    DocumentSnapshot userDoc = 
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      String? fetchedImageUrl = (userDoc.data() as Map<String, dynamic>?)?['profilePic']; // Safe access
      if (fetchedImageUrl != null) {
        setState(() {
          _imageUrl = fetchedImageUrl;
        });
      }
    }
  } catch (e) {
    print("Error fetching profile image: $e");
  }
}

@override
void initState() {
  super.initState();
  _fetchProfileImage(); // Fetch image on screen load
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text("Profile"),
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 10),
            child: ListTile(
              leading: _isUploading
                  ? SizedBox(
                      height: 10,
                      width: 10,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ))
                  : Stack(
                      children: [
                        _imageUrl != null
                            ? CircleAvatar(
                                radius: 40,
                                backgroundImage: NetworkImage(_imageUrl!),
                              )
                            : _image != null
                                ? CircleAvatar(
                                    radius: 40,
                                    backgroundImage: MemoryImage(_image!),
                                  )
                                : const CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Colors.grey,
                                    child: Icon(Icons.person),
                                  ),
                        Positioned(
                          bottom: -0,
                          left: 45,
                          child: IconButton(
                            onPressed: _selectImage,
                            icon: const Icon(
                              Icons.camera_alt_sharp,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
              title: Text("Karan"),
              subtitle: Text("Hello babe, what's going on?"),
            ),
          ),
          // if (_isUploading) CircularProgressIndicator(),
          Divider(),
          Container(
            child: Card(
              child: Column(
                children: [
                  Text("Karan Kumar ......."),
                  Text("Hello............ "),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
