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
        title: Text("Chat"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (ctx) => ProfileScreen(),
                ),
              );
            },
            icon: Icon(Icons.person),
          ),
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (ctx) => LoginScreen(),
                ),
              );
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("chatrooms")
            .where("participants", arrayContains: userId.uid)
            .orderBy("lastMessage.createdAt", descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No conversations found"));
          }

          return Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                    itemCount: snapshot.data!.docs.length,
                    separatorBuilder: (context, index) => Divider(
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
                            return SizedBox(); // Avoid showing empty data
                          }

                          if (!userSnapshot.hasData ||
                              !userSnapshot.data!.exists) {
                            return SizedBox();
                          }

                          var userDoc = userSnapshot.data!;
                          var userName = userDoc["username"];
                          var userProfilePic = userDoc["profilePic"];

                          return ListTile(
                            tileColor: const Color.fromARGB(255, 31, 30, 30),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5)),
                            leading: userProfilePic != null
                                ? CircleAvatar(
                                    radius: 25,
                                    backgroundImage:
                                        NetworkImage(userProfilePic),
                                  )
                                : CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Colors.grey,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.black,
                                    ),
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
                                SizedBox(height: 10),
                                unreadCounter == 0
                                    ? SizedBox(height: 10)
                                    : CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Colors.black,
                                        child: Text(
                                          "$unreadCounter",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10),
                                        ),
                                      ),
                              ],
                            ),
                            onTap: () {
                              // 🔥 Reset unreadCounter when opening chat
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
