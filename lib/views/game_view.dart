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
        double itemWidth = 100.0; 
        double targetScroll = (index / 2) * itemWidth - 100;
        if (targetScroll < 0) targetScroll = 0;
        
        moveListScrollController.animateTo(
          targetScroll,
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
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.handshake), onPressed: controller.declareDraw, tooltip: "Offer Draw"),
          IconButton(icon: const Icon(Icons.flag), onPressed: controller.resignGame, tooltip: "Resign"),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            color: const Color(0xFFF5F5F5),
            child: Obx(() {
              int currentPly = controller.currentMoveIndex.value;
              
              return ListView.builder(
                controller: moveListScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: (controller.moveHistorySan.length / 2).ceil(),
                itemBuilder: (context, index) {
                  int i = index * 2;
                  
                  String whiteMove = controller.moveHistorySan.length > i ? controller.moveHistorySan[i] : '';
                  String blackMove = controller.moveHistorySan.length > i + 1 ? controller.moveHistorySan[i + 1] : '';
                  
                  bool isWhiteActive = (currentPly == i + 1);
                  bool isBlackActive = (currentPly == i + 2);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        Text("${index + 1}. ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600])),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isWhiteActive ? const Color(0xFFF0D9B5) : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: isWhiteActive ? Border.all(color: Colors.brown, width: 1.5) : null,
                          ),
                          child: Text(
                            whiteMove, 
                            style: TextStyle(
                              fontWeight: isWhiteActive ? FontWeight.bold : FontWeight.normal,
                              color: isWhiteActive ? Colors.brown[900] : Colors.black87
                            )
                          ),
                        ),
                        
                        const SizedBox(width: 4),
                        
                        if (blackMove.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isBlackActive ? const Color(0xFFF0D9B5) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: isBlackActive ? Border.all(color: Colors.brown, width: 1.5) : null,
                            ),
                            child: Text(
                              blackMove, 
                              style: TextStyle(
                                fontWeight: isBlackActive ? FontWeight.bold : FontWeight.normal,
                                color: isBlackActive ? Colors.brown[900] : Colors.black87
                              )
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            }),
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
                      key: ValueKey("board_${ctrl.fenHistory.length}"),
                      
                      state: ctrl.boardState,
                      theme: squares.BoardTheme.brown,
                      pieceSet: ctrl.pieceSet,
                      selection: ctrl.selectedSquare.value,
                      
                      markers: ctrl.validMoves.toList(),
                      markerTheme: squares.MarkerTheme(
                        empty: squares.MarkerTheme.dot,
                        piece: squares.MarkerTheme.corners(), 
                      ),

                      animatePieces: true,
                      animationDuration: const Duration(milliseconds: 300),
                      
                      onTap: (x) => ctrl.handleTap(x),
                      acceptDrag: (start, end) => ctrl.onUserMove(squares.Move(from: start.from, to: end)),
                      validateDrag: (_, __) => true, 
                    );
                  },
                ),
              ),
            ),
          ),
          
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