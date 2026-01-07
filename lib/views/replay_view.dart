import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_chess_board/simple_chess_board.dart';
import '../controllers/replay_controller.dart';
import '../widgets/board_overlay.dart';

class ReplayView extends StatelessWidget {
  const ReplayView({super.key});

  @override
  Widget build(BuildContext context) {
    final ReplayController controller = Get.find();
    final ScrollController moveListScrollController = ScrollController();

    ever(controller.currentMoveIndex, (index) {
      if (moveListScrollController.hasClients && index > 0) {
        double rowIndex = (index / 2).floorToDouble();
        double targetOffset = (rowIndex - 1) * 100.0; 
        if (targetOffset < 0) targetOffset = 0;
        moveListScrollController.animateTo(
          targetOffset, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text("${controller.whiteName} vs ${controller.blackName}")),
        centerTitle: true,
        backgroundColor: const Color(0xFFF0D9B5),
        foregroundColor: const Color(0xFF5D4037),
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
                      Container(padding: const EdgeInsets.only(left: 8, right: 4), child: Text("${index + 1}.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 16))),
                      _buildMoveButton(text: controller.moveHistorySan[whiteMoveIndex], moveIndex: whiteMoveIndex, controller: controller),
                      if (hasBlackMove) ...[const SizedBox(width: 4), _buildMoveButton(text: controller.moveHistorySan[blackMoveIndex], moveIndex: blackMoveIndex, controller: controller)],
                      const SizedBox(width: 12),
                    ],
                  );
                },
              );
            }),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    color: Colors.brown[900],
                    child: Stack(
                      children: [
                        Obx(() => SimpleChessBoard(
                          fen: controller.displayFen.value,
                          blackSideAtBottom: false,
                          whitePlayerType: PlayerType.computer,
                          blackPlayerType: PlayerType.computer,
                          showCoordinatesZone: false, 
                          chessBoardColors: ChessBoardColors()..lightSquaresColor = const Color(0xFFF0D9B5)..darkSquaresColor = const Color(0xFFB58863),
                          cellHighlights: const {}, 
                          onPromote: () async => PieceType.queen,
                          onMove: ({required ShortMove move}) {},
                          onPromotionCommited: ({required ShortMove moveDone, required PieceType pieceType}) {},
                          onTap: ({required String cellCoordinate}) {},
                        )),
                        const BoardOverlay(isBlackAtBottom: false),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(onPressed: controller.currentMoveIndex.value > 0 ? controller.jumpToStart : null, icon: const Icon(Icons.first_page, size: 32)),
                IconButton(onPressed: controller.currentMoveIndex.value > 0 ? controller.goToPrevious : null, icon: const Icon(Icons.chevron_left, size: 32)),
                IconButton(onPressed: controller.currentMoveIndex.value < controller.fenHistory.length - 1 ? controller.goToNext : null, icon: const Icon(Icons.chevron_right, size: 32)),
                IconButton(onPressed: controller.currentMoveIndex.value < controller.fenHistory.length - 1 ? controller.jumpToLatest : null, icon: const Icon(Icons.last_page, size: 32)),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildMoveButton({required String text, required int moveIndex, required ReplayController controller}) {
    return Obx(() {
      bool isSelected = moveIndex == (controller.currentMoveIndex.value - 1);
      return InkWell(
        onTap: () => controller.jumpToMove(moveIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: isSelected ? const Color(0xFFb58863) : Colors.transparent, borderRadius: BorderRadius.circular(4)),
          child: Text(text, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 16)),
        ),
      );
    });
  }
}
