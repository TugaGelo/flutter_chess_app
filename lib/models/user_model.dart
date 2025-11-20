import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
  });

  // Convert our User object to a JSON map (for sending to Firebase)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
    };
  }

  // Create a User object from a Firestore snapshot (for receiving from Firebase)
  factory UserModel.fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return UserModel(
      uid: snapshot['uid'],
      email: snapshot['email'],
      username: snapshot['username'],
    );
  }
}