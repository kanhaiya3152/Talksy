import 'package:cloud_firestore/cloud_firestore.dart';

class Users {
  final String uid;
  final String username;
  final String email;

  Users({
    required this.uid,
    required this.username,
    required this.email,
  });

  static Users fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>?;

    if (snapshot == null) {
      throw Exception("Snapshot data is null");
    }

    return Users(
      uid: snapshot['uid'] ?? '',
      username: snapshot['username'] ?? '',
      email: snapshot['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "username": username,
        "email": email,
      };
}