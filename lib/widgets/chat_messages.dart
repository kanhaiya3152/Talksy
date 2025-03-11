import 'package:chat_app/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class ChatMessages extends StatefulWidget {
  final String receiverId;

  const ChatMessages({required this.receiverId, super.key});

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  void setupPushNotifications() async {
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission();
    // final token = await fcm.getToken();
    // print(token);

    fcm.subscribeToTopic("chats");
  }

  @override
  void initState() {
    super.initState();
    setupPushNotifications();
  }

  final userId = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser!;

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("chats")
          .where('participants', arrayContains: authenticatedUser.uid)
          .snapshots(),
      builder: (ctx, chatSnapshots) {
        if (chatSnapshots.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!chatSnapshots.hasData || chatSnapshots.data!.docs.isEmpty) {
          return Center(
            child: Text("No messages found."),
          );
        }
        if (chatSnapshots.hasError) {
          return Center(
            child: Text("Something went wrong."),
          );
        }

        final loadedMessages = chatSnapshots.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['senderId'] == authenticatedUser.uid && data['receiverId'] == widget.receiverId) ||
                 (data['senderId'] == widget.receiverId && data['receiverId'] == authenticatedUser.uid);
        }).toList();

        return ListView.builder(
          padding: EdgeInsets.only(bottom: 40, left: 13, right: 13),
          reverse: true,
          itemCount: loadedMessages.length,
          itemBuilder: (ctx, index) {
            final chatMessage = loadedMessages[index].data() as Map<String, dynamic>;
            final nextChatMessage = index + 1 < loadedMessages.length
                ? loadedMessages[index + 1].data() as Map<String, dynamic>
                : null;
            final currentMessageUserId = chatMessage["senderId"];
            final nextMessageUserId =
                nextChatMessage != null ? nextChatMessage["senderId"] : null;

            final nextUserIsSame = nextMessageUserId == currentMessageUserId;

            if (nextUserIsSame) {
              return MessageBubble.next(
                message: chatMessage['text'],
                isMe: authenticatedUser.uid == currentMessageUserId,
                timestamp: chatMessage['createdAt'],
              );
            } else {
              return MessageBubble.first(
                username: chatMessage['username'],
                message: chatMessage['text'],
                userImage: chatMessage['userimage'],
                isMe: authenticatedUser.uid == currentMessageUserId,
                timestamp: chatMessage['createdAt'],
              );
            }
          },
        );
      },
    );
  }
}