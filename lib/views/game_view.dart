import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_chess_board/simple_chess_board.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';
import '../controllers/game_controller.dart';
import '../widgets/board_overlay.dart';
import '../utils/board_geometry.dart';

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
            onPressed: () {
              Get.defaultDialog(
                title: "Offer Draw?",
                titleStyle: const TextStyle(color: themeBrown, fontWeight: FontWeight.bold),
                middleText: "Declare the game as a draw?",
                textConfirm: "Declare Draw",
                textCancel: "Cancel",
                buttonColor: themeBrown,
                confirmTextColor: Colors.white,
                cancelTextColor: themeBrown,
                onConfirm: () {
                  Get.back();
                  controller.declareDraw();
                }
              );
            },
            icon: const Icon(Icons.handshake),
            tooltip: "Draw",
          ),
          IconButton(
            onPressed: () {
              Get.defaultDialog(
                title: "Resign?",
                titleStyle: const TextStyle(color: themeBrown, fontWeight: FontWeight.bold),
                middleText: "Are you sure you want to give up?",
                textConfirm: "Yes, Resign",
                textCancel: "Cancel",
                buttonColor: Colors.redAccent,
                confirmTextColor: Colors.white,
                cancelTextColor: themeBrown,
                onConfirm: () {
                  Get.back();
                  controller.resignGame();
                }
              );
            },
            icon: const Icon(Icons.flag),
            tooltip: "Resign",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(color: Colors.grey[200]),
            child: Obx(() {
              int pairCount = (controller.moveHistorySan.length / 2).ceil();
              return ListView.builder(
                controller: moveListScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: pairCount,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemBuilder: (context, index) {
                  int whiteMoveIndex = index * 2;
                  int blackMoveIndex = (index * 2) + 1;
                  bool hasBlackMove = blackMoveIndex < controller.moveHistorySan.length;

                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 8, right: 4),
                        child: Text(
                          "${index + 1}.",
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: Colors.grey[700],
                            fontSize: 16
                          ),
                        ),
                      ),

                      _buildMoveButton(
                        text: controller.moveHistorySan[whiteMoveIndex],
                        moveIndex: whiteMoveIndex,
                        controller: controller
                      ),

                      if (hasBlackMove) ...[
                        const SizedBox(width: 4),
                        _buildMoveButton(
                          text: controller.moveHistorySan[blackMoveIndex],
                          moveIndex: blackMoveIndex,
                          controller: controller
                        ),
                      ],
                      
                      const SizedBox(width: 12),
                    ],
                  );
                },
              );
            }),
          ),

          Obx(() {
            if (controller.gameMode.value == 'dice') {
              bool isOpponentActive = !controller.isMyTurn.value;
              bool isOpponentWhite = controller.myColor.value == 'b'; 

              return _buildDiceRow(
                isActive: isOpponentActive,
                diceValues: isOpponentActive ? controller.currentDice : [], 
                isBottom: false,
                isWhitePieces: isOpponentWhite,
                controller: controller,
              );
            }
            else if (controller.gameMode.value == 'vegas') {
               bool isOpponentActive = !controller.isMyTurn.value;
               return Container(
                 height: 60,
                 alignment: Alignment.center,
                 child: isOpponentActive 
                   ? Text("Opponent Moves: ${controller.movesLeft.value}", style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.bold))
                   : const SizedBox(),
               );
            }
            return const SizedBox(height: 10);
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
                                  String? char = await controller.pickPromotionCharacter();
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
                                  child: _getPieceWidget(controller.animPieceChar.value),
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
            if (controller.gameMode.value == 'dice') {
              bool isMyRowActive = controller.isMyTurn.value;
              bool amIWhite = controller.myColor.value == 'w'; 

              return _buildDiceRow(
                isActive: isMyRowActive,
                diceValues: isMyRowActive ? controller.currentDice : [],
                isBottom: true,
                isWhitePieces: amIWhite,
                controller: controller,
              );
            }
            else if (controller.gameMode.value == 'vegas') {
               bool isMyRowActive = controller.isMyTurn.value;
               return Container(
                 height: 60,
                 alignment: Alignment.center,
                 child: isMyRowActive 
                   ? Text("Moves Left: ${controller.movesLeft.value}", style: TextStyle(fontSize: 24, color: Colors.green[800], fontWeight: FontWeight.bold))
                   : const SizedBox(),
               );
            }
            return const SizedBox();
          }),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: controller.currentMoveIndex.value > 0 
                      ? controller.jumpToStart : null, 
                  icon: const Icon(Icons.first_page, size: 32),
                ),
                IconButton(
                  onPressed: controller.currentMoveIndex.value > 0 
                      ? controller.goToPrevious : null,
                  icon: const Icon(Icons.chevron_left, size: 32),
                ),
                IconButton(
                  onPressed: controller.currentMoveIndex.value < controller.fenHistory.length - 1 
                      ? controller.goToNext : null,
                  icon: const Icon(Icons.chevron_right, size: 32),
                ),
                IconButton(
                  onPressed: controller.currentMoveIndex.value < controller.fenHistory.length - 1 
                      ? controller.jumpToLatest : null,
                  icon: const Icon(Icons.last_page, size: 32),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildDiceRow({
    required bool isActive,
    required List<int> diceValues,
    required bool isBottom,
    required bool isWhitePieces,
    required GameController controller,
  }) {
    const Color activeBorder = Color(0xFFB58863); 
    const Color activeBg = Color(0xFFF0D9B5);     
    const Color inactiveColor = Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < 3; i++)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isActive && diceValues.isNotEmpty ? activeBg : Colors.grey[200],
                border: Border.all(
                  color: isActive && diceValues.isNotEmpty ? activeBorder : inactiveColor,
                  width: 2
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: (isActive && i < diceValues.length)
                    ? SizedBox(
                        width: 28,
                        height: 28,
                        child: _getPieceWidgetForDice(diceValues[i], isWhitePieces),
                      )
                    : null, 
              ),
            ),

          if (isBottom && isActive && !controller.canMakeAnyMove.value)
             Padding(
               padding: const EdgeInsets.only(left: 10),
               child: ElevatedButton(
                 onPressed: () => controller.passTurn(),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: activeBorder, 
                   foregroundColor: Colors.white
                 ),
                 child: const Text("PASS", style: TextStyle(fontWeight: FontWeight.bold)),
               ),
             )
        ],
      ),
    );
  }

  Widget _getPieceWidgetForDice(int val, bool isWhite) {
    if (isWhite) {
      switch(val) {
        case 1: return WhitePawn();
        case 2: return WhiteKnight();
        case 3: return WhiteBishop();
        case 4: return WhiteRook();
        case 5: return WhiteQueen();
        case 6: return WhiteKing();
        default: return const SizedBox();
      }
    } else {
      switch(val) {
        case 1: return BlackPawn();
        case 2: return BlackKnight();
        case 3: return BlackBishop();
        case 4: return BlackRook();
        case 5: return BlackQueen();
        case 6: return BlackKing();
        default: return const SizedBox();
      }
    }
  }
  
  Widget _getPieceWidget(String char) {
    switch (char) {
      case 'P': return WhitePawn();
      case 'N': return WhiteKnight();
      case 'B': return WhiteBishop();
      case 'R': return WhiteRook();
      case 'Q': return WhiteQueen();
      case 'K': return WhiteKing();
      case 'p': return BlackPawn();
      case 'n': return BlackKnight();
      case 'b': return BlackBishop();
      case 'r': return BlackRook();
      case 'q': return BlackQueen();
      case 'k': return BlackKing();
      default: return const SizedBox();
    }
  }

  Widget _buildMoveButton({
    required String text, 
    required int moveIndex, 
    required GameController controller
  }) {
    return Obx(() {
      bool isSelected = moveIndex == (controller.currentMoveIndex.value - 1);
      
      if (text == "Pass") {
        return Container(
           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
           decoration: BoxDecoration(
             color: isSelected ? const Color(0xFFb58863) : Colors.transparent, 
             borderRadius: BorderRadius.circular(4)
           ),
           child: Row(
             children: [
               Icon(Icons.block, size: 14, color: isSelected ? Colors.white : Colors.red[700]),
               const SizedBox(width: 4),
               Text(
                 "Pass", 
                 style: TextStyle(
                   color: isSelected ? Colors.white : Colors.red[700], 
                   fontWeight: FontWeight.bold,
                   fontSize: 14
                 )
               ),
             ],
           ),
         );
      }

      return InkWell(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFFb58863)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      );
    });
  }
}