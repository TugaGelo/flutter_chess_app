import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_chess_board/simple_chess_board.dart';
import '../controllers/game_controller.dart';

class GameView extends StatelessWidget {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameController.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter Chess App"),
        centerTitle: true,
        leading: const SizedBox(),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Icon(Icons.person, size: 40, color: Colors.grey),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Obx(() {
                final currentFen = controller.displayFen.value.isEmpty
                    ? 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
                    : controller.displayFen.value;

                return SimpleChessBoard(
                  fen: currentFen,
                  blackSideAtBottom: controller.myColor.value == 'b',
                  whitePlayerType: PlayerType.human,
                  blackPlayerType: PlayerType.human,
                  chessBoardColors: ChessBoardColors(),
                  cellHighlights: const {},
                  
                  onPromote: () async => PieceType.queen,
                  
                  onMove: ({required ShortMove move}) {
                    String? promoChar;
                    if (move.promotion == PieceType.queen) promoChar = 'q';
                    if (move.promotion == PieceType.rook) promoChar = 'r';
                    if (move.promotion == PieceType.bishop) promoChar = 'b';
                    if (move.promotion == PieceType.knight) promoChar = 'n';

                    controller.makeMove(
                        from: move.from, to: move.to, promotion: promoChar);
                  },
                  onPromotionCommited: ({required ShortMove moveDone, required PieceType pieceType}) {},
                  onTap: ({required String cellCoordinate}) {},
                );
              }),
            ),
          ),

          SizedBox(
            height: 50,
            child: Obx(() => ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.moveHistorySan.length,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemBuilder: (context, index) {
                bool isSelected = index == controller.currentMoveIndex.value - 1;

                return Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.brown : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${index + 1}. ${controller.moveHistorySan[index]}",
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            )),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: controller.currentMoveIndex.value > 0 
                      ? controller.jumpToStart 
                      : null, 
                  icon: const Icon(Icons.first_page, size: 32),
                ),
                IconButton(
                  onPressed: controller.currentMoveIndex.value > 0 
                      ? controller.goToPrevious 
                      : null,
                  icon: const Icon(Icons.chevron_left, size: 32),
                ),
                IconButton(
                  onPressed: controller.currentMoveIndex.value < controller.fenHistory.length - 1 
                      ? controller.goToNext 
                      : null,
                  icon: const Icon(Icons.chevron_right, size: 32),
                ),
                IconButton(
                  onPressed: controller.currentMoveIndex.value < controller.fenHistory.length - 1 
                      ? controller.jumpToLatest 
                      : null,
                  icon: const Icon(Icons.last_page, size: 32),
                ),
              ],
            )),
          ),
          
          Obx(() => controller.gameOverMessage.value.isNotEmpty 
            ? Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(controller.gameOverMessage.value, style: const TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
              )
            : const SizedBox()
          ),
        ],
      ),
    );
  }
}
