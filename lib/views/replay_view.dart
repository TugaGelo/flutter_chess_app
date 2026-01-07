import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:squares/squares.dart';
import '../controllers/replay_controller.dart';

class ReplayView extends StatelessWidget {
  final String gameId;
  const ReplayView({super.key, this.gameId = ''}); 

  @override
  Widget build(BuildContext context) {
    final ReplayController controller = Get.isRegistered<ReplayController>() 
        ? Get.find() 
        : Get.put(ReplayController());

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
              int pairCount = (controller.moves.length / 2).ceil();
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: pairCount,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemBuilder: (context, index) {
                  int wIndex = index * 2;
                  int bIndex = (index * 2) + 1;
                  String wMove = controller.moves[wIndex];
                  String bMove = bIndex < controller.moves.length ? controller.moves[bIndex] : '';
                  
                  return Row(
                    children: [
                      Text("${index+1}. ", style: const TextStyle(fontWeight: FontWeight.bold)),
                      _buildMoveButton(wMove, wIndex, controller),
                      if (bMove.isNotEmpty) ...[
                        const SizedBox(width: 5),
                        _buildMoveButton(bMove, bIndex, controller),
                      ],
                      const SizedBox(width: 15),
                    ],
                  );
                },
              );
            }),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: GetBuilder<ReplayController>(
                  builder: (ctrl) {
                    return Board(
                      state: ctrl.boardController.state,
                      playState: PlayState.finished, 
                      
                      theme: BoardTheme.brown,
                      pieceSet: PieceSet.merida(),
                    );
                  },
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(onPressed: controller.index.value > -1 ? controller.jumpToStart : null, icon: const Icon(Icons.first_page)),
                IconButton(onPressed: controller.index.value > -1 ? controller.prev : null, icon: const Icon(Icons.chevron_left)),
                IconButton(onPressed: controller.index.value < controller.moves.length - 1 ? controller.next : null, icon: const Icon(Icons.chevron_right)),
                IconButton(onPressed: controller.index.value < controller.moves.length - 1 ? controller.jumpToLatest : null, icon: const Icon(Icons.last_page)),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildMoveButton(String text, int index, ReplayController ctrl) {
    return Obx(() {
      bool isSelected = index == ctrl.index.value;
      return InkWell(
        onTap: () => ctrl.jumpToMove(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.brown : Colors.transparent,
            borderRadius: BorderRadius.circular(4)
          ),
          child: Text(text, style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
          )),
        ),
      );
    });
  }
}
