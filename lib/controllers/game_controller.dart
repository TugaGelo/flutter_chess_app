import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../controllers/auth_controller.dart';
import '../views/lobby_view.dart';

class GameController extends GetxController {
  static GameController instance = Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  RxString gameId = ''.obs;
  RxString myColor = ''.obs;
  RxBool isMyTurn = false.obs;
  RxBool isWhiteTurn = true.obs;
  RxBool isGameEnded = false.obs;
  RxString gameOverMessage = ''.obs;
  
  RxString fen = ''.obs; 
  String _lastProcessedFen = '';

  RxBool isAnimating = false.obs;
  RxString animStartSquare = ''.obs; 
  RxString animEndSquare = ''.obs;   
  RxString animPieceChar = ''.obs;   

  RxMap<String, Color> validMoveHighlights = <String, Color>{}.obs;
  String? _selectedSquare;

  RxString displayFen = ''.obs; 
  RxList<String> fenHistory = <String>[].obs; 
  RxList<String> moveHistorySan = <String>[].obs;
  RxInt currentMoveIndex = (-1).obs;

  final chess_lib.Chess _chess = chess_lib.Chess();

  void setGame(String id, String assignedColor) {
    gameId.value = id;
    myColor.value = assignedColor; 
    isGameEnded.value = false;
    _connectToGameStream();
  }

