import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/matchmaking_controller.dart'; 
import 'history_view.dart';

class LobbyView extends StatelessWidget {
  const LobbyView({super.key});

  @override
  Widget build(BuildContext context) {
    final MatchmakingController matchmakingController = Get.put(MatchmakingController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess Lobby'),
        actions: [
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
            const SizedBox(height: 30),

            Obx(() => ElevatedButton.icon(
              onPressed: matchmakingController.isSearching.value 
                  ? null 
                  : () {
                      matchmakingController.startMatchmaking();
                    },
              
              icon: matchmakingController.isSearching.value 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)
                    )
                  : const Icon(Icons.play_arrow),
              
              label: Text(
                matchmakingController.isSearching.value ? "Searching..." : "Play Game"
              ),
              
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            )),

            const SizedBox(height: 16),
            
            OutlinedButton.icon(
              onPressed: () {
                Get.to(() => const HistoryView());
              },
              icon: const Icon(Icons.history, color: Colors.brown),
              label: const Text("Past Games", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                side: const BorderSide(color: Colors.brown, width: 2),
              ),
            )
          ],
        ),
      ),
    );
  }
}
