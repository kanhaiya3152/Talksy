import 'package:chat_app/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatMessages extends StatefulWidget {
  final String receiverId;

  const ChatMessages({required this.receiverId, super.key});

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  late String chatRoomId;

  @override
  void initState() {
    super.initState();
    setupPushNotifications();

    final authenticatedUser = FirebaseAuth.instance.currentUser!;
    chatRoomId = (authenticatedUser.uid.hashCode > widget.receiverId.hashCode)
        ? "${authenticatedUser.uid}_${widget.receiverId}"
        : "${widget.receiverId}_${authenticatedUser.uid}";
  }

  void setupPushNotifications() async {
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission();
    fcm.subscribeToTopic("chat_$chatRoomId");
  }

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser!;

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoomId)
          .collection("messages")
          .orderBy('createdAt', descending: false) // Ascending order
          .snapshots(),
      builder: (ctx, chatSnapshots) {
        if (chatSnapshots.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (chatSnapshots.hasError) {
          return Center(child: Text("Something went wrong. Please try again."));
        }

        if (!chatSnapshots.hasData || chatSnapshots.data!.docs.isEmpty) {
          return Center(child: Text("No messages found."));
        }

        final loadedMessages = chatSnapshots.data!.docs;

        // Group messages by date
        Map<String, List<QueryDocumentSnapshot>> groupedMessages = {};
        for (var message in loadedMessages) {
          final date = (message['createdAt'] as Timestamp).toDate();
          final dateString = DateFormat('yyyy-MM-dd').format(date);
          groupedMessages.putIfAbsent(dateString, () => []).add(message);
        }

        List<Widget> messageWidgets = [];
        groupedMessages.forEach((dateString, messages) {
          final date = DateFormat('yyyy-MM-dd').parse(dateString);
          final displayDate = _getDateString(date);

          // Add date header
          messageWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text(
                  displayDate,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
            ),
          );

          // Add messages
          for (var i = 0; i < messages.length; i++) {
            final chatMessage = messages[i].data() as Map<String, dynamic>;
            final DateTime timestamp = (chatMessage['createdAt'] as Timestamp).toDate();
            final currentMessageUserId = chatMessage["senderId"];
            final previousMessageUserId = i > 0 ? messages[i - 1]["senderId"] : null;

            if (previousMessageUserId == currentMessageUserId) {
              messageWidgets.add(MessageBubble.next(
                message: chatMessage['text'],
                isMe: authenticatedUser.uid == currentMessageUserId,
                timestamp: Timestamp.fromDate(timestamp),
              ));
            } else {
              messageWidgets.add(MessageBubble.first(
                username: chatMessage['username'],
                message: chatMessage['text'],
                userImage: chatMessage['userimage'],
                isMe: authenticatedUser.uid == currentMessageUserId,
                timestamp: Timestamp.fromDate(timestamp),
              ));
            }
          }
        });

        return ListView(
          padding: EdgeInsets.only(bottom: 40, left: 13, right: 13),
          reverse: true, // Messages are already in correct order
          children: messageWidgets.reversed.toList(),
        );
      },
    );
  }

  String _getDateString(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateFormat('EEEE').format(date); // Day of the week
  }
}
