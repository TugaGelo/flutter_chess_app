import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_chess_board/simple_chess_board.dart';
import '../../controllers/game_controller.dart';
import '../board_overlay.dart';
import '../../utils/board_geometry.dart';
import '../../utils/chess_utils.dart';
import '../../utils/game_dialogs.dart';

class AnimatableChessBoard extends StatelessWidget {
  final GameController controller;

  const AnimatableChessBoard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double containerWidth = constraints.maxWidth;
          if (constraints.maxHeight < containerWidth) containerWidth = constraints.maxHeight;
          double actualBoardSize = containerWidth - 16.0;
          double squareSize = actualBoardSize / 8;

          return Center(
            child: SizedBox(
              width: containerWidth,
              height: containerWidth,
              child: Obx(() {
                final currentFen = controller.displayFen.value.isEmpty 
                    ? 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1' 
                    : controller.displayFen.value;
                bool blackAtBottom = controller.myColor.value == 'b';

                double ghostTop = 0;
                double ghostLeft = 0;
                double maskTop = 0;
                double maskLeft = 0;
                Color maskColor = Colors.transparent;

                if (controller.isAnimating.value) {
                   List<int> endCoords = BoardGeometry.getSquareIndices(controller.animEndSquare.value, blackAtBottom);
                   ghostTop = endCoords[0] * squareSize;
                   ghostLeft = endCoords[1] * squareSize;

                   List<int> startCoords = BoardGeometry.getSquareIndices(controller.animStartSquare.value, blackAtBottom);
                   maskTop = startCoords[0] * squareSize;
                   maskLeft = startCoords[1] * squareSize;
                   bool isLightSquare = (startCoords[0] + startCoords[1]) % 2 == 0;
                   maskColor = isLightSquare ? const Color(0xFFF0D9B5) : const Color(0xFFB58863);
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8.0),
                  color: controller.isWhiteTurn.value ? Colors.grey[300] : Colors.black,
                  child: Stack(
                    children: [
                      SimpleChessBoard(
                        fen: currentFen,
                        blackSideAtBottom: blackAtBottom,
                        whitePlayerType: PlayerType.human,
                        blackPlayerType: PlayerType.human,
                        showCoordinatesZone: false,
                        showPossibleMoves: false,
                        chessBoardColors: ChessBoardColors()..lightSquaresColor = const Color(0xFFF0D9B5)..darkSquaresColor = const Color(0xFFB58863),
                        cellHighlights: Map.from(controller.validMoveHighlights),
                        
                        onPromote: () async {
                          String? char = await GameDialogs.showPromotion(controller.myColor.value == 'w');
                          if (char == null) return null;
                          switch (char) {
                            case 'q': return PieceType.queen;
                            case 'r': return PieceType.rook;
                            case 'b': return PieceType.bishop;
                            case 'n': return PieceType.knight;
                            default: return PieceType.queen;
                          }
                        },
                        onPromotionCommited: ({required ShortMove moveDone, required PieceType pieceType}) {
                          String char = 'q';
                          if (pieceType == PieceType.rook) char = 'r';
                          if (pieceType == PieceType.bishop) char = 'b';
                          if (pieceType == PieceType.knight) char = 'n';
                          controller.makeMove(from: moveDone.from, to: moveDone.to, promotion: char);
                        },
                        onMove: ({required ShortMove move}) {
                          controller.makeMove(from: move.from, to: move.to);
                        },
                        onTap: ({required String cellCoordinate}) {
                          controller.onSquareTap(cellCoordinate);
                        },
                      ),

                      if (controller.isAnimating.value)
                        Positioned(
                          top: maskTop, left: maskLeft, width: squareSize, height: squareSize,
                          child: Container(color: maskColor),
                        ),

                      BoardOverlay(isBlackAtBottom: blackAtBottom),

                      if (controller.isAnimating.value)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          top: ghostTop, left: ghostLeft, width: squareSize, height: squareSize,
                          child: ChessUtils.getPieceWidget(controller.animPieceChar.value),
                        ),
                    ],
                  ),
                );
              }),
            ),
          );
        }
      ),
    );
  }
}
