import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/screens/chat_details_screen.dart';

class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({super.key});

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  final userId = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Users"),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No users found"));
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
                      var userDoc = snapshot.data!.docs[index];
                      var userName = userDoc['username'];
                      var userProfilePic = userDoc['profilePic'];
                      var userUid = userDoc['uid'];

                      // Skip the current user
                      if (userUid == userId.uid) {
                        return SizedBox();
                      }

                      return ListTile(
                        tileColor: const Color.fromARGB(255, 31, 30, 30),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)),
                        leading: userProfilePic != null
                            ? CircleAvatar(
                                radius: 25,
                                backgroundImage: NetworkImage(userProfilePic),
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
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => ChatDetailScreen(
                                receiverId: userUid,
                                receiverName: userName,
                                receiverProfilePic: userProfilePic,
                              ),
                            ),
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
}