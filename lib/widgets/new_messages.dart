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

    FirebaseFirestore.instance.collection("chats").add({
      "text": enteredMessage,
      "createdAt": Timestamp.now(),
      "senderId": userId,
      "receiverId": widget.receiverId,
      "username": userData.data()!["username"],
      "userimage": userData.data()!["profilePic"],
      "participants": [userId, widget.receiverId],
    });
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