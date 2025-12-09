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
    
    // Pick a random term
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
          // 1. THE BOARD
          Expanded(
            flex: 5, 
            child: Container(
              color: Colors.grey[200], 
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

          // 2. THE LESSON TEXT
          Expanded(
            flex: 2, 
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

          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Obx(() {
                    bool isLoadingThis = matchmakingController.searchingMode.value == 'classical';
                    bool isAnyLoading = matchmakingController.searchingMode.value.isNotEmpty;

                    return ElevatedButton.icon(
                      onPressed: isAnyLoading 
                          ? null 
                          : () => matchmakingController.startMatchmaking('classical'),
                      
                      icon: isLoadingThis 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.play_arrow),
                      
                      label: Text(
                        isLoadingThis ? "Searching..." : "Classical",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: textBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: Obx(() {
                    bool isLoadingThis = matchmakingController.searchingMode.value == 'dice';
                    bool isAnyLoading = matchmakingController.searchingMode.value.isNotEmpty;

                    return ElevatedButton.icon(
                      onPressed: isAnyLoading 
                          ? null 
                          : () => matchmakingController.startMatchmaking('dice'),
                      
                      icon: isLoadingThis 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.casino),
                      
                      label: Text(
                        isLoadingThis ? "Searching..." : "Dice",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB58863),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  }),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
