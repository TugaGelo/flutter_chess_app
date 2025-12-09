import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter_chess_app/models/user_model.dart' as model;
import '../views/auth_view.dart';
import '../views/lobby_view.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();
  late Rx<User?> _firebaseUser;
  
  Rxn<model.UserModel> firestoreUser = Rxn<model.UserModel>();
  
  User? get user => _firebaseUser.value;

  @override
  void onReady() {
    super.onReady();
    _firebaseUser = Rx<User?>(FirebaseAuth.instance.currentUser);
    _firebaseUser.bindStream(FirebaseAuth.instance.authStateChanges());
    
    ever(_firebaseUser, _setInitialScreen);
  }

  _setInitialScreen(User? user) async {
    if (user == null) {
      Get.offAll(() => const AuthView());
    } else {
      try {
        DocumentSnapshot snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (snap.exists) {
          firestoreUser.value = model.UserModel.fromSnap(snap);
          print("User is logged in: ${firestoreUser.value!.username}"); 
        }
      } catch (e) {
        print("Error fetching user profile: $e");
      }
      
      Get.offAll(() => const LobbyView()); 
    }
  }

  // SIGN UP FUNCTION
  Future<void> signUp(String username, String email, String password) async {
    try {
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      model.UserModel userModel = model.UserModel(
        uid: cred.user!.uid,
        email: email,
        username: username,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set(userModel.toJson());
      
      firestoreUser.value = userModel;

      print("Success: Account created successfully!");
      
    } catch (e) {
      print("Error Creating Account: $e");
    }
  }

  // SIGN IN FUNCTION
  Future<void> login(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("Success: Welcome back!");
    } catch (e) {
      print("Login Failed: $e");
    }
  }

  // SIGN OUT FUNCTION
  void signOut() {
    FirebaseAuth.instance.signOut();
    firestoreUser.value = null; 
  }
}