  void _connectToGameStream() {
    _db.collection('games').doc(gameId.value).snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;

      var data = snapshot.data() as Map<String, dynamic>;
      
      String myUid = AuthController.instance.user!.uid;
      if (data['white'] == myUid) {
        myColor.value = 'w';
      } else if (data['black'] == myUid) {
        myColor.value = 'b';
      }

      String serverFen = data['fen'];
      String serverPgn = data['pgn'] ?? ''; 
      Map<String, dynamic>? lastMoveData = data['lastMove'];
      String? winner = data['winner']; 

      if (serverFen == chess_lib.Chess.DEFAULT_POSITION) {
        if (isGameEnded.value) {
          Get.back(); 
          isGameEnded.value = false;
        }
        gameOverMessage.value = '';
        _chess.reset();
        fenHistory.clear();
        moveHistorySan.clear();
        currentMoveIndex.value = -1;
      }

      if (_lastProcessedFen == serverFen && winner == null) return;
      _lastProcessedFen = serverFen;

      if (serverPgn.isNotEmpty) {
        _chess.load_pgn(serverPgn);
      } else {
        _chess.load(serverFen);
      }

      bool isOpponentMove = lastMoveData != null && lastMoveData['by'] != myColor.value;
      if (isOpponentMove && lastMoveData != null && !isAnimating.value) {
        await _triggerAnimation(
          lastMoveData['from'], 
          lastMoveData['to'],
          serverFen 
        );
      }

      _updateHistoryAndUI(serverFen);

      if (!isGameEnded.value) {
        if (winner != null) {
           if (winner == 'draw') {
             _showGameOverDialog("Game Drawn", "by mutual agreement");
           } else {
             _handleResignation(winner);
           }
        } else if (_chess.in_checkmate) {
           String winnerColor = _chess.turn == chess_lib.Color.WHITE ? "Black" : "White";
           _showGameOverDialog("$winnerColor Won", "by checkmate");
        } else if (_chess.in_draw || _chess.in_stalemate || _chess.in_threefold_repetition) {
           _showGameOverDialog("Draw", "by stalemate or repetition");
        }
      }
    });
  }

  Future<void> _triggerAnimation(String from, String to, String targetFen) async {
    final tempGame = chess_lib.Chess();
    tempGame.load(targetFen);
    final piece = tempGame.get(to); 
    
    if (piece != null) {
      animPieceChar.value = piece.type.toString(); 
      if (piece.color == chess_lib.Color.WHITE) {
        animPieceChar.value = animPieceChar.value.toUpperCase();
      } else {
        animPieceChar.value = animPieceChar.value.toLowerCase();
      }
      
      animStartSquare.value = from;
      animEndSquare.value = from;
      isAnimating.value = true;
      
      await Future.delayed(const Duration(milliseconds: 20));
      
      animEndSquare.value = to;
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      isAnimating.value = false;
    }
  }

  void _updateHistoryAndUI(String serverFen) {
    if (fenHistory.isEmpty || fenHistory.last != serverFen) {
        fenHistory.add(serverFen);
        
        List<String> pgnMoves = _chess.pgn().split(' ');
        List<String> cleanMoves = pgnMoves
            .where((s) => s.isNotEmpty && !s.contains('.'))
            .toList();
            
        List<String> fancyMoves = [];
        for (int i = 0; i < cleanMoves.length; i++) {
          String move = cleanMoves[i];
          bool isWhiteMove = (i % 2 == 0);
          
          if (isWhiteMove) {
            move = move.replaceAll('K', '♔')
                       .replaceAll('Q', '♕')
                       .replaceAll('R', '♖')
                       .replaceAll('B', '♗')
                       .replaceAll('N', '♘');
          } else {
            move = move.replaceAll('K', '♚')
                       .replaceAll('Q', '♛')
                       .replaceAll('R', '♜')
                       .replaceAll('B', '♝')
                       .replaceAll('N', '♞');
          }
          fancyMoves.add(move);
        }
        
        moveHistorySan.assignAll(fancyMoves);
        if (currentMoveIndex.value == fenHistory.length - 2 || currentMoveIndex.value == -1) {
           jumpToLatest();
        }
      }

    if (currentMoveIndex.value == fenHistory.length - 1 || currentMoveIndex.value == -1) {
        displayFen.value = serverFen;
    }
    
    fen.value = serverFen;
    isWhiteTurn.value = _chess.turn == chess_lib.Color.WHITE;

    isMyTurn.value = (_chess.turn == chess_lib.Color.WHITE && myColor.value == 'w') ||
                     (_chess.turn == chess_lib.Color.BLACK && myColor.value == 'b');
  }

  Future<void> makeMove({required String from, required String to, String? promotion}) async {
    if (isGameEnded.value) return; 
    if (currentMoveIndex.value != fenHistory.length - 1) return;
    if (!isMyTurn.value) return;

    try {
      final moveMap = {'from': from, 'to': to};
      if (promotion != null) moveMap['promotion'] = promotion;

      bool success = _chess.move(moveMap);
      
      if (success) {
        clearHighlights();
        displayFen.value = _chess.fen; 
        
        await _db.collection('games').doc(gameId.value).update({
          'fen': _chess.fen, 
          'pgn': _chess.pgn(),
          'lastMove': {'from': from, 'to': to, 'promotion': promotion, 'by': myColor.value}
        });
      } else {
        displayFen.refresh(); 
      }
    } catch (e) {
      displayFen.refresh();
    }
  }

  Future<void> resignGame() async {
    String winner = myColor.value == 'w' ? 'b' : 'w';
    await _db.collection('games').doc(gameId.value).update({
      'winner': winner
    });
  }

  Future<void> declareDraw() async {
    await _db.collection('games').doc(gameId.value).update({
      'winner': 'draw'
    });
  }

  Future<void> triggerRematch() async {
    var doc = await _db.collection('games').doc(gameId.value).get();
    String currentWhite = doc['white'];
    String currentBlack = doc['black'];

    await _db.collection('games').doc(gameId.value).update({
      'white': currentBlack,
      'black': currentWhite,
      'fen': chess_lib.Chess.DEFAULT_POSITION,
      'pgn': '',
      'lastMove': null,
      'winner': null
    });
  }

  void _handleResignation(String winnerColor) {
    String title = winnerColor == 'w' ? "White Won" : "Black Won";
    _showGameOverDialog(title, "by resignation");
  }

  void _showGameOverDialog(String title, String subtitle) {
    isGameEnded.value = true;
    
    const Color bgColor = Color(0xFFF0D9B5);
    const Color textColor = Color(0xFF5D4037);
    const Color btnColor = Color(0xFFB58863);

    Get.defaultDialog(
      title: title,
      titleStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
      backgroundColor: bgColor,
      radius: 12,
      content: Column(
        children: [
          const Icon(Icons.emoji_events, size: 60, color: btnColor),
          const SizedBox(height: 12),
          Text(subtitle, style: const TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
        ],
      ),
      barrierDismissible: false, 
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () {
                  Get.offAll(() => const LobbyView());
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: textColor, width: 2),
                  foregroundColor: textColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text("Lobby", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Get.back();
                  isGameEnded.value = false;
                  triggerRematch();
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text("Rematch", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 4,
                ),
              ),
            ],
          ),
        )
      ]
    );
  }

  void jumpToLatest() {
    if (fenHistory.isEmpty) return;
    currentMoveIndex.value = fenHistory.length - 1;
    displayFen.value = fenHistory.last;
  }

  void goToPrevious() {
    if (currentMoveIndex.value > 0) {
      currentMoveIndex.value--;
      displayFen.value = fenHistory[currentMoveIndex.value];
    }
  }

  void goToNext() {
    if (currentMoveIndex.value < fenHistory.length - 1) {
      currentMoveIndex.value++;
      displayFen.value = fenHistory[currentMoveIndex.value];
    }
  }

  void jumpToStart() {
    if (fenHistory.isNotEmpty) {
      currentMoveIndex.value = 0;
      displayFen.value = fenHistory[0];
    }
  }
  void jumpToMove(int index) {
    int target = index + 1;
    if (target < fenHistory.length) {
      currentMoveIndex.value = target;
      displayFen.value = fenHistory[target];
    }
  }
  
  void onSquareTap(String square) {
    if (isGameEnded.value) return; 
    
    if (validMoveHighlights.containsKey(square)) {
      makeMove(from: _selectedSquare!, to: square);
      return;
    }
    final piece = _chess.get(square);
    bool isMyPiece = piece != null && 
                     ((myColor.value == 'w' && piece.color == chess_lib.Color.WHITE) ||
                      (myColor.value == 'b' && piece.color == chess_lib.Color.BLACK));

    if (isMyPiece) {
      _selectedSquare = square;
      final moves = _chess.moves({'square': square, 'verbose': true});
      final newHighlights = <String, Color>{};
      newHighlights[square] = const Color(0xFF64B5F6).withOpacity(0.6); 
      for (var move in moves) {
        String targetSquare = move['to']; 
        newHighlights[targetSquare] = const Color(0xFF81C784).withOpacity(0.6); 
      }
      validMoveHighlights.value = newHighlights;
      validMoveHighlights.refresh(); 
    } else {
      clearHighlights();
    }
  }
  void clearHighlights() {
    validMoveHighlights.clear();
    _selectedSquare = null;
  }
}
