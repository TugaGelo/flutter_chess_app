import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';
import '../views/lobby_view.dart';
import '../controllers/sound_controller.dart';

class GameDialogs {
  
  static void showGameOver(String title, String subtitle, VoidCallback onRematch) {
    Get.defaultDialog(
      title: title,
      titleStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
      backgroundColor: const Color(0xFFF0D9B5),
      radius: 12,
      content: Column(
        children: [
          const Icon(Icons.emoji_events, size: 60, color: Color(0xFFB58863)),
          const SizedBox(height: 12),
          Text(subtitle, style: const TextStyle(fontSize: 18, color: Color(0xFF5D4037), fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
        ],
      ),
      barrierDismissible: false, 
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () => Get.offAll(() => const LobbyView()),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF5D4037), width: 2),
                  foregroundColor: const Color(0xFF5D4037),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text("Lobby", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Get.back();
                  onRematch();
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text("Rematch", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB58863),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 4,
                ),
              ),
            ],
          ),
        )
      ]
    );
  }

  static Future<String?> showPromotion(bool isWhite) async {
    return await Get.dialog<String>(
      SimpleDialog(
        title: const Text('Promote to:', textAlign: TextAlign.center),
        backgroundColor: const Color(0xFFF0D9B5),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _promoOption('q', isWhite ? WhiteQueen() : BlackQueen()),
              _promoOption('r', isWhite ? WhiteRook() : BlackRook()),
              _promoOption('b', isWhite ? WhiteBishop() : BlackBishop()),
              _promoOption('n', isWhite ? WhiteKnight() : BlackKnight()),
            ],
          )
        ],
      ),
      barrierDismissible: false,
    );
  }

  static Widget _promoOption(String char, Widget icon) {
    return InkWell(
      onTap: () => Get.back(result: char),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(width: 50, height: 50, child: icon),
      ),
    );
  }

  static void showConfirmation({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    Get.defaultDialog(
      title: title,
      titleStyle: const TextStyle(color: Color(0xFF5D4037), fontWeight: FontWeight.bold),
      middleText: content,
      textConfirm: confirmText,
      textCancel: "Cancel",
      buttonColor: confirmColor,
      confirmTextColor: Colors.white,
      cancelTextColor: const Color(0xFF5D4037),
      onConfirm: () {
        Get.back();
        onConfirm();
      }
    );
  }
}
