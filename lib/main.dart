import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/game_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);

  Get.put(AuthController());
  Get.put(GameController());

  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Chess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text("Firebase is Initialized! ✅"),
        ),
      ),
    );
  }
}
