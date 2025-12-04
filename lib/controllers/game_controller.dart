import 'package:flutter/material.dart'; // Needed for Color
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../controllers/auth_controller.dart';

class GameController extends GetxController {
  static GameController instance = Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  RxString gameId = ''.obs;
  RxString myColor = ''.obs;
  RxBool isMyTurn = false.obs;
  RxString gameOverMessage = ''.obs;
  RxBool isWhiteTurn = true.obs;
  
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
    _connectToGameStream();
  }

  void _connectToGameStream() {
    _db.collection('games').doc(gameId.value).snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;

      var data = snapshot.data() as Map<String, dynamic>;
      String serverFen = data['fen'];
      String serverPgn = data['pgn'] ?? ''; 
      Map<String, dynamic>? lastMoveData = data['lastMove'];

      if (_lastProcessedFen == serverFen) return;
      _lastProcessedFen = serverFen;

      if (serverPgn.isNotEmpty) {
        _chess.load_pgn(serverPgn);
      } else {
        _chess.load(serverFen);
      }

      bool isOpponentMove = lastMoveData != null && lastMoveData['by'] != myColor.value;
      
      if (isOpponentMove && lastMoveData != null) {
        await _triggerAnimation(
          lastMoveData['from'], 
          lastMoveData['to'],
          serverFen 
        );
      }

      _updateHistoryAndUI(serverFen);
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

    if (_chess.in_checkmate) {
      gameOverMessage.value = isMyTurn.value ? "You Lost!" : "You Won!";
    } else if (_chess.in_draw) {
      gameOverMessage.value = "Draw!";
    }
  }

  void onSquareTap(String square) {
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

  Future<void> makeMove({required String from, required String to, String? promotion}) async {
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
}
