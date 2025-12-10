import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:squares/squares.dart';
import '../controllers/game_controller.dart';

class GameView extends StatelessWidget {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<GameController>()) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final GameController controller = GameController.instance;

    return Scaffold(
      appBar: AppBar(title: const Text("Dice Chess")),
      body: Column(
        children: [
          SizedBox(height: 50, child: Obx(() => Text(controller.moveHistorySan.join(" ")))),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: GetBuilder<GameController>(
                  builder: (ctrl) {
                    return Board(
                      state: ctrl.boardController.state,
                      theme: BoardTheme.brown,
                      pieceSet: PieceSet.merida(),
                      selection: ctrl.selectedSquare.value,
                      
                      onTap: (x) => ctrl.handleTap(x),
                      acceptDrag: (start, end) => ctrl.onDrop(Move(from: start.from, to: end)),
                      validateDrag: (_, __) => true,
                    );
                  },
                ),
              ),
            ),
          ),
          
          Obx(() => Text("Dice: ${controller.currentDice}", style: const TextStyle(fontSize: 24))),
        ],
      ),
    );
  }
}
