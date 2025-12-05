import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/history_controller.dart';
import '../controllers/replay_controller.dart';
import '../views/replay_view.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final HistoryController controller = Get.put(HistoryController());

    const Color bgBeige = Color(0xFFF0D9B5); 
    const Color textBrown = Color(0xFF5D4037);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Match History", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: bgBeige,
        foregroundColor: textBrown,
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: textBrown));
        }

        if (controller.allGames.isEmpty) {
          return const Center(
            child: Text("No games played yet!", style: TextStyle(color: Colors.grey, fontSize: 18)),
          );
        }

        return ListView.builder(
          itemCount: controller.allGames.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            var gameDoc = controller.allGames[index];
            var data = gameDoc.data() as Map<String, dynamic>;
            
            String whiteName = data['whiteName'] ?? "Unknown";
            String blackName = data['blackName'] ?? "Unknown";
            String result = controller.getResultText(data);
            
            String dateText = "Unknown Date";
            if (data['date'] != null) {
               DateTime dt = (data['date'] as Timestamp).toDate();
               dateText = DateFormat.yMMMd().add_jm().format(dt);
            }

            Color statusColor;
            Color bgColor;
            
            if (result == "You Won") {
              statusColor = Colors.green;
              bgColor = Colors.green.shade100;
            } else if (result == "You Lost") {
              statusColor = Colors.red;
              bgColor = Colors.red.shade100;
            } else if (result == "Draw") {
              statusColor = Colors.orange;
              bgColor = Colors.orange.shade100;
            } else {
              statusColor = Colors.blue;
              bgColor = Colors.blue.shade100;
            }

            return Dismissible(
              key: Key(gameDoc.id),
              direction: DismissDirection.endToStart, 
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.white, size: 30),
              ),
              onDismissed: (direction) {
                controller.deleteGame(gameDoc.id);
                Get.snackbar("Deleted", "Game removed from history", duration: const Duration(seconds: 1));
              },
              child: Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.emoji_events, color: statusColor),
                  ),
                  
                  title: Text(
                    "$whiteName vs $blackName",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(result, style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor.withOpacity(0.8),
                      )),
                      Text(dateText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    final replayController = Get.put(ReplayController());
                    replayController.loadGame(data);
                    Get.to(() => const ReplayView());
                  },
                ),
              ),
            );
          },
        );
      }),
    );
  }
}