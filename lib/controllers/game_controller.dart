import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'dart:math';
import '../controllers/auth_controller.dart';
import '../views/lobby_view.dart';
import '../controllers/sound_controller.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';

class GameController extends GetxController {
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

  RxString displayFen = ''.obs; 
  RxList<String> fenHistory = <String>[].obs; 
  RxList<String> moveHistorySan = <String>[].obs; 
  RxInt currentMoveIndex = (-1).obs;

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
      
      if (data.containsKey('movesLeft')) {
        movesLeft.value = data['movesLeft'];
      }

      List<dynamic> serverMoves = data['moves'] ?? [];
      List<String> groupedMoves = [];
      String currentGroup = "";
      String lastColor = "";

      for (var moveObj in serverMoves) {
        String rawMove = moveObj.toString();
        String colorPrefix = "";
        String cleanMove = rawMove;

        if (rawMove.length > 2 && rawMove[1] == ':') {
          colorPrefix = rawMove.substring(0, 1);
          cleanMove = rawMove.substring(2);
        }

        if (colorPrefix == 'w') {
          cleanMove = cleanMove.replaceAll('K', '♔').replaceAll('Q', '♕').replaceAll('R', '♖').replaceAll('B', '♗').replaceAll('N', '♘');
        } else if (colorPrefix == 'b') {
          cleanMove = cleanMove.replaceAll('K', '♔').replaceAll('Q', '♕').replaceAll('R', '♜').replaceAll('B', '♝').replaceAll('N', '♞');
        }

        if (cleanMove == "Pass") {
           if (currentGroup.isNotEmpty) groupedMoves.add(currentGroup);
           groupedMoves.add("Pass");
           currentGroup = "";
           lastColor = colorPrefix == 'w' ? 'b' : 'w';
           continue;
        }

        if (colorPrefix == lastColor && colorPrefix.isNotEmpty) {
          if (currentGroup.isNotEmpty) currentGroup += ", ";
          currentGroup += cleanMove;
        } else {
          if (currentGroup.isNotEmpty) groupedMoves.add(currentGroup);
          currentGroup = cleanMove;
          lastColor = colorPrefix;
        }
      }
      if (currentGroup.isNotEmpty) groupedMoves.add(currentGroup);
      moveHistorySan.assignAll(groupedMoves);

      gameMode.value = data['mode'] ?? 'classical';
      
      if (data['dice'] != null) {
        currentDice.assignAll(List<int>.from(data['dice']));
      } else {
        currentDice.clear();
      }

      if (serverMoves.isEmpty && movesLeft.value == 0) {
         if (gameMode.value == 'vegas') movesLeft.value = 1;
         if (gameMode.value == 'boa') movesLeft.value = 3; 
      }

      if (serverFen == chess_lib.Chess.DEFAULT_POSITION && serverMoves.isEmpty && fenHistory.isEmpty) {
        SoundController.instance.playGameStart(); 
      }

      if (serverFen == chess_lib.Chess.DEFAULT_POSITION && serverMoves.isEmpty) {
        if (isGameEnded.value) { Get.back(); isGameEnded.value = false; }
        gameOverMessage.value = '';
        _chess.reset();
        fenHistory.clear();
        moveHistorySan.clear();
        currentMoveIndex.value = -1;
      }

      if (_lastProcessedFen == serverFen && winner == null) return;
      _lastProcessedFen = serverFen;

      _chess.load(serverFen);

      bool isOpponentMove = lastMoveData != null && lastMoveData['by'] != myColor.value;
      if (isOpponentMove && lastMoveData != null && !isAnimating.value) {
        if (lastMoveData['from'] != 'pass' && lastMoveData['from'] != lastMoveData['to']) {
           await _triggerAnimation(lastMoveData['from'], lastMoveData['to'], serverFen);
           if (!_chess.game_over) {
               if (_chess.in_check) {
                  SoundController.instance.playCheck();
               } 
               else if (serverMoves.isNotEmpty && serverMoves.last.toString().contains('x')) {
                  SoundController.instance.playCapture(); 
               } 
               else {
                  SoundController.instance.playOpponentMove(); 
               }
           }
        }
      }

      _updateHistoryAndUI(serverFen);

      if (isMyTurn.value) {
        if (gameMode.value == 'dice' || gameMode.value == 'boa') {
          _checkDiceLegalMoves();
        } else {
          canMakeAnyMove.value = true;
        }
      }

