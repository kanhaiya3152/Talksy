import 'package:chat_app/screens/chat_details_screen.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/screens/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final userId = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats",style: TextStyle(fontSize: 25,color: Colors.white),),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("chatrooms")
            .where("participants", arrayContains: userId.uid)
            .orderBy("lastMessage.createdAt", descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No conversations found"));
          }

          return Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                    itemCount: snapshot.data!.docs.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 10,
                      color: Colors.black,
                    ),
                    itemBuilder: (context, index) {
                      var chatRoomDoc = snapshot.data!.docs[index];
                      var chatRoomData =
                          chatRoomDoc.data() as Map<String, dynamic>;

                      // 🔥 Get receiver details
                      var participants =
                          chatRoomData["participants"] as List<dynamic>;
                      var receiverId =
                          participants.firstWhere((id) => id != userId.uid);
                      var lastMessage =
                          chatRoomData["lastMessage"] as Map<String, dynamic>?;
                      var unreadCounter = chatRoomData["unreadCounter"] != null
                          ? (chatRoomData["unreadCounter"][userId.uid] ?? 0)
                          : 0;

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection("users")
                            .doc(receiverId)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(); // Avoid showing empty data
                          }

                          if (!userSnapshot.hasData ||
                              !userSnapshot.data!.exists) {
                            return const SizedBox();
                          }

                          var userDoc = userSnapshot.data!;
                          var userName = userDoc["username"];
                          var userProfilePic = userDoc["profilePic"];

                          return ListTile(
                            tileColor: const Color.fromARGB(255, 31, 30, 30),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5)),
                            leading: userProfilePic != null && userProfilePic.isNotEmpty
                                ? CircleAvatar(
                                    radius: 25,
                                    backgroundImage:
                                        NetworkImage(userProfilePic),
                                  )
                                : CircleAvatar(
                                    radius: 25,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: Image.asset("assets/profile.jpg")),
                                  ),
                            title: Text(userName ?? 'No Name'),
                            subtitle: Text(
                              lastMessage != null
                                  ? lastMessage["text"]
                                  : "No messages yet",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  lastMessage == null
                                      ? ""
                                      : getTime(lastMessage["createdAt"]),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 10),
                                unreadCounter == 0
                                    ? const SizedBox(height: 10)
                                    : CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Colors.black,
                                        child: Text(
                                          "$unreadCounter",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10),
                                        ),
                                      ),
                              ],
                            ),
                            onTap: () {
                              //  Reset unreadCounter when opening chat
                              FirebaseFirestore.instance
                                  .collection("chatrooms")
                                  .doc(chatRoomDoc.id)
                                  .update({
                                "unreadCounter.${userId.uid}": 0,
                              });

                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) => ChatDetailScreen(
                                    receiverId: receiverId,
                                    receiverName: userName,
                                    receiverProfilePic: userProfilePic,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String getTime(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return DateFormat('hh:mm a').format(dateTime);
  }
}