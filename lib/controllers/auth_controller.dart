import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter_chess_app/models/user_model.dart' as model;
import '../views/auth_view.dart';
import '../views/lobby_view.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();
  late Rx<User?> _firebaseUser;
  
  User? get user => _firebaseUser.value;

  @override
  void onReady() {
    super.onReady();
    _firebaseUser = Rx<User?>(FirebaseAuth.instance.currentUser);
    _firebaseUser.bindStream(FirebaseAuth.instance.authStateChanges());
    
    ever(_firebaseUser, _setInitialScreen);
  }

  _setInitialScreen(User? user) {
    if (user == null) {
      print("User is logged out");
      Get.offAll(() => const AuthView());
    } else {
      print("User is logged in: ${user.email}");
      Get.offAll(() => const LobbyView()); 
    }
  }
  
  // SIGN UP
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

      Get.snackbar("Success", "Account created successfully!");
      
    } catch (e) {
      Get.snackbar("Error Creating Account", e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // SIGN IN
  Future<void> login(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Get.snackbar("Success", "Welcome back!");
    } catch (e) {
      Get.snackbar("Login Failed", e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // SIGN OUT
  void signOut() {
    FirebaseAuth.instance.signOut();
  }
}
