import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';

class LobbyView extends StatelessWidget {
  const LobbyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess Lobby'),
        actions: [
          // LOGOUT BUTTON
          IconButton(
            onPressed: () {
              AuthController.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome, Grandmaster! ♟️",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                print("Play button clicked");
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text("Play Game"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            )
          ],
        ),
      ),
    );
  }
}
