import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:chat_app/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Uint8List? _image;
  String? _imageUrl;
  bool _isUploading = false;
  String username = "";
  String email = "";
  String bio = "";
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  final userId = FirebaseAuth.instance.currentUser;

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
  setState(() => _isUploading = true);

  try {
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/image.png').writeAsBytes(fileBytes);

    String? imageUrl = await uploadImageToCloudinary(file);

    if (imageUrl != null) {
      await saveImageUrlToFirestore(imageUrl);
      setState(() => _imageUrl = imageUrl);
    } else {
      debugPrint("Image upload failed");
    }
  } catch (e) {
    debugPrint("Error uploading image: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to upload image. Try again.")),
    );
  } finally {
    setState(() => _isUploading = false);
  }
}


  // Upload file to Cloudinary
  Future<String?> uploadImageToCloudinary(File imageFile) async {
    String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? ""; // Replace with your Cloudinary cloud name
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId!.uid)
          .set({
        'profilePic': imageUrl,
      }, SetOptions(merge: true));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Uploaded")));
    } on FirebaseException catch (e) {
      // print(e.hashCode);
      debugPrint("Nhi chl rha h");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("nhi chal rha ??")));
    }
  }

  // Fetch Image URL from Firestore
  Future<void> _fetchProfileImage() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId!.uid)
          .get();

      username = (userDoc.data() as Map<String, dynamic>)['username'];
      email = (userDoc.data() as Map<String, dynamic>)['email'];
      bio = (userDoc.data() as Map<String, dynamic>)['bio'] ?? "";

      if (userDoc.exists) {
        String? fetchedImageUrl = (userDoc.data()
            as Map<String, dynamic>?)?['profilePic']; // Safe access
        if (fetchedImageUrl != null && fetchedImageUrl.isNotEmpty) {
          setState(() {
            _imageUrl = fetchedImageUrl;
          });
        } else {
          // Set default profile picture if none exists
          await _setDefaultProfilePicture();
        }
      }
    } catch (e) {
      print("Error fetching profile image: $e");
    }
  }

  Future<void> _setDefaultProfilePicture() async {
  try {
    final ByteData bytes = await rootBundle.load('assets/profile.jpg'); 
    final Uint8List defaultImageBytes = bytes.buffer.asUint8List();

    String? defaultImageUrl = await uploadImageToCloudinary(
      await File('${(await getTemporaryDirectory()).path}/default.png')
          .writeAsBytes(defaultImageBytes),
    );

    if (defaultImageUrl != null) {
      await saveImageUrlToFirestore(defaultImageUrl);
      setState(() => _imageUrl = defaultImageUrl);
    }
  } catch (e) {
    debugPrint('Error setting default profile picture: $e');
  }
}


  Future<void> _getUserData() async {
    if (userId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId!.uid)
          .get();

      setState(() {
        email = userId!.email ?? "";
        username = userDoc['username'] ?? "No Username";
        bio = userDoc['bio'] ?? "";
        _usernameController.text = username;
        _bioController.text = bio;
      });
    }
  }

  Future<void> _updateUsername() async {
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId!.uid)
          .update({
        'username': _usernameController.text,
      });

      setState(() {
        username = _usernameController.text;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated successfully')),
      );
    }
  }

  Future<void> _updateBio() async {
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId!.uid)
          .update({
        'bio': _bioController.text,
      });

      setState(() {
        bio = _bioController.text;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bio updated successfully')),
      );
    }
  }

  void _showUpdateUsernameDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Username'),
          content: TextField(
            controller: _usernameController,
            decoration: const InputDecoration(hintText: "Enter new username"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateUsername();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateBioDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Bio'),
          content: TextField(
            controller: _bioController,
            decoration: const InputDecoration(hintText: "Enter new bio"),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateBio();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Do you want !'),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (ctx) => const LoginScreen(),
                          ),
                        );
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchProfileImage(); // Fetch image on screen load
    _getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text("Profile"),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            child: ListTile(
              leading: _isUploading
                  ? const SizedBox(
                      height: 10,
                      width: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
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
                                : CircleAvatar(
                                    radius: 40,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: Image.asset("assets/profile.jpg")),
                                  ),
                        Positioned(
                          bottom: -0,
                          left: 50,
                          child: Container(
                            height: 28,
                            width: 28,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(60),
                              // border: Border.all(),
                            ),
                            child: IconButton(
                              onPressed: _selectImage,
                              icon: const Icon(
                                Icons.camera_alt_sharp,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
              title: Text(
                username,
                style: const TextStyle(fontSize: 20),
              ),
              subtitle: bio.isNotEmpty ? Text(bio) : const Text("Add bio"),
            ),
          ),
          // if (_isUploading) CircularProgressIndicator(),
          const SizedBox(
            height: 10,
          ),
          const Divider(),
          const SizedBox(
            height: 10,
          ),
          Container(
            height: MediaQuery.of(context).size.height / 2.35,
            width: double.infinity,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 20, right: 20, top: 10, bottom: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Name",
                              style:
                                  TextStyle(fontSize: 20, color: Colors.white),
                            ),
                            TextButton(
                                onPressed: _showUpdateUsernameDialog,
                                child: const Text("Edit")),
                          ],
                        ),
                        Text(
                          username,
                          style: const TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                      ],
                    ),
                    const Divider(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Email",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                        Text(email,
                            style:
                                const TextStyle(fontSize: 18, color: Colors.white70)),
                      ],
                    ),
                    const Divider(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Bio",
                              style:
                                  TextStyle(fontSize: 20, color: Colors.white),
                            ),
                            TextButton(
                                onPressed: _showUpdateBioDialog,
                                child: const Text("Edit"))
                          ],
                        ),
                        GestureDetector(
                          onTap: _showUpdateBioDialog,
                          child: Text(
                            bio.isNotEmpty ? bio : "Add bio",
                            style:
                                const TextStyle(fontSize: 18, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(
                      height: 5,
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "About",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 17,
                          color: Colors.white70,
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    const Divider(),
                    const SizedBox(
                      height: 5,
                    ),
                    GestureDetector(
                      onTap: _logout,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Logout",
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 17,
                            color: Colors.white70,
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}