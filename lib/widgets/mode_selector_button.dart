import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/matchmaking_controller.dart';
import '../controllers/sound_controller.dart';

class ModeSelectorButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String mode;
  final MatchmakingController controller;

  const ModeSelectorButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.mode,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Stack(
        children: [
          Positioned.fill(
            child: Obx(() {
              bool isLoadingThis = controller.searchingMode.value == mode;
              bool isAnyLoading = controller.searchingMode.value.isNotEmpty;

              VoidCallback? onPressedLogic;
              Color buttonColor = color;
              Widget content;

              if (isLoadingThis) {
                buttonColor = Colors.redAccent;
                onPressedLogic = () {
                  SoundController.instance.playCancel();
                  controller.cancelMatchmaking();
                };
                content = const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    SizedBox(width: 12),
                    Text("Cancel", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                );
              } else if (!isAnyLoading) {
                onPressedLogic = () {
                  SoundController.instance.playClick();
                  controller.startMatchmaking(mode);
                };
                content = Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 24),
                    const SizedBox(width: 12),
                    Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                );
              } else {
                onPressedLogic = null;
                content = Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 24),
                    const SizedBox(width: 12),
                    Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                );
              }

              return ElevatedButton(
                onPressed: onPressedLogic,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[500],
                  elevation: isLoadingThis || !isAnyLoading ? 3 : 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.zero,
                ),
                child: content,
              );
            }),
          ),

          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Obx(() => controller.searchingMode.value == mode
                ? const SizedBox()
                : IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.white70),
                    tooltip: "Rules",
                    onPressed: () {
                      SoundController.instance.playClick();
                      _showRulesDialog();
                    },
                  )),
          )
        ],
      ),
    );
  }

  void _showRulesDialog() {
    String content = "";
    switch (mode) {
      case 'classical':
        content = "Standard Chess Rules apply.\n\nTime to prove who is the true grandmaster of the office!";
        break;
      case 'dice':
        content = "Roll 3 Dice each turn!\n\nYou can ONLY move pieces that match the dice values:\n\n♙ Pawn: 1\n♘ Knight: 2\n♗ Bishop: 3\n♖ Rook: 4\n♕ Queen: 5\n♔ King: 6\n\nIf you have no legal moves, you must Pass.";
        break;
      case 'vegas':
        content = "High Stakes, variable moves!\n\nRoll 1 Die to determine your turn:\n\n🎲 1-2 = 1 Move\n🎲 3-4 = 2 Moves\n🎲 5-6 = 3 Moves\n\n⚠️ IMPORTANT: If you Check your opponent, your turn ends immediately, even if you had moves left!";
        break;
      case 'boa':
        content = "The Ultimate Chaos!\n\n• You ALWAYS get 3 Dice & 3 Moves.\n• You must use the dice to move specific pieces.\n• You can pass if stuck, but try to use all 3!\n\n⚠️ IMPORTANT: If you Check your opponent, your turn ends immediately!";
        break;
    }

    Get.defaultDialog(
      title: label,
      titleStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          content,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
      confirm: ElevatedButton(
        onPressed: () {
          SoundController.instance.playClick();
          Get.back();
        },
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037), foregroundColor: Colors.white),
        child: const Text("Got it!"),
      ),
      radius: 10,
    );
  }
}
