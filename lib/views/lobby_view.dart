import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_chess_board/simple_chess_board.dart';
import 'dart:math'; 
import '../controllers/auth_controller.dart';
import '../controllers/matchmaking_controller.dart';
import '../controllers/sound_controller.dart';
import '../models/chess_term.dart';
import '../data/chess_terms_data.dart';
import '../widgets/board_overlay.dart';
import '../widgets/mode_selector_button.dart'; 
import 'history_view.dart';

class LobbyView extends StatelessWidget {
  const LobbyView({super.key});

  @override
  Widget build(BuildContext context) {
    final MatchmakingController matchmakingController = Get.put(MatchmakingController());
    Get.put(SoundController()); 
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
            SoundController.instance.playClick();
            Get.to(() => const HistoryView());
          },
          icon: const Icon(Icons.history),
          tooltip: "Match History",
        ),
        actions: [
          IconButton(
            onPressed: () {
              SoundController.instance.playClick();
              AuthController.instance.signOut();
            },
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
                          onMove: ({required ShortMove move}) {}, 
                          onPromote: () async => PieceType.queen,
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
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textBrown),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dailyTerm.description,
                    textAlign: TextAlign.center,
                    maxLines: 3, 
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
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
                  ModeSelectorButton(
                    label: "Classical", 
                    icon: Icons.play_arrow, 
                    color: textBrown, 
                    mode: 'classical',
                    controller: matchmakingController
                  ),
                  const SizedBox(height: 10),
                  
                  ModeSelectorButton(
                    label: "Dice", 
                    icon: Icons.casino, 
                    color: const Color(0xFFB58863), 
                    mode: 'dice',
                    controller: matchmakingController
                  ),
                  const SizedBox(height: 10),

                  ModeSelectorButton(
                    label: "Vegas", 
                    icon: Icons.local_fire_department, 
                    color: const Color(0xFFD32F2F),
                    mode: 'vegas',
                    controller: matchmakingController
                  ),
                  const SizedBox(height: 10),

                  ModeSelectorButton(
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
}
