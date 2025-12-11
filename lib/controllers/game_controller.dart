import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:bishop/bishop.dart' as bishop; 
import 'package:squares/squares.dart' as squares;
import 'dart:math';
import '../controllers/auth_controller.dart';
import '../views/lobby_view.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';

class GameController extends GetxController {
  static GameController instance = Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<DocumentSnapshot>? _gameSubscription;

  RxString gameId = ''.obs;
  RxString myColor = ''.obs;
  RxBool isMyTurn = false.obs;
  RxString gameMode = 'classical'.obs;
  RxList<int> currentDice = <int>[].obs;
  RxBool isGameEnded = false.obs;
  RxBool canMakeAnyMove = true.obs;

  late bishop.Game game;
  late squares.BoardState boardState;
  late squares.PieceSet pieceSet;
  
  String boardKey = "";
  
  Rxn<int> selectedSquare = Rxn<int>();
  RxList<int> validMoves = <int>[].obs;
  
  Map<String, dynamic>? lastMoveConfig; 
  
  bool enableAnimation = true;

  List<String> fenHistory = [];
  RxString displayFen = ''.obs; 
  RxList<String> moveHistorySan = <String>[].obs; 
  RxInt currentMoveIndex = (-1).obs;

  @override
  void onInit() {
    super.onInit();
    pieceSet = squares.PieceSet.merida();
    _initGame();
  }

  @override
  void onClose() {
    _unsubscribeFromGame();
    super.onClose();
  }

  void _unsubscribeFromGame() {
    if (_gameSubscription != null) {
      _gameSubscription!.cancel();
      _gameSubscription = null;
    }
  }

  void _initGame([String? fen]) {
    game = bishop.Game(variant: bishop.Variant.standard());
    if (fen != null) game.loadFen(fen);

    _updateUi();
    
    fenHistory = [game.fen];
    displayFen.value = game.fen;
    currentMoveIndex.value = 0;
  }

  String _toAlgebraic(int index) {
    int file = index % 8;
    int rank = 8 - (index ~/ 8);
    String fileChar = String.fromCharCode('a'.codeUnitAt(0) + file);
    return "$fileChar$rank";
  }

  int _fromAlgebraic(String square) {
    if (square.length != 2) return -1;
    int file = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    int rank = int.parse(square[1]);
    return (8 - rank) * 8 + file;
  }

  squares.BoardState _createBoardState(bishop.Game game) {
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

    int? from;
    int? to;
    
    if (lastMoveConfig != null) {
      from = _fromAlgebraic(lastMoveConfig!['from']);
      to = _fromAlgebraic(lastMoveConfig!['to']);
    } else if (game.history.isNotEmpty) {
      var lastMove = game.history.last.move;
      if (lastMove != null) {
        String fromAlg = game.size.squareName(lastMove.from);
        String toAlg = game.size.squareName(lastMove.to);
        from = _fromAlgebraic(fromAlg);
        to = _fromAlgebraic(toAlg);
      }
    }

    return squares.BoardState(
      board: boardList, 
      lastFrom: from,
      lastTo: to,
      orientation: myColor.value == 'b' ? 1 : 0, 
    );
  }

  void _updateUi() {
    boardKey = DateTime.now().millisecondsSinceEpoch.toString();
    boardState = _createBoardState(game);
    update();
  }

  void handleTap(int square) {
    if (currentMoveIndex.value != fenHistory.length - 1) return;
    if (!isMyTurn.value) return;

    String piece = boardState.board[square];
    bool isOwnPiece = false;
    if (piece.isNotEmpty) {
      bool isWhitePiece = piece == piece.toUpperCase();
      isOwnPiece = (myColor.value == 'w' && isWhitePiece) || 
                   (myColor.value == 'b' && !isWhitePiece);
    }

    if (selectedSquare.value != null) {
      if (selectedSquare.value == square) {
        selectedSquare.value = null;
        validMoves.clear();
        update();
        return;
      }

      if (isOwnPiece) {
        selectedSquare.value = square;
        _calculateValidMoves(square);
        update();
        return;
      }
      
      onUserMove(squares.Move(from: selectedSquare.value!, to: square));
    } else {
      if (isOwnPiece) {
        selectedSquare.value = square;
        _calculateValidMoves(square);
        update();
      }
    }
  }

  void _calculateValidMoves(int square) {
    String algFrom = _toAlgebraic(square);
    var moves = game.generateLegalMoves().where((m) {
      String mFrom = game.size.squareName(m.from);
      return mFrom == algFrom;
    });
    
    validMoves.value = moves.map((m) {
      String mTo = game.size.squareName(m.to);
      return _fromAlgebraic(mTo);
    }).toList();
  }

