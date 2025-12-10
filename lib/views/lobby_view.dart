import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/matchmaking_controller.dart';
import '../views/replay_view.dart';

class LobbyView extends StatelessWidget {
  const LobbyView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = AuthController.instance;
    final MatchmakingController matchController = Get.put(MatchmakingController());

    const Color themeBeige = Color(0xFFF0D9B5);
    const Color themeBrown = Color(0xFF5D4037);

    return Scaffold(
      backgroundColor: themeBeige,
      appBar: AppBar(
        title: const Text("Chess Lobby", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: themeBrown,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authController.signOut(),
            tooltip: "Sign Out",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  const Icon(Icons.casino, size: 80, color: themeBrown),
                  const SizedBox(height: 10),
                  Obx(() => Text(
                    "Welcome,\n${authController.user?.email?.split('@')[0] ?? 'Player'}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: themeBrown),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 50),

            Obx(() {
              if (matchController.isSearching.value) {
                return Column(
                  children: const [
                    CircularProgressIndicator(color: themeBrown),
                    SizedBox(height: 20),
                    Text("Searching for opponent...", style: TextStyle(color: themeBrown, fontSize: 16)),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => matchController.joinQueue('classical'),
                      icon: const Icon(Icons.person),
                      label: const Text("Play Classical Chess"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: () => matchController.joinQueue('dice'),
                      icon: const Icon(Icons.casino),
                      label: const Text("Play Dice Chess"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    const Divider(color: themeBrown),
                    const SizedBox(height: 10),
                    
                    const Center(child: Text("Recent Games", style: TextStyle(color: themeBrown, fontWeight: FontWeight.bold))),                  ],
                );
              }
            }),
          ],
        ),
      ),
    );
  }
}
