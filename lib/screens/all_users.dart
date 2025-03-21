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
        title: const Text("Users"),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users found"));
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
                      var userDoc = snapshot.data!.docs[index];
                      var userName = userDoc['username'];
                      var userProfilePic = userDoc['profilePic'];
                      var userUid = userDoc['uid'];

                      // Skip the current user
                      if (userUid == userId.uid) {
                        return const SizedBox();
                      }

                      return ListTile(
                        tileColor: const Color.fromARGB(255, 31, 30, 30),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)),
                        leading: userProfilePic != null &&
                                userProfilePic.isNotEmpty
                            ? CircleAvatar(
                                radius: 25,
                                backgroundImage: NetworkImage(userProfilePic),
                              )
                            : CircleAvatar(
                                radius: 25,
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: Image.asset("assets/profile.jpg")),
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
