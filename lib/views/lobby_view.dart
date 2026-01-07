import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_chess_board/simple_chess_board.dart';
import 'dart:math'; 
import '../controllers/auth_controller.dart';
import '../controllers/matchmaking_controller.dart';
import '../models/chess_term.dart';
import '../data/chess_terms_data.dart';
import '../widgets/board_overlay.dart';
import 'history_view.dart';

class LobbyView extends StatelessWidget {
  const LobbyView({super.key});

  @override
  Widget build(BuildContext context) {
    final MatchmakingController matchmakingController = Get.put(MatchmakingController());
    final ChessTerm dailyTerm = chessTerms[Random().nextInt(chessTerms.length)];

    const Color bgBeige = Color(0xFFF0D9B5); 
    const Color textBrown = Color(0xFF5D4037);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Hipe Office Chess', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: bgBeige,
        foregroundColor: textBrown,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Get.to(() => const HistoryView());
          },
          icon: const Icon(Icons.history),
          tooltip: "Match History",
        ),
        actions: [
          IconButton(
            onPressed: () => AuthController.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3, 
            child: Container(
              color: Colors.white, 
              padding: const EdgeInsets.all(20),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0, 
                  child: Stack(
                    children: [
                      IgnorePointer( 
                        child: SimpleChessBoard(
                          fen: dailyTerm.fen,
                          blackSideAtBottom: false,
                          whitePlayerType: PlayerType.computer,
                          blackPlayerType: PlayerType.computer,
                          showCoordinatesZone: false,
                          chessBoardColors: ChessBoardColors()
                            ..lightSquaresColor = const Color(0xFFF0D9B5)
                            ..darkSquaresColor = const Color(0xFFB58863),
                          onPromote: () async => PieceType.queen,
                          onMove: ({required ShortMove move}) {},
                          onPromotionCommited: ({required ShortMove moveDone, required PieceType pieceType}) {},
                          onTap: ({required String cellCoordinate}) {},
                          cellHighlights: const {},
                        ),
                      ),
                      const BoardOverlay(isBlackAtBottom: false),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            flex: 1, 
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              width: double.infinity,
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dailyTerm.title,
                    style: const TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: textBrown
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dailyTerm.description,
                    textAlign: TextAlign.center,
                    maxLines: 3, 
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16, 
                      color: Colors.black87,
                      height: 1.4 
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 20),
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildModeButton(
                    label: "Classical", 
                    icon: Icons.play_arrow, 
                    color: textBrown, 
                    mode: 'classical',
                    controller: matchmakingController
                  ),
                  const SizedBox(height: 10),
                  
                  _buildModeButton(
                    label: "Dice", 
                    icon: Icons.casino, 
                    color: const Color(0xFFB58863), 
                    mode: 'dice',
                    controller: matchmakingController
                  ),
                  const SizedBox(height: 10),

                  _buildModeButton(
                    label: "Vegas", 
                    icon: Icons.local_fire_department, 
                    color: const Color(0xFFD32F2F),
                    mode: 'vegas',
                    controller: matchmakingController
                  ),
                  const SizedBox(height: 10),

                  _buildModeButton(
                    label: "Boa", 
                    icon: Icons.all_inclusive, 
                    color: const Color(0xFF7B1FA2),
                    mode: 'boa',
                    controller: matchmakingController
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label, 
    required IconData icon, 
    required Color color, 
    required String mode,
    required MatchmakingController controller
  }) {
    return SizedBox(
      width: double.infinity, 
      height: 50, 
      child: Stack(
        children: [
          Positioned.fill(
            child: Obx(() {
              bool isLoadingThis = controller.searchingMode.value == mode;
              bool isAnyLoading = controller.searchingMode.value.isNotEmpty;

              return ElevatedButton(
                onPressed: isLoadingThis 
                    ? () => controller.cancelMatchmaking() 
                    : (isAnyLoading ? null : () => controller.startMatchmaking(mode)),
                
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLoadingThis ? Colors.redAccent : color,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.zero,
                ),
                child: isLoadingThis 
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 12),
                          Text("Cancel", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            label,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              );
            }),
          ),
          
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Obx(() => controller.searchingMode.value == mode 
              ? const SizedBox()
              : IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white70),
                  tooltip: "Rules",
                  onPressed: () => _showRulesDialog(mode, label),
                )
            ),
          )
        ],
      ),
    );
  }

  void _showRulesDialog(String mode, String title) {
    String content = "";
    switch (mode) {
      case 'classical':
        content = "Standard Chess Rules apply.\n\nTime to prove who is the true grandmaster of the office!";
        break;
      case 'dice':
        content = "Roll 3 Dice each turn!\n\nYou can ONLY move pieces that match the dice values:\n\n♙ Pawn: 1\n♘ Knight: 2\n♗ Bishop: 3\n♖ Rook: 4\n♕ Queen: 5\n♔ King: 6\n\nIf you have no legal moves, you must Pass.";
        break;
      case 'vegas':
        content = "High Stakes, variable moves!\n\nRoll 1 Die to determine your turn:\n\n🎲 1-2 = 1 Move\n🎲 3-4 = 2 Moves\n🎲 5-6 = 3 Moves\n\nPlan your combos carefully!";
        break;
      case 'boa':
        content = "The Ultimate Chaos!\n\n• You ALWAYS get 3 Dice & 3 Moves.\n• You must use the dice to move specific pieces.\n• You can pass if stuck, but try to use all 3!";
        break;
    }

    Get.defaultDialog(
      title: title,
      titleStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          content, 
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
      confirm: ElevatedButton(
        onPressed: () => Get.back(),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037), foregroundColor: Colors.white),
        child: const Text("Got it!"),
      ),
      radius: 10,
    );
  }
}
