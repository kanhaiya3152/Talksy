import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/widgets/new_messages.dart';
import 'package:chat_app/widgets/chat_messages.dart';

class ChatDetailScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? receiverProfilePic;

  const ChatDetailScreen({
    required this.receiverId,
    required this.receiverName,
    this.receiverProfilePic,
    super.key,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            widget.receiverProfilePic != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(widget.receiverProfilePic!),
                  )
                : CircleAvatar(
                    child: Icon(Icons.person),
                  ),
            SizedBox(width: 10),
            Text(widget.receiverName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatMessages(receiverId: widget.receiverId),
          ),
          NewMessages(receiverId: widget.receiverId),
        ],
      ),
    );
  }
}