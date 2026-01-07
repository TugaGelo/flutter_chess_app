import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'dart:math';
import '../controllers/auth_controller.dart';
import '../controllers/sound_controller.dart';
import '../utils/chess_utils.dart';
import '../utils/game_dialogs.dart';
import '../utils/chess_rule_engine.dart';
import '../mixins/history_navigation_mixin.dart';

class GameController extends GetxController with HistoryNavigationMixin {
  static GameController instance = Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  RxString gameId = ''.obs;
  RxString myColor = ''.obs;
  RxBool isMyTurn = false.obs;
  RxBool isWhiteTurn = true.obs;
  RxBool isGameEnded = false.obs;
  RxString gameOverMessage = ''.obs;
  
  RxString gameMode = 'classical'.obs;
  RxList<int> currentDice = <int>[].obs;
  RxInt movesLeft = 0.obs;
  RxBool canMakeAnyMove = true.obs;
  
  RxString fen = ''.obs; 
  String _lastProcessedFen = '';

  RxBool isAnimating = false.obs;
  RxString animStartSquare = ''.obs; 
  RxString animEndSquare = ''.obs;   
  RxString animPieceChar = ''.obs;   

  RxMap<String, Color> validMoveHighlights = <String, Color>{}.obs;
  String? _selectedSquare;

  @override
  RxString displayFen = ''.obs; 
  @override
  RxList<String> fenHistory = <String>[].obs; 
  @override
  RxInt currentMoveIndex = (-1).obs;
  
  RxList<String> moveHistorySan = <String>[].obs; 
  final chess_lib.Chess _chess = chess_lib.Chess();

  void setGame(String id, String assignedColor) {
    gameId.value = id;
    myColor.value = assignedColor; 
    isGameEnded.value = false;
    
    _chess.reset();
    fenHistory.clear();
    moveHistorySan.clear();
    currentMoveIndex.value = -1;
    gameOverMessage.value = '';
    _lastProcessedFen = '';
    
    _connectToGameStream();
  }

