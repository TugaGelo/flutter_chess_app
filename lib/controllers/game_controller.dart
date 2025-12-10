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
  
  Rxn<int> selectedSquare = Rxn<int>();
  RxList<int> validMoves = <int>[].obs;
  
  Map<String, dynamic>? lastMoveConfig; 

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

  void _initGame([String? fen]) {
    game = bishop.Game(variant: bishop.Variant.standard());
    if (fen != null) game.loadFen(fen);

    boardState = _createBoardState(game);
    
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
    boardState = _createBoardState(game);
    update();
  }

  void handleTap(int square) {
    if (currentMoveIndex.value != fenHistory.length - 1) return;
    if (!isMyTurn.value) return;

    if (selectedSquare.value == null) {
      String piece = boardState.board[square];
      if (piece.isEmpty) return;
      
      bool isWhitePiece = piece == piece.toUpperCase();
      if (myColor.value == 'w' && !isWhitePiece) return;
      if (myColor.value == 'b' && isWhitePiece) return;

      selectedSquare.value = square;
      
      String algFrom = _toAlgebraic(square);
      var moves = game.generateLegalMoves().where((m) {
        String mFrom = game.size.squareName(m.from);
        return mFrom == algFrom;
      });
      
      validMoves.value = moves.map((m) {
        String mTo = game.size.squareName(m.to);
        return _fromAlgebraic(mTo);
      }).toList();

      update(); 
    } else {
      if (selectedSquare.value == square) {
        selectedSquare.value = null;
        validMoves.clear();
        update();
      } else {
        onUserMove(squares.Move(from: selectedSquare.value!, to: square));
      }
    }
  }

  void onUserMove(squares.Move move) async {
    selectedSquare.value = null;
    validMoves.clear();
    update();

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
    
    lastMoveConfig = null; 
    boardState = _createBoardState(tempGame);
    update();
  }

  void nextMove() => jumpToMove(currentMoveIndex.value + 1);
  void prevMove() => jumpToMove(currentMoveIndex.value - 1);
  void jumpToLive() {
    currentMoveIndex.value = fenHistory.length - 1;
    _updateUi(); 
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

  Future<void> resignGame() async { 
    String winner = myColor.value == 'w' ? 'b' : 'w';
    await _db.collection('games').doc(gameId.value).update({'winner': winner});
  }
  
  Future<void> declareDraw() async {
    await _db.collection('games').doc(gameId.value).update({'winner': 'draw'});
  }
  
  void _handleGameOver(String winner) {
    isGameEnded.value = true;
    String text = winner == 'draw' ? "Game Drawn" : (winner == 'w' ? "White Won" : "Black Won");
    Get.defaultDialog(
      title: "Game Over",
      middleText: text,
      textConfirm: "Lobby",
      onConfirm: () => Get.offAll(() => const LobbyView()),
    );
  }

  void setGame(String id, String assignedColor) {
    gameId.value = id;
    myColor.value = assignedColor; 
    isGameEnded.value = false;
    lastMoveConfig = null;
    _updateUi(); 
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
