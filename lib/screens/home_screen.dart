import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/widgets/chat_messages.dart';
import 'package:chat_app/widgets/new_messages.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.uid});
  final String uid;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => ChatScreen(),
              ),
            );
          },
          icon: Icon(Icons.arrow_back),
        ),
        title: Text("Chats"),
      ),
      body: Column(
        children: [
          Expanded(child: ChatMessages(receiverId: widget.uid)),
          NewMessages(receiverId: widget.uid),
        ],
      ),
    );
  }
}