  void _connectToGameStream() {
    _db.collection('games').doc(gameId.value).snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      var data = snapshot.data() as Map<String, dynamic>;
      
      String myUid = AuthController.instance.user!.uid;
      if (data['white'] == myUid) myColor.value = 'w';
      else if (data['black'] == myUid) myColor.value = 'b';

      String serverFen = data['fen'];
      Map<String, dynamic>? lastMoveData = data['lastMove'];
      String? winner = data['winner']; 
      
      if (data.containsKey('movesLeft')) movesLeft.value = data['movesLeft'];

      List<dynamic> serverMoves = data['moves'] ?? [];
      moveHistorySan.assignAll(ChessUtils.parseServerMoves(serverMoves));

      gameMode.value = data['mode'] ?? 'classical';
      
      if (data['dice'] != null) currentDice.assignAll(List<int>.from(data['dice']));
      else currentDice.clear();

      _reconstructGameHistory(serverMoves);

      if (serverMoves.isEmpty && movesLeft.value == 0) {
         if (gameMode.value == 'vegas') movesLeft.value = 1;
         if (gameMode.value == 'boa') movesLeft.value = 3; 
      }

      if (serverFen == chess_lib.Chess.DEFAULT_POSITION && serverMoves.isEmpty) {
        if (_lastProcessedFen == '') SoundController.instance.playGameStart();
      }

      if (_lastProcessedFen == serverFen && winner == null) return;
      _lastProcessedFen = serverFen;

      _chess.load(serverFen);

      bool isOpponentMove = lastMoveData != null && lastMoveData['by'] != myColor.value;
      if (isOpponentMove && lastMoveData != null && !isAnimating.value) {
        if (lastMoveData['from'] != 'pass' && lastMoveData['from'] != lastMoveData['to']) {
           await _triggerAnimation(lastMoveData['from'], lastMoveData['to'], serverFen);
           if (!_chess.game_over) {
               if (_chess.in_check) SoundController.instance.playCheck();
               else if (serverMoves.isNotEmpty && serverMoves.last.toString().contains('x')) SoundController.instance.playCapture();
               else SoundController.instance.playOpponentMove();
           }
        }
      }

      _updateUI(serverFen);

      if (isMyTurn.value) {
        if (gameMode.value == 'dice' || gameMode.value == 'boa') {
          canMakeAnyMove.value = ChessRuleEngine.canMakeAnyDiceMove(_chess, currentDice);
          if (!canMakeAnyMove.value && _chess.in_check) {
             _handleCheckmateByBadLuck();
          }
        } else {
          canMakeAnyMove.value = true;
        }
      }

      if (!isGameEnded.value) {
        if (winner != null) {
           SoundController.instance.playGameEnd(); 
           if (winner == 'draw') GameDialogs.showGameOver("Game Drawn", "by mutual agreement", triggerRematch);
           else _handleResignation(winner);
        } else if (_chess.in_checkmate) {
           SoundController.instance.playGameEnd(); 
           String winnerColor = _chess.turn == chess_lib.Color.WHITE ? "Black" : "White";
           GameDialogs.showGameOver("$winnerColor Won", "by checkmate", triggerRematch);
           if (winner == null) _db.collection('games').doc(gameId.value).update({'winner': winnerColor == "White" ? 'w' : 'b'});
        } else if (_chess.in_draw || _chess.in_stalemate) {
           SoundController.instance.playGameEnd(); 
           GameDialogs.showGameOver("Draw", "by stalemate", triggerRematch);
           if (winner == null) _db.collection('games').doc(gameId.value).update({'winner': 'draw'});
        }
      }
    });
  }

  void _handleCheckmateByBadLuck() {
    Get.snackbar("Checkmate!", "Bad luck! Your dice cannot save the King.", 
      backgroundColor: Colors.red, colorText: Colors.white, duration: const Duration(seconds: 4));
    Future.delayed(const Duration(seconds: 3), () => resignGame());
  }

  void _reconstructGameHistory(List<dynamic> serverMoves) {
    final tempGame = chess_lib.Chess();
    tempGame.reset();
    List<String> reconstructedHistory = [chess_lib.Chess.DEFAULT_POSITION];
    
    for (var moveStr in serverMoves) {
       String cleanMove = moveStr.toString();
       if (cleanMove.contains(':')) cleanMove = cleanMove.split(':')[1];
       
       if (cleanMove == 'Pass') {
          String currentFen = tempGame.fen;
          List<String> parts = currentFen.split(' ');
          parts[1] = parts[1] == 'w' ? 'b' : 'w'; 
          parts[3] = '-'; 
          if (parts[1] == 'w') {
             try { parts[5] = (int.parse(parts[5]) + 1).toString(); } catch(e) {}
          }
          String newFen = parts.join(' ');
          tempGame.load(newFen); 
          reconstructedHistory.add(newFen);
       } else {
          try {
             tempGame.move(cleanMove);
             reconstructedHistory.add(tempGame.fen);
          } catch (e) {
             print("Error replaying move: $cleanMove");
          }
       }
    }
    
    fenHistory.assignAll(reconstructedHistory);
    
    if (currentMoveIndex.value == -1 || currentMoveIndex.value >= fenHistory.length - 2) {
       currentMoveIndex.value = fenHistory.length - 1;
    }
  }

  Future<void> _triggerAnimation(String from, String to, String targetFen) async {
    final tempGame = chess_lib.Chess();
    tempGame.load(targetFen);
    final piece = tempGame.get(to); 
    
    if (piece != null) {
      animPieceChar.value = piece.type.toString(); 
      if (piece.color == chess_lib.Color.WHITE) animPieceChar.value = animPieceChar.value.toUpperCase();
      else animPieceChar.value = animPieceChar.value.toLowerCase();
      
      animStartSquare.value = from;
      animEndSquare.value = from;
      isAnimating.value = true;
      
      await Future.delayed(const Duration(milliseconds: 20));
      animEndSquare.value = to; 
      await Future.delayed(const Duration(milliseconds: 300));
      isAnimating.value = false;
    }
  }

  void _updateUI(String serverFen) {
    if (currentMoveIndex.value == fenHistory.length - 1 || currentMoveIndex.value == -1) {
        displayFen.value = serverFen;
    }
    
    fen.value = serverFen;
    isWhiteTurn.value = _chess.turn == chess_lib.Color.WHITE;

    if (_chess.in_check) {
      String? kingSquare = ChessRuleEngine.findKingSquare(_chess, _chess.turn);
      if (kingSquare != null) {
        validMoveHighlights[kingSquare] = Colors.red.withOpacity(0.6);
      }
    } else {
      if (_selectedSquare == null) validMoveHighlights.clear();
    }

    isMyTurn.value = (_chess.turn == chess_lib.Color.WHITE && myColor.value == 'w') ||
                     (_chess.turn == chess_lib.Color.BLACK && myColor.value == 'b');
  }

  void onSquareTap(String square) {
    if (isGameEnded.value) return; 
    
    if (validMoveHighlights.containsKey(square) && validMoveHighlights[square] != Colors.red.withOpacity(0.6)) {
       if (validMoveHighlights[square]!.value == const Color(0xFF81C784).withOpacity(0.6).value) {
         makeMove(from: _selectedSquare!, to: square, isTap: true);
         return;
       }
    }
    
    final piece = _chess.get(square);
    bool isMyPiece = piece != null && 
                     ((myColor.value == 'w' && piece.color == chess_lib.Color.WHITE) ||
                      (myColor.value == 'b' && piece.color == chess_lib.Color.BLACK));
                      
    if (isMyPiece) {
      _selectedSquare = square;
      
      Map<String, Color> newHighlights = ChessRuleEngine.getHighlights(
        chess: _chess, 
        square: square, 
        isDiceMode: (gameMode.value == 'dice' || gameMode.value == 'boa'), 
        currentDice: currentDice
      );
      
      if (newHighlights.isNotEmpty) {
         validMoveHighlights.assignAll(newHighlights);
      } else {
         clearHighlights();
      }
    } else {
      clearHighlights();
    }
  }

  void clearHighlights() {
    validMoveHighlights.clear();
    _selectedSquare = null;
    if (_chess.in_check) {
      String? kingSquare = ChessRuleEngine.findKingSquare(_chess, _chess.turn);
      if (kingSquare != null) {
        validMoveHighlights[kingSquare] = Colors.red.withOpacity(0.6);
      }
    }
  }

  Future<void> makeMove({required String from, required String to, String? promotion, bool isTap = false}) async {
    if (isGameEnded.value) return; 
    
    if (currentMoveIndex.value != fenHistory.length - 1) {
       Get.snackbar("History Mode", "Jump to the latest move to play.", 
         snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 1));
       return;
    }
    
    if (!isMyTurn.value) return;

    int pieceValue = 0; 
    if (gameMode.value == 'dice' || gameMode.value == 'boa') {
      final piece = _chess.get(from);
      if (piece != null) {
        pieceValue = ChessUtils.getPieceDiceValue(piece.type);
        if (!currentDice.contains(pieceValue)) {
          Get.snackbar("Invalid Move", "Must match dice!", snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 1));
          return;
        }
      }
    }

    if (promotion == null && ChessRuleEngine.isPromotion(_chess, from, to)) {
      promotion = await GameDialogs.showPromotion(myColor.value == 'w');
      if (promotion == null) return; 
    }

    try {
      final moveMap = {'from': from, 'to': to};
      if (promotion != null) moveMap['promotion'] = promotion;

      bool isCapture = _chess.get(to) != null; 

      bool success = _chess.move(moveMap);
      
      if (success) {
        if (!_chess.game_over) {
            bool isCheck = _chess.in_check; 
            if (isCheck) SoundController.instance.playCheck();
            else if (isCapture) SoundController.instance.playCapture();
            else SoundController.instance.playMove();
        }

        String pgn = _chess.pgn();
        List<String> pgnTokens = pgn.split(' ').where((t) => t.trim().isNotEmpty && !t.contains('.')).toList();
        String moveSan = pgnTokens.isNotEmpty ? pgnTokens.last : '';
        if (['1-0', '0-1', '1/2-1/2', '*'].contains(moveSan) && pgnTokens.length > 1) {
           moveSan = pgnTokens[pgnTokens.length - 2];
        }

        String signedMove = "${myColor.value}:$moveSan"; 
        String finalFen = _chess.fen;
        int nextMovesLeft = 0;
        List<int> nextDice = List.from(currentDice);

        clearHighlights();
        if (isTap) await _triggerAnimation(from, to, finalFen);

        displayFen.value = finalFen; 

        if (gameMode.value == 'boa') {
          if (nextDice.contains(pieceValue)) nextDice.remove(pieceValue);
          
          int current = movesLeft.value > 0 ? movesLeft.value : 1;
          nextMovesLeft = current - 1;

          if (_chess.in_check || _chess.in_checkmate) {
            nextMovesLeft = 0;
            if (_chess.in_check) {
               Get.snackbar("Check!", "Turn ends immediately!", 
                 backgroundColor: Colors.red, colorText: Colors.white, duration: const Duration(seconds: 2));
            }
          }

          if (nextMovesLeft > 0) {
            List<String> parts = finalFen.split(' ');
            parts[1] = myColor.value; 
            parts[3] = '-'; 
            finalFen = parts.join(' ');
            _chess.load(finalFen);
            displayFen.value = finalFen;
          } else {
            nextMovesLeft = 3;
            nextDice = [Random().nextInt(6)+1, Random().nextInt(6)+1, Random().nextInt(6)+1];
          }
        }
        else if (gameMode.value == 'vegas') {
          int current = movesLeft.value > 0 ? movesLeft.value : 1; 
          nextMovesLeft = current - 1;

          if (_chess.in_check || _chess.in_checkmate) {
            nextMovesLeft = 0;
            if (_chess.in_check) {
               Get.snackbar("Check!", "Turn ends immediately!", 
                 backgroundColor: Colors.red, colorText: Colors.white, duration: const Duration(seconds: 2));
            }
          }

          if (nextMovesLeft > 0) {
            List<String> parts = finalFen.split(' ');
            parts[1] = myColor.value;
            parts[3] = '-';
            finalFen = parts.join(' ');
            _chess.load(finalFen);
            displayFen.value = finalFen;
          } else {
            int roll = Random().nextInt(6) + 1;
            if (roll <= 2) nextMovesLeft = 1;
            else if (roll <= 4) nextMovesLeft = 2;
            else nextMovesLeft = 3;
            nextDice = [roll];
          }
        } 
        else if (gameMode.value == 'dice') {
           nextDice = [Random().nextInt(6)+1, Random().nextInt(6)+1, Random().nextInt(6)+1];
        }

        await _db.collection('games').doc(gameId.value).update({
          'fen': finalFen, 
          'pgn': _chess.pgn(),
          'moves': FieldValue.arrayUnion([signedMove]), 
          'lastMove': {'from': from, 'to': to, 'promotion': promotion, 'by': myColor.value},
          'dice': nextDice,
          'movesLeft': nextMovesLeft
        });
      } else {
        displayFen.refresh(); 
      }
    } catch (e) {
      displayFen.refresh();
    }
  }

  Future<void> passTurn() async {
    if (!isMyTurn.value) return;
    if (gameMode.value == 'classical' || gameMode.value == 'vegas') return;
    
    if (ChessRuleEngine.canMakeAnyDiceMove(_chess, currentDice)) {
       Get.snackbar("Cannot Pass", "You have legal moves! You must play.", 
         backgroundColor: Colors.red, colorText: Colors.white);
       return;
    }

    String currentFen = _chess.fen;
    List<String> fenParts = currentFen.split(' ');
    if (fenParts.length >= 2) {
      fenParts[1] = fenParts[1] == 'w' ? 'b' : 'w'; 
      if (fenParts.length >= 6) {
        try {
          if (fenParts[1] == 'w') fenParts[5] = (int.parse(fenParts[5]) + 1).toString();
        } catch (e) {}
      }
    }
    String newFen = fenParts.join(' ');

    List<int> nextDice = [Random().nextInt(6)+1, Random().nextInt(6)+1, Random().nextInt(6)+1];
    int nextMovesLeft = (gameMode.value == 'boa') ? 3 : 0;

    clearHighlights();
    
    await _db.collection('games').doc(gameId.value).update({
      'fen': newFen,
      'dice': nextDice,
      'moves': FieldValue.arrayUnion(["Pass"]),
      'lastMove': {'from': 'pass', 'to': 'pass', 'by': myColor.value},
      'movesLeft': nextMovesLeft
    });
  }
  
  Future<void> resignGame() async {
    String winner = myColor.value == 'w' ? 'b' : 'w';
    await _db.collection('games').doc(gameId.value).update({'winner': winner});
  }

  Future<void> declareDraw() async {
    await _db.collection('games').doc(gameId.value).update({'winner': 'draw'});
  }

  Future<void> triggerRematch() async {
    var doc = await _db.collection('games').doc(gameId.value).get();
    String currentWhite = doc['white'];
    String currentBlack = doc['black'];
    String mode = doc['mode'] ?? 'classical';
    List<int> initialDice = [];
    if (mode == 'dice' || mode == 'boa') {
      Random rng = Random();
      initialDice = [rng.nextInt(6)+1, rng.nextInt(6)+1, rng.nextInt(6)+1];
    }
    await _db.collection('games').doc(gameId.value).update({
      'white': currentBlack,
      'black': currentWhite,
      'fen': chess_lib.Chess.DEFAULT_POSITION,
      'pgn': '',
      'moves': [],
      'lastMove': null,
      'winner': null,
      'dice': initialDice,
      'movesLeft': (mode == 'vegas') ? 1 : (mode == 'boa' ? 3 : 0)
    });
  }

  void _handleResignation(String winnerColor) {
    String title = winnerColor == 'w' ? "White Won" : "Black Won";
    GameDialogs.showGameOver(title, "by resignation", triggerRematch);
  }
}
