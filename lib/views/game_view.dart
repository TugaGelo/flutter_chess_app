import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:squares/squares.dart' as squares;
import '../controllers/game_controller.dart';

class GameView extends StatelessWidget {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<GameController>()) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final GameController controller = GameController.instance;
    final ScrollController moveListScrollController = ScrollController();

    ever(controller.currentMoveIndex, (index) {
      if (moveListScrollController.hasClients && index > 0) {
        moveListScrollController.animateTo(
          index * 50.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          controller.gameMode.value == 'dice' ? "Dice Chess" : "Classical Chess",
          style: const TextStyle(fontWeight: FontWeight.bold)
        )),
        actions: [
          IconButton(icon: const Icon(Icons.handshake), onPressed: controller.declareDraw, tooltip: "Offer Draw"),
          IconButton(icon: const Icon(Icons.flag), onPressed: controller.resignGame, tooltip: "Resign"),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            color: Colors.grey[200],
            child: Obx(() => ListView.builder(
              controller: moveListScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: (controller.moveHistorySan.length / 2).ceil(),
              itemBuilder: (context, index) {
                int i = index * 2;
                String whiteMove = controller.moveHistorySan.length > i ? controller.moveHistorySan[i] : '';
                String blackMove = controller.moveHistorySan.length > i + 1 ? controller.moveHistorySan[i + 1] : '';
                
                int currentPairIndex = (controller.currentMoveIndex.value + 1) ~/ 2;
                bool isCurrent = (index + 1) == currentPairIndex;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  color: isCurrent ? Colors.brown.withOpacity(0.2) : Colors.transparent,
                  child: Center(
                    child: Text(
                      "${index + 1}. $whiteMove $blackMove", 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: isCurrent ? Colors.brown[800] : Colors.black
                      )
                    )
                  ),
                );
              },
            )),
          ),

          Obx(() => controller.gameMode.value == 'dice' && !controller.isMyTurn.value
              ? _DiceRow(dice: controller.currentDice, isWhite: controller.myColor.value == 'b')
              : const SizedBox(height: 10)),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: GetBuilder<GameController>(
                  builder: (ctrl) {
                    return squares.Board(
                      key: const ValueKey('game_board'),
                      state: ctrl.boardState,
                      theme: squares.BoardTheme.brown,
                      pieceSet: squares.PieceSet.merida(),
                      selection: ctrl.selectedSquare.value,
                      
                      markers: ctrl.validMoves.toList(),
                      
                      markerTheme: squares.MarkerTheme(
                        empty: squares.MarkerTheme.dot,
                        piece: squares.MarkerTheme.corners(), 
                      ),

                      animatePieces: true,
                      animationDuration: const Duration(milliseconds: 250),
                      
                      onTap: (x) => ctrl.handleTap(x),
                      acceptDrag: (start, end) => ctrl.onUserMove(squares.Move(from: start.from, to: end)),
                      validateDrag: (_, __) => true, 
                    );
                  },
                ),
              ),
            ),
          ),
          
          // My Dice
          Obx(() => controller.gameMode.value == 'dice' && controller.isMyTurn.value
              ? _DiceRow(dice: controller.currentDice, isWhite: controller.myColor.value == 'w')
              : const SizedBox(height: 10)),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => controller.jumpToMove(0), 
                  icon: const Icon(Icons.first_page),
                  tooltip: "Start",
                ),
                IconButton(
                  onPressed: controller.prevMove, 
                  icon: const Icon(Icons.chevron_left),
                  tooltip: "Previous",
                ),
                IconButton(
                  onPressed: controller.nextMove, 
                  icon: const Icon(Icons.chevron_right),
                  tooltip: "Next",
                ),
                IconButton(
                  onPressed: controller.jumpToLive, 
                  icon: const Icon(Icons.last_page),
                  tooltip: "Live",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiceRow extends StatelessWidget {
  final List<int> dice;
  final bool isWhite;
  const _DiceRow({required this.dice, required this.isWhite});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: dice.map((val) => Container(
          margin: const EdgeInsets.all(4),
          width: 40, height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.brown),
            color: const Color(0xFFF0D9B5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text("$val", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
        )).toList(),
      ),
    );
  }
}
