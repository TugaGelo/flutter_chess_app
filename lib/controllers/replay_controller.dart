import 'package:get/get.dart';
import 'package:chess/chess.dart' as chess_lib;

class ReplayController extends GetxController {
  RxString displayFen = ''.obs;
  RxList<String> fenHistory = <String>[].obs;
  RxList<String> moveHistorySan = <String>[].obs;
  RxInt currentMoveIndex = (-1).obs;
  
  RxString whiteName = ''.obs;
  RxString blackName = ''.obs;
  RxString resultText = ''.obs;

  final chess_lib.Chess _chess = chess_lib.Chess();

  void loadGame(Map<String, dynamic> gameData) {
    _chess.reset();
    fenHistory.clear();
    moveHistorySan.clear();
    currentMoveIndex.value = -1;

    whiteName.value = gameData['whiteName'] ?? "Unknown";
    blackName.value = gameData['blackName'] ?? "Unknown";
    
    String pgn = gameData['pgn'] ?? '';
    
    fenHistory.add(chess_lib.Chess.DEFAULT_POSITION);
    displayFen.value = chess_lib.Chess.DEFAULT_POSITION;

    if (pgn.isNotEmpty) {
      _chess.load_pgn(pgn);
      
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

      final replayChess = chess_lib.Chess();
      for (var move in cleanMoves) {
        replayChess.move(move);
        fenHistory.add(replayChess.fen);
      }
    }
    
    jumpToStart();
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