  void onUserMove(squares.Move move) async {
    selectedSquare.value = null;
    validMoves.clear();

    if (currentMoveIndex.value != fenHistory.length - 1) return;
    if (!isMyTurn.value) return;

    String pieceSymbol = boardState.board[move.from]; 
    if (pieceSymbol.isEmpty) return;
    
    bool isWhitePiece = pieceSymbol == pieceSymbol.toUpperCase();
    if (myColor.value == 'w' && !isWhitePiece) return;
    if (myColor.value == 'b' && isWhitePiece) return;

    int type = _symbolToType(pieceSymbol);

    if (gameMode.value == 'dice') {
      int diceVal = type; 
      if (!currentDice.contains(diceVal)) {
        Get.snackbar("Invalid Move", "Dice require a ${_getPieceName(diceVal)}");
        _updateUi();
        return;
      }
    }

    bool isPawn = type == 1; 
    int toIndex = move.to;
    bool isPromoRank = (toIndex < 8 || toIndex >= 56);
    
    String? promoChar;
    if (isPawn && isPromoRank && move.promo == null) {
        promoChar = await _showPromotionDialog();
        if (promoChar == null) {
          _updateUi();
          return; 
        }
    }

    String algFrom = _toAlgebraic(move.from);
    String algTo = _toAlgebraic(move.to);
    String moveString = "$algFrom$algTo${promoChar ?? ''}";

    if (!game.isMoveValid(moveString)) {
      _updateUi();
      return;
    }

    var bishopMove = game.getMove(moveString);
    String san = bishopMove != null ? game.toSan(bishopMove) : moveString;

    bool result = game.makeMoveString(moveString);
    
    if (result) {
      lastMoveConfig = { 'from': algFrom, 'to': algTo };
      
      fenHistory.add(game.fen);
      currentMoveIndex.value = fenHistory.length - 1;
      
      enableAnimation = false;
      _updateUi(); 
      _submitMoveToServer(moveString, san);
    } else {
      _updateUi();
    }
  }

  Future<void> _submitMoveToServer(String algMove, String san) async {
    try {
      List<int> nextDice = [];
      if (gameMode.value == 'dice') {
          nextDice = [Random().nextInt(6)+1, Random().nextInt(6)+1, Random().nextInt(6)+1];
      }

      String fromAlg = algMove.substring(0, 2);
      String toAlg = algMove.substring(2, 4);

      await _db.collection('games').doc(gameId.value).update({
        'fen': game.fen, 
        'moves': FieldValue.arrayUnion([san]), 
        'lastMove': {
          'from': fromAlg, 
          'to': toAlg, 
          'by': myColor.value
        },
        'dice': nextDice 
      });
    } catch (e) {
      print("Firestore Error: $e");
    }
  }

  void jumpToMove(int index) {
    if (index < 0 || index >= fenHistory.length) return;
    currentMoveIndex.value = index;
    
    bishop.Game tempGame = bishop.Game(variant: bishop.Variant.standard());
    tempGame.loadFen(fenHistory[index]);
    
    selectedSquare.value = null;
    validMoves.clear();
    lastMoveConfig = null; 
    
    enableAnimation = false;
    boardKey = "history_$index"; 
    boardState = _createBoardState(tempGame);
    update();
  }

  void nextMove() => jumpToMove(currentMoveIndex.value + 1);
  void prevMove() => jumpToMove(currentMoveIndex.value - 1);
  void jumpToLive() {
    currentMoveIndex.value = fenHistory.length - 1;
    bishop.Game liveGame = bishop.Game(variant: bishop.Variant.standard());
    liveGame.loadFen(fenHistory.last);
    
    lastMoveConfig = null; 
    enableAnimation = false;
    boardKey = "live";
    boardState = _createBoardState(liveGame);
    update(); 
  }

  int _symbolToType(String symbol) {
    switch (symbol.toLowerCase()) {
      case 'p': return 1;
      case 'n': return 2;
      case 'b': return 3;
      case 'r': return 4;
      case 'q': return 5;
      case 'k': return 6;
      default: return 0;
    }
  }

  void _checkDiceLegalMoves() {
    var moves = game.generateLegalMoves();
    bool found = false;
    for (var move in moves) {
      int pieceType = game.board[move.from].abs(); 
      if (currentDice.contains(pieceType)) {
        found = true;
        break;
      }
    }
    canMakeAnyMove.value = found;
  }

