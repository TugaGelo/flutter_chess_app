import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_chess_board/simple_chess_board.dart';
import '../controllers/game_controller.dart';
import '../widgets/board_overlay.dart';
import '../utils/board_geometry.dart';
import '../utils/chess_utils.dart';
import '../widgets/game/dice_row.dart';
import '../widgets/game/move_list_bar.dart';
import '../utils/game_dialogs.dart';

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
            child: Padding(
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
                           List<int> endCoords = BoardGeometry.getSquareIndices(
                             controller.animEndSquare.value, 
                             blackAtBottom
                           );
                           ghostTop = endCoords[0] * squareSize;
                           ghostLeft = endCoords[1] * squareSize;

                           List<int> startCoords = BoardGeometry.getSquareIndices(
                             controller.animStartSquare.value, 
                             blackAtBottom
                           );
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
                                  top: maskTop,
                                  left: maskLeft,
                                  width: squareSize,
                                  height: squareSize,
                                  child: Container(color: maskColor),
                                ),
                              BoardOverlay(isBlackAtBottom: blackAtBottom),
                              if (controller.isAnimating.value)
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  top: ghostTop,
                                  left: ghostLeft,
                                  width: squareSize,
                                  height: squareSize,
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
            ),
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
