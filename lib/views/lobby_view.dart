import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:squares/squares.dart';
import 'package:bishop/bishop.dart' as bishop;
import 'dart:math';
import '../controllers/auth_controller.dart';
import '../controllers/matchmaking_controller.dart';
import '../data/chess_terms_data.dart';
import '../models/chess_term.dart';
import 'history_view.dart';

class LobbyView extends StatefulWidget {
  const LobbyView({super.key});

  @override
  State<LobbyView> createState() => _LobbyViewState();
}

class _LobbyViewState extends State<LobbyView> {
  late ChessTerm randomTerm;
  late BoardController miniBoardController;

  @override
  void initState() {
    super.initState();
    randomTerm = chessTerms[Random().nextInt(chessTerms.length)];

    bishop.Game tempGame = bishop.Game(variant: bishop.Variant.standard());
    tempGame.loadFen(randomTerm.fen);

    miniBoardController = BoardController(
      state: _createBoardState(tempGame),
      playState: PlayState.finished,
      pieceSet: PieceSet.merida(),
      theme: BoardTheme.brown,
    );
  }

  BoardState _createBoardState(bishop.Game game) {
    String fenBoard = game.fen.split(' ')[0];
    List<String> boardList = [];
    for (String row in fenBoard.split('/')) {
      for (int i = 0; i < row.length; i++) {
        String char = row[i];
        int? empty = int.tryParse(char);
        if (empty != null) {
          boardList.addAll(List.filled(empty, ''));
        } else {
          boardList.add(char);
        }
      }
    }
    return BoardState(board: boardList);
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = AuthController.instance;
    final MatchmakingController matchController = Get.put(MatchmakingController());

    const Color themeBeige = Color(0xFFF0D9B5);
    const Color themeBrown = Color(0xFF5D4037);

    return Scaffold(
      backgroundColor: themeBeige,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.history),
          tooltip: "Match History",
          onPressed: () => Get.to(() => const HistoryView()),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: themeBrown,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authController.signOut(),
            tooltip: "Sign Out",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: themeBrown.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(randomTerm.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: themeBrown)),
                  const SizedBox(height: 8),
                  Text(randomTerm.description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                  const SizedBox(height: 15),

                  AspectRatio(
                    aspectRatio: 1.0,
                    child: IgnorePointer(
                      child: Board(
                        state: miniBoardController.state,
                        theme: BoardTheme.brown,
                        pieceSet: PieceSet.merida(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            Obx(() {
              if (matchController.isSearching.value) {
                return Column(
                  children: const [
                    CircularProgressIndicator(color: themeBrown),
                    SizedBox(height: 20),
                    Text("Searching for opponent...", style: TextStyle(color: themeBrown, fontSize: 16)),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ModeButton(
                      icon: Icons.person,
                      label: "Classical",
                      color: themeBrown,
                      onPressed: () => matchController.joinQueue('classical')
                    ),
                    const SizedBox(height: 15),
                    _ModeButton(
                      icon: Icons.casino,
                      label: "Dice",
                      color: Colors.orange[800]!,
                      onPressed: () => matchController.joinQueue('dice')
                    ),
                    const SizedBox(height: 15),
                    _ModeButton(
                      icon: Icons.monetization_on,
                      label: "Vegas (Soon)",
                      color: Colors.green[800]!,
                      onPressed: null
                    ),
                  ],
                );
              }
            }),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ModeButton({required this.icon, required this.label, required this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: const TextStyle(fontSize: 18),
      ),
    );
  }
}
