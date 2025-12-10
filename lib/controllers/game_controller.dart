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
  
  late bishop.Game game;
  late squares.BoardController boardController;
  Rxn<int> selectedSquare = Rxn<int>();

  List<String> fenHistory = [];
  RxString displayFen = ''.obs; 
  RxList<String> moveHistorySan = <String>[].obs; 
  RxInt currentMoveIndex = (-1).obs;

  @override
  void onInit() {
    super.onInit();
    _initGame();
  }

  void _initGame([String? fen]) {
    game = bishop.Game(variant: bishop.Variant.standard());
    if (fen != null) game.loadFen(fen);

    boardController = squares.BoardController(
      state: _createBoardState(game),
      playState: _createPlayState(game),
      pieceSet: squares.PieceSet.merida(),
      theme: squares.BoardTheme.brown,
      moves: [],
    );
    
    fenHistory = [game.fen];
    displayFen.value = game.fen;
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
    
    if (game.history.isNotEmpty) {
      var m = game.history.last.move;
      from = m?.from;
      to = m?.to;
    }

    return squares.BoardState(
      board: boardList, 
      lastFrom: from,
      lastTo: to,
      orientation: myColor.value == 'b' ? 1 : 0,
    );
  }

  squares.PlayState _createPlayState(bishop.Game game) {
    if (game.gameOver) return squares.PlayState.finished;
    if (isMyTurn.value) return squares.PlayState.ourTurn;
    return squares.PlayState.theirTurn;
  }

  void _updateUi() {
    selectedSquare.value = null;
    boardController = squares.BoardController(
      state: _createBoardState(game),
      playState: _createPlayState(game),
      pieceSet: squares.PieceSet.merida(),
      theme: squares.BoardTheme.brown,
    );
    update();
  }


  void handleTap(int square) {
    if (!isMyTurn.value) return;

    if (selectedSquare.value == null) {
      if (boardController.state.board[square].isNotEmpty) {
        selectedSquare.value = square;
        update();
      }
    } else {
      // Move
      if (selectedSquare.value == square) {
        selectedSquare.value = null;
        update();
      } else {
        _attemptMove(selectedSquare.value!, square);
      }
    }
  }

  void onDrop(squares.Move move) {
    if (!isMyTurn.value) return;
    _attemptMove(move.from, move.to);
  }

  void _attemptMove(int from, int to) async {
    String pStr = boardController.state.board[from];
    int pType = _charToPieceType(pStr);
    
    if (gameMode.value == 'dice') {
      if (!currentDice.contains(pType)) {
        Get.snackbar("Dice Block", "You rolled ${currentDice.join(',')}. Need $pType.");
        _updateUi();
        return;
      }
    }

    bool isPromo = (pType == 1) && (to < 8 || to > 55);
    
    int? promoPiece;
    if (isPromo) {
      String? char = await _showPromotionDialog();
      if (char == null) { _updateUi(); return; }
      promoPiece = _charToBishopPromo(char);
    }

    var moves = game.generateLegalMoves();
    bishop.Move? validMove;
    
    try {
      if (promoPiece != null) {
        validMove = moves.firstWhere((m) => m.from == from && m.to == to && m.promotion == promoPiece);
      } else {
        validMove = moves.firstWhere((m) => m.from == from && m.to == to);
      }
    } catch (e) {
      _updateUi();
      return;
    }

    String san = game.toSan(validMove);
    game.makeMove(validMove);
    _updateUi();
    _submitToServer(validMove, san);
  }


  int _charToPieceType(String char) {
    switch(char.toLowerCase()) {
      case 'p': return 1;
      case 'n': return 2;
      case 'b': return 3;
      case 'r': return 4;
      case 'q': return 5;
      case 'k': return 6;
      default: return 0;
    }
  }

  int _charToBishopPromo(String char) {
    switch(char) {
      case 'n': return 2;
      case 'b': return 3;
      case 'r': return 4;
      case 'q': return 5;
      default: return 5;
    }
  }

  Future<String?> _showPromotionDialog() async {
    return await Get.dialog<String>(
      SimpleDialog(
        title: const Text("Promote"),
        children: [
          _promoOption("Queen", "q"),
          _promoOption("Rook", "r"),
          _promoOption("Bishop", "b"),
          _promoOption("Knight", "n"),
        ],
      )
    );
  }

  Widget _promoOption(String label, String char) {
    return ListTile(
      title: Text(label),
      onTap: () => Get.back(result: char),
    );
  }

  void setGame(String id, String color) {
    gameId.value = id;
    myColor.value = color;
    _connectToGameStream();
  }

  void _connectToGameStream() {
    _db.collection('games').doc(gameId.value).snapshots().listen((snap) {
      if (!snap.exists) return;
      var data = snap.data()!;
      
      gameMode.value = data['mode'] ?? 'classical';
      if (data['dice'] != null) currentDice.assignAll(List<int>.from(data['dice']));

      String sFen = data['fen'];
      if (sFen != game.fen) {
        game.loadFen(sFen);
        _updateUi();
        fenHistory.add(sFen);
        displayFen.value = sFen;
        currentMoveIndex.value = fenHistory.length - 1;
      }

      bool whiteTurn = game.turn == 0;
      isMyTurn.value = (whiteTurn && myColor.value == 'w') || (!whiteTurn && myColor.value == 'b');
      
      List<dynamic> moves = data['moves'] ?? [];
      moveHistorySan.assignAll(moves.map((e) => e.toString()).toList());
    });
  }

  void _submitToServer(bishop.Move move, String san) {
    List<int> nextDice = gameMode.value == 'dice' 
        ? [Random().nextInt(6)+1, Random().nextInt(6)+1, Random().nextInt(6)+1] 
        : [];
    
    _db.collection('games').doc(gameId.value).update({
      'fen': game.fen,
      'pgn': game.pgn,
      'moves': FieldValue.arrayUnion([san]),
      'dice': nextDice
    });
  }
  
  void resignGame() {}
  void declareDraw() {}
}