      if (!isGameEnded.value) {
        if (winner != null) {
           SoundController.instance.playGameEnd(); 
           if (winner == 'draw') _showGameOverDialog("Game Drawn", "by mutual agreement");
           else _handleResignation(winner);
        } else if (_chess.in_checkmate) {
           SoundController.instance.playGameEnd(); 
           String winnerColor = _chess.turn == chess_lib.Color.WHITE ? "Black" : "White";
           _showGameOverDialog("$winnerColor Won", "by checkmate");
           if (winner == null) _db.collection('games').doc(gameId.value).update({'winner': winnerColor == "White" ? 'w' : 'b'});
        } else if (_chess.in_draw || _chess.in_stalemate) {
           SoundController.instance.playGameEnd(); 
           _showGameOverDialog("Draw", "by stalemate");
           if (winner == null) _db.collection('games').doc(gameId.value).update({'winner': 'draw'});
        }
      }
    });
  }

  void _checkDiceLegalMoves() {
    final tempGame = chess_lib.Chess();
    tempGame.load(_chess.fen);
    List<dynamic> allMoves = tempGame.moves({'asObjects': true});
    bool foundLegalMove = false;
    
    for (var move in allMoves) {
      chess_lib.PieceType type;
      if (move is Map) type = move['piece']; 
      else type = move.piece; 
      
      int diceValue = _getPieceDiceValue(type);
      if (currentDice.contains(diceValue)) {
        foundLegalMove = true;
        break; 
      }
    }
    canMakeAnyMove.value = foundLegalMove;
    
    if (!foundLegalMove && isMyTurn.value && _chess.in_check) {
      Get.snackbar("Checkmate!", "Bad luck! Your dice cannot save the King.", 
        backgroundColor: Colors.red, colorText: Colors.white, duration: const Duration(seconds: 4));
      Future.delayed(const Duration(seconds: 3), () => resignGame());
    }
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
        if (currentMoveIndex.value == fenHistory.length - 2 || currentMoveIndex.value == -1) {
           jumpToLatest();
        }
    }

    if (currentMoveIndex.value == fenHistory.length - 1 || currentMoveIndex.value == -1) {
        displayFen.value = serverFen;
    }
    
    fen.value = serverFen;
    isWhiteTurn.value = _chess.turn == chess_lib.Color.WHITE;

    if (_chess.in_check) {
      String? kingSquare = _findKingSquare(_chess.turn);
      if (kingSquare != null) {
        validMoveHighlights[kingSquare] = Colors.red.withOpacity(0.6);
      }
    } else {
      if (_selectedSquare == null) {
        validMoveHighlights.clear();
      }
    }

    isMyTurn.value = (_chess.turn == chess_lib.Color.WHITE && myColor.value == 'w') ||
                     (_chess.turn == chess_lib.Color.BLACK && myColor.value == 'b');
  }

  Future<void> makeMove({required String from, required String to, String? promotion, bool isTap = false}) async {
    if (isGameEnded.value) return; 
    if (currentMoveIndex.value != fenHistory.length - 1) return;
    if (!isMyTurn.value) return;

    int pieceValue = 0; 

    if (gameMode.value == 'dice' || gameMode.value == 'boa') {
      final piece = _chess.get(from);
      if (piece != null) {
        pieceValue = _getPieceDiceValue(piece.type);
        if (!currentDice.contains(pieceValue)) {
          Get.snackbar("Invalid Move", "Must match dice!", snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 1));
          return;
        }
      }
    }

    if (promotion == null && _isPromotion(from, to)) {
      promotion = await pickPromotionCharacter();
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
            if (isCheck) {
               SoundController.instance.playCheck();
            } else if (isCapture) {
               SoundController.instance.playCapture();
            } else {
               SoundController.instance.playMove();
            }
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
          if (nextDice.contains(pieceValue)) {
            nextDice.remove(pieceValue); 
          }
          
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

  bool _isPromotion(String from, String to) {
    final piece = _chess.get(from);
    if (piece == null || piece.type != chess_lib.PieceType.PAWN) return false;
    if (piece.color == chess_lib.Color.WHITE && to.endsWith('8')) return true;
    if (piece.color == chess_lib.Color.BLACK && to.endsWith('1')) return true;
    return false;
  }

  Future<String?> pickPromotionCharacter() async {
    bool isWhite = myColor.value == 'w';
    return await Get.dialog<String>(
      SimpleDialog(
        title: const Text('Promote to:', textAlign: TextAlign.center),
        backgroundColor: const Color(0xFFF0D9B5),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _promoOption('q', isWhite ? WhiteQueen() : BlackQueen()),
              _promoOption('r', isWhite ? WhiteRook() : BlackRook()),
              _promoOption('b', isWhite ? WhiteBishop() : BlackBishop()),
              _promoOption('n', isWhite ? WhiteKnight() : BlackKnight()),
            ],
          )
        ],
      ),
      barrierDismissible: false,
    );
  }

  Widget _promoOption(String char, Widget icon) {
    return InkWell(
      onTap: () => Get.back(result: char),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(width: 50, height: 50, child: icon),
      ),
    );
  }

  Future<void> passTurn() async {
    if (!isMyTurn.value) return;
    
    if (gameMode.value == 'classical' || gameMode.value == 'vegas') return;
    
    _checkDiceLegalMoves();
    if (canMakeAnyMove.value) {
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
          if (fenParts[1] == 'w') {
            fenParts[5] = (int.parse(fenParts[5]) + 1).toString();
          }
        } catch (e) {}
      }
    }
    String newFen = fenParts.join(' ');

    List<int> nextDice = [];
    int nextMovesLeft = 0;

    if (gameMode.value == 'boa') {
       nextMovesLeft = 3; 
       nextDice = [Random().nextInt(6)+1, Random().nextInt(6)+1, Random().nextInt(6)+1];
    } else {
       nextDice = [Random().nextInt(6)+1, Random().nextInt(6)+1, Random().nextInt(6)+1];
    }

    clearHighlights();
    
    await _db.collection('games').doc(gameId.value).update({
      'fen': newFen,
      'dice': nextDice,
      'moves': FieldValue.arrayUnion(["Pass"]),
      'lastMove': {'from': 'pass', 'to': 'pass', 'by': myColor.value},
      'movesLeft': nextMovesLeft
    });
  }

  int _getPieceDiceValue(chess_lib.PieceType type) {
    switch (type) {
      case chess_lib.PieceType.PAWN: return 1;
      case chess_lib.PieceType.KNIGHT: return 2;
      case chess_lib.PieceType.BISHOP: return 3;
      case chess_lib.PieceType.ROOK: return 4;
      case chess_lib.PieceType.QUEEN: return 5;
      case chess_lib.PieceType.KING: return 6;
      default: return 0;
    }
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
      if (gameMode.value == 'dice' || gameMode.value == 'boa') {
         int val = _getPieceDiceValue(piece.type);
         if (!currentDice.contains(val)) {
            return;
         }
      }
      final moves = _chess.moves({'square': square, 'verbose': true});
      final newHighlights = <String, Color>{};
      if (_chess.in_check) {
        String? kingSquare = _findKingSquare(_chess.turn);
        if (kingSquare != null) {
          newHighlights[kingSquare] = Colors.red.withOpacity(0.6);
        }
      }
      newHighlights[square] = const Color(0xFF64B5F6).withOpacity(0.6); 
      for (var move in moves) {
        String targetSquare = move['to']; 
        newHighlights[targetSquare] = const Color(0xFF81C784).withOpacity(0.6); 
      }
      validMoveHighlights.assignAll(newHighlights);
      validMoveHighlights.refresh(); 
    } else {
      clearHighlights();
    }
  }

  void clearHighlights() {
    validMoveHighlights.clear();
    _selectedSquare = null;
    if (_chess.in_check) {
      String? kingSquare = _findKingSquare(_chess.turn);
      if (kingSquare != null) {
        validMoveHighlights[kingSquare] = Colors.red.withOpacity(0.6);
      }
    }
  }
  
  String? _findKingSquare(chess_lib.Color color) {
    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    final ranks = ['1', '2', '3', '4', '5', '6', '7', '8'];
    for (var file in files) {
      for (var rank in ranks) {
        String square = '$file$rank';
        final piece = _chess.get(square);
        if (piece != null && 
            piece.type == chess_lib.PieceType.KING && 
            piece.color == color) {
          return square;
        }
      }
    }
    return null;
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
    _showGameOverDialog(title, "by resignation");
  }

  void _showGameOverDialog(String title, String subtitle) {
    isGameEnded.value = true;
    Get.defaultDialog(
      title: title,
      titleStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
      backgroundColor: const Color(0xFFF0D9B5),
      radius: 12,
      content: Column(
        children: [
          const Icon(Icons.emoji_events, size: 60, color: Color(0xFFB58863)),
          const SizedBox(height: 12),
          Text(subtitle, style: const TextStyle(fontSize: 18, color: Color(0xFF5D4037), fontWeight: FontWeight.w500)),
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
                onPressed: () => Get.offAll(() => const LobbyView()),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF5D4037), width: 2),
                  foregroundColor: const Color(0xFF5D4037),
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
                  backgroundColor: const Color(0xFFB58863),
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
}
