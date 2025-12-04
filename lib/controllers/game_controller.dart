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

  RxString displayFen = ''.obs; 
  RxList<String> fenHistory = <String>[].obs; 
  RxList<String> moveHistorySan = <String>[].obs;
  RxInt currentMoveIndex = (-1).obs;

  final chess_lib.Chess _chess = chess_lib.Chess();

  void setGame(String id, String assignedColor) {
    gameId.value = id;
    myColor.value = assignedColor;
    
    print("Game initialized! ID: $id, I am playing as: ${myColor.value}");
    _connectToGameStream();
  }

  void _connectToGameStream() {
    _db.collection('games').doc(gameId.value).snapshots().listen((snapshot) {
      if (!snapshot.exists) return;

      var data = snapshot.data() as Map<String, dynamic>;
      String serverFen = data['fen'];
      String serverPgn = data['pgn'] ?? ''; 
      
      if (serverPgn.isNotEmpty) {
        _chess.load_pgn(serverPgn);
      } else {
        _chess.load(serverFen);
      }
      
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
    });
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

  void jumpToMove(int listIndex) {
    int targetFenIndex = listIndex + 1;
    
    if (targetFenIndex < fenHistory.length) {
      currentMoveIndex.value = targetFenIndex;
      displayFen.value = fenHistory[targetFenIndex];
    }
  }

  Future<void> makeMove({required String from, required String to, String? promotion}) async {
    if (currentMoveIndex.value != fenHistory.length - 1) {
      print("Jump to latest move to play");
      return;
    }
    
    if (!isMyTurn.value) return;

    try {
      final moveMap = {'from': from, 'to': to};
      if (promotion != null) moveMap['promotion'] = promotion;

      bool success = _chess.move(moveMap);
      
      if (success) {
        await _db.collection('games').doc(gameId.value).update({
          'fen': _chess.fen,
          'pgn': _chess.pgn(),
          'lastMove': {'from': from, 'to': to, 'promotion': promotion, 'by': myColor.value}
        });
      } else {
        displayFen.refresh(); 
      }
    } catch (e) {
      print("Move error: $e");
      displayFen.refresh();
    }
  }
}
