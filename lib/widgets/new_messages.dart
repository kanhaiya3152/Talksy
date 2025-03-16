import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewMessages extends StatefulWidget {
  final String receiverId;

  const NewMessages({required this.receiverId, super.key});

  @override
  State<NewMessages> createState() => _NewMessagesState();
}

class _NewMessagesState extends State<NewMessages> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String chatRoomId = "";

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

  final chatRoomRef = FirebaseFirestore.instance.collection("chatrooms").doc(chatRoomId);

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


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 15, right: 1, bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              decoration: InputDecoration(labelText: "Send a message ..."),
            ),
          ),
          IconButton(onPressed: _submitMessage, icon: Icon(Icons.send)),
        ],
      ),
    );
  }
}