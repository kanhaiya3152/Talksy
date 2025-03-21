import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NewMessages extends StatefulWidget {
  final String receiverId;

  const NewMessages({required this.receiverId, super.key});

  @override
  State<NewMessages> createState() => _NewMessagesState();
}

class _NewMessagesState extends State<NewMessages> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  String chatRoomId = "";

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitMessage() async {
    final enteredMessage = _messageController.text;

    if (enteredMessage.trim().isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();
    _messageController.clear();

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userData =
        await FirebaseFirestore.instance.collection("users").doc(userId).get();

    // 🔥 Create chatRoomId based on sorted user IDs
    if (userId.hashCode > widget.receiverId.hashCode) {
      chatRoomId = "${userId}_${widget.receiverId}";
    } else {
      chatRoomId = "${widget.receiverId}_${userId}";
    }

    final messageData = {
      "text": enteredMessage,
      "createdAt": Timestamp.now(),
      "senderId": userId,
      "receiverId": widget.receiverId,
      "username": userData.data()!["username"],
      "userimage": userData.data()!["profilePic"],
      "participants": [userId, widget.receiverId],
      "read": false,
    };

    final chatRoomRef =
        FirebaseFirestore.instance.collection("chatrooms").doc(chatRoomId);

    // 🔥 Add message to messages collection inside chatroom
    await chatRoomRef.collection("messages").add(messageData);

    // 🔥 Update lastMessage and unreadCounter in chatroom document
    await chatRoomRef.set({
      "lastMessage": messageData,
      "unreadCounter": {
        userId: 0, // Reset sender's unread count
        widget.receiverId: FieldValue.increment(1) // Increment receiver's unread count
      },
      "participants": [userId, widget.receiverId],
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> _sendImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      return; // User canceled image selection
    }

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userData =
        await FirebaseFirestore.instance.collection("users").doc(userId).get();

    // 🔥 Create chatRoomId based on sorted user IDs
    if (userId.hashCode > widget.receiverId.hashCode) {
      chatRoomId = "${userId}_${widget.receiverId}";
    } else {
      chatRoomId = "${widget.receiverId}_${userId}";
    }

    final chatRoomRef =
        FirebaseFirestore.instance.collection("chatrooms").doc(chatRoomId);

    try {
      // 🔥 Upload image to Cloudinary
      final imageUrl = await _uploadImageToCloudinary(File(pickedFile.path));

      if (imageUrl != null) {
        final messageData = {
          "text": "", // Empty text for image messages
          "imageUrl": imageUrl,
          "createdAt": Timestamp.now(),
          "senderId": userId,
          "receiverId": widget.receiverId,
          "username": userData.data()!["username"],
          "userimage": userData.data()!["profilePic"],
          "participants": [userId, widget.receiverId],
          "read": false,
        };

        // Add image message to messages collection inside chatroom
        await chatRoomRef.collection("messages").add(messageData);

        //  Update lastMessage and unreadCounter in chatroom document
        await chatRoomRef.set({
          "lastMessage": messageData,
          "unreadCounter": {
            userId: 0, // Reset sender's unread count
            widget.receiverId: FieldValue.increment(1) // Increment receiver's unread count
          },
          "participants": [userId, widget.receiverId],
          "updatedAt": Timestamp.now(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send image. Please try again.")),
      );
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? ""; // Replace with your Cloudinary cloud name
    String uploadPreset = "upload_file"; // Replace with your upload preset

    final cloudinaryUrl =
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

    try {
      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl));
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url']; // Cloudinary URL
      } else {
        print("Upload failed: ${jsonResponse['error']}");
        return null;
      }
    } catch (e) {
      print("Error uploading to Cloudinary: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 1, bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              decoration: const InputDecoration(labelText: "Send a message ..."),
            ),
          ),
          IconButton(
            onPressed: _sendImage,
            icon: const Icon(Icons.image,size: 30,),
          ),
          IconButton(onPressed: _submitMessage, icon: const Icon(Icons.send)),
        ],
      ),
    );
  }
}