  Future<String?> _showPromotionDialog() async {
     bool isWhite = myColor.value == 'w';
     return await Get.dialog<String>(
      SimpleDialog(
        title: const Text('Promote to:', textAlign: TextAlign.center),
        backgroundColor: const Color(0xFFF0D9B5),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _promoOption("Queen", 'q', isWhite ? WhiteQueen() : BlackQueen()),
              _promoOption("Rook", 'r', isWhite ? WhiteRook() : BlackRook()),
              _promoOption("Bishop", 'b', isWhite ? WhiteBishop() : BlackBishop()),
              _promoOption("Knight", 'n', isWhite ? WhiteKnight() : BlackKnight()),
            ],
          )
        ],
      ),
      barrierDismissible: false,
    );
  }

  Widget _promoOption(String label, String char, Widget icon) {
    return InkWell(
      onTap: () => Get.back(result: char),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(width: 50, height: 50, child: icon),
      ),
    );
  }

  String _getPieceName(int type) {
    switch (type) {
      case 1: return "Pawn";
      case 2: return "Knight";
      case 3: return "Bishop";
      case 4: return "Rook";
      case 5: return "Queen";
      case 6: return "King";
      default: return "Piece";
    }
  }

  Future<void> resignGame() async { 
    String winner = myColor.value == 'w' ? 'b' : 'w';
    await _db.collection('games').doc(gameId.value).update({'winner': winner});
  }
  
  Future<void> declareDraw() async {
    await _db.collection('games').doc(gameId.value).update({'winner': 'draw'});
  }
  
  void _handleGameOver(String winner) {
    if (isGameEnded.value) return;
    
    isGameEnded.value = true;
    _unsubscribeFromGame(); 

    bool isDraw = winner == 'draw';
    bool iWon = (winner == myColor.value);
    
    String title = isDraw ? "Game Drawn" : (iWon ? "You Won!" : "You Lost");
    IconData icon = isDraw ? Icons.handshake : (iWon ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded);
    Color iconColor = isDraw ? Colors.brown : (iWon ? Colors.amber[700]! : Colors.grey);
    String message = isDraw ? "Good Game!" : (iWon ? "Congratulations!" : "Better luck next time.");

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF5F5F5),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 64, color: iconColor),
              ),
              const SizedBox(height: 24),
              
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold,
                  color: Colors.black87
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                message,
                style: TextStyle(
                  fontSize: 16, 
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic
                ),
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.offAll(() => const LobbyView()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513), // SaddleBrown
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    "Back to Lobby", 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void setGame(String id, String assignedColor) {
    _unsubscribeFromGame();
    
    gameId.value = id;
    myColor.value = assignedColor; 
    isGameEnded.value = false;
    lastMoveConfig = null;
    
    _initGame(); 
    
    _connectToGameStream();
  }

  void _connectToGameStream() {
    _gameSubscription = _db.collection('games').doc(gameId.value).snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      var data = snapshot.data() as Map<String, dynamic>;
      
      String myUid = AuthController.instance.user!.uid;
      if (data['white'] == myUid) myColor.value = 'w';
      else if (data['black'] == myUid) myColor.value = 'b';

      String serverFen = data['fen'];
      List<dynamic> serverMoves = data['moves'] ?? [];
      String? winner = data['winner'];
      
      if (data['lastMove'] != null) {
        lastMoveConfig = data['lastMove'];
      }
      
      List<String> formattedMoves = [];
      for (var move in serverMoves) formattedMoves.add(move.toString());
      moveHistorySan.assignAll(formattedMoves);

      gameMode.value = data['mode'] ?? 'classical';
      if (data['dice'] != null) currentDice.assignAll(List<int>.from(data['dice']));
      else currentDice.clear();

      bool isFirstLoad = fenHistory.length == 1 && fenHistory.first == game.fen;

      if (game.fen != serverFen || isFirstLoad) {
        game.loadFen(serverFen);
        
        if (fenHistory.isEmpty || fenHistory.last != serverFen) {
           fenHistory.add(serverFen);
           currentMoveIndex.value = fenHistory.length - 1;
        }
        displayFen.value = serverFen;
        
        enableAnimation = true;
        _updateUi();
      }

      bool isWhiteTurn = game.turn == 0; 
      isMyTurn.value = (isWhiteTurn && myColor.value == 'w') ||
                       (!isWhiteTurn && myColor.value == 'b');

      if (isMyTurn.value && gameMode.value == 'dice') {
        _checkDiceLegalMoves();
      } else {
        canMakeAnyMove.value = true;
      }

      if (!isGameEnded.value) {
        if (winner != null) {
           _handleGameOver(winner);
        } else if (game.gameOver) {
           if (game.winner == 0) _handleGameOver('w');
           else if (game.winner == 1) _handleGameOver('b');
           else _handleGameOver('draw');
        }
      }
    });
  }
}