import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';
import '../utils/game_dialogs.dart';
import '../widgets/game/dice_row.dart';
import '../widgets/game/move_list_bar.dart';
import '../widgets/game/animatable_chess_board.dart';

class GameView extends StatelessWidget {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameController.instance;
    final ScrollController moveListScrollController = ScrollController();

    ever(controller.currentMoveIndex, (index) {
      if (moveListScrollController.hasClients && index > 0) {
        double rowIndex = (index / 2).floorToDouble();
        double targetOffset = (rowIndex - 1) * 100.0;
        if (targetOffset < 0) targetOffset = 0;
        moveListScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    const Color themeBeige = Color(0xFFF0D9B5);
    const Color themeBrown = Color(0xFF5D4037);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter Chess App", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: themeBeige,
        foregroundColor: themeBrown,
        actions: [
          IconButton(
            onPressed: () => GameDialogs.showConfirmation(
              title: "Offer Draw?", 
              content: "Declare the game as a draw?", 
              confirmText: "Declare Draw", 
              confirmColor: themeBrown, 
              onConfirm: controller.declareDraw
            ),
            icon: const Icon(Icons.handshake),
          ),
          IconButton(
            onPressed: () => GameDialogs.showConfirmation(
              title: "Resign?", 
              content: "Are you sure you want to give up?", 
              confirmText: "Yes, Resign", 
              confirmColor: Colors.redAccent, 
              onConfirm: controller.resignGame
            ),
            icon: const Icon(Icons.flag),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          MoveListBar(controller: controller, scrollController: moveListScrollController),

          Obx(() {
            if (controller.gameMode.value == 'dice' || controller.gameMode.value == 'boa') {
              return Column(
                children: [
                   const SizedBox(height: 5), 
                   DiceRow(
                    isActive: !controller.isMyTurn.value,
                    diceValues: controller.currentDice, 
                    isBottom: false,
                    isWhitePieces: controller.myColor.value == 'b',
                    controller: controller,
                  ),
                ],
              );
            }
            else if (controller.gameMode.value == 'vegas') {
               bool isOpponentActive = !controller.isMyTurn.value;
               return Container(
                 height: 60,
                 alignment: Alignment.center,
                 child: isOpponentActive 
                   ? Text("Opponent Moves: ${controller.movesLeft.value}", style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.bold))
                   : const SizedBox(height: 60),
               );
            }
            return const SizedBox(height: 60);
          }),

          Expanded(
            child: AnimatableChessBoard(controller: controller),
          ),

          Obx(() {
            if (controller.gameMode.value == 'dice' || controller.gameMode.value == 'boa') {
              return Column(
                children: [
                  const SizedBox(height: 5),
                  DiceRow(
                    isActive: controller.isMyTurn.value,
                    diceValues: controller.currentDice,
                    isBottom: true,
                    isWhitePieces: controller.myColor.value == 'w',
                    controller: controller,
                  ),
                ],
              );
            }
            else if (controller.gameMode.value == 'vegas') {
               bool isMyRowActive = controller.isMyTurn.value;
               return Container(
                 height: 60,
                 alignment: Alignment.center,
                 child: isMyRowActive 
                   ? Text("Moves Left: ${controller.movesLeft.value}", style: TextStyle(fontSize: 24, color: Colors.green[800], fontWeight: FontWeight.bold))
                   : const SizedBox(height: 60),
               );
            }
            return const SizedBox(height: 60);
          }),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navBtn(Icons.first_page, controller.currentMoveIndex.value > 0 ? controller.jumpToStart : null),
                _navBtn(Icons.chevron_left, controller.currentMoveIndex.value > 0 ? controller.goToPrevious : null),
                _navBtn(Icons.chevron_right, controller.currentMoveIndex.value < controller.fenHistory.length - 1 ? controller.goToNext : null),
                _navBtn(Icons.last_page, controller.currentMoveIndex.value < controller.fenHistory.length - 1 ? controller.jumpToLatest : null),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback? onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 32),
      color: onPressed != null ? Colors.black : Colors.grey,
    );
  }
}
