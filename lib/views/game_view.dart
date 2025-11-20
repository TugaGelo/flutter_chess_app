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
        title: const Text("Chess Match"),
        leading: const SizedBox(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() => Column(
              children: [
                Text(
                  controller.isMyTurn.value ? "🟢 YOUR TURN" : "🔴 WAITING",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: controller.isMyTurn.value ? Colors.green : Colors.grey,
                  ),
                ),
                if (controller.gameOverMessage.value.isNotEmpty)
                  Text(controller.gameOverMessage.value,
                      style: const TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
              ],
            )),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Obx(() {
                final currentFen = controller.fen.value.isEmpty
                    ? 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
                    : controller.fen.value;

                return SimpleChessBoard(
                  fen: currentFen,
                  
                  blackSideAtBottom: controller.myColor.value == 'b',
                  
                  whitePlayerType: PlayerType.human,
                  blackPlayerType: PlayerType.human,
                  
                  chessBoardColors: ChessBoardColors(),
                  cellHighlights: const {},

                  onMove: ({required ShortMove move}) {
                    String? promoChar;
                    if (move.promotion == PieceType.queen) promoChar = 'q';
                    if (move.promotion == PieceType.rook) promoChar = 'r';
                    if (move.promotion == PieceType.bishop) promoChar = 'b';
                    if (move.promotion == PieceType.knight) promoChar = 'n';

                    controller.makeMove(
                        from: move.from, to: move.to, promotion: promoChar);
                  },

                  onPromote: () async {
                    return PieceType.queen;
                  },

                  onPromotionCommited: ({required ShortMove moveDone, required PieceType pieceType}) {
                    String promoChar = 'q';
                    if (pieceType == PieceType.rook) promoChar = 'r';
                    if (pieceType == PieceType.bishop) promoChar = 'b';
                    if (pieceType == PieceType.knight) promoChar = 'n';

                    controller.makeMove(
                        from: moveDone.from, 
                        to: moveDone.to, 
                        promotion: promoChar
                    );
                  },

                  onTap: ({required String cellCoordinate}) {
                    print("Tapped: $cellCoordinate");
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
