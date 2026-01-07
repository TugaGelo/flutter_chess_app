import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/game_controller.dart';

class MoveListBar extends StatelessWidget {
  final GameController controller;
  final ScrollController scrollController;

  const MoveListBar({
    super.key, 
    required this.controller, 
    required this.scrollController
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(color: Colors.grey[200]),
      child: Obx(() {
        int pairCount = (controller.moveHistorySan.length / 2).ceil();
        
        return ListView.builder(
          controller: scrollController,
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
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 16),
                  ),
                ),
                _buildMoveButton(
                  text: controller.moveHistorySan[whiteMoveIndex],
                  moveIndex: whiteMoveIndex,
                ),
                if (hasBlackMove) ...[
                  const SizedBox(width: 4),
                  _buildMoveButton(
                    text: controller.moveHistorySan[blackMoveIndex],
                    moveIndex: blackMoveIndex,
                  ),
                ],
                const SizedBox(width: 12),
              ],
            );
          },
        );
      }),
    );
  }

  Widget _buildMoveButton({required String text, required int moveIndex}) {
    return Obx(() {
      bool isSelected = moveIndex == (controller.currentMoveIndex.value - 1);
      bool isPass = text == "Pass";

      return InkWell(
        onTap: () => controller.jumpToMove(moveIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFb58863) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: isPass 
            ? Row(
                children: [
                  Icon(Icons.block, size: 14, color: isSelected ? Colors.white : Colors.red[700]),
                  const SizedBox(width: 4),
                  Text("Pass", style: TextStyle(color: isSelected ? Colors.white : Colors.red[700], fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              )
            : Text(
                text,
                style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14),
              ),
        ),
      );
    });
  }
}
