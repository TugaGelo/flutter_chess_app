import 'package:get/get.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../controllers/sound_controller.dart'; 

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
    
    fenHistory.add(chess_lib.Chess.DEFAULT_POSITION);
    displayFen.value = chess_lib.Chess.DEFAULT_POSITION;

    List<dynamic> rawMoves = gameData['moves'] ?? [];
        
    for (var moveObj in rawMoves) {
       String cleanMove = moveObj.toString();
       if (cleanMove.contains(':')) {
         cleanMove = cleanMove.split(':')[1];
       }

       _addToMoveHistory(cleanMove);

       if (cleanMove == 'Pass') {
          String currentFen = _chess.fen;
          List<String> parts = currentFen.split(' ');
          parts[1] = parts[1] == 'w' ? 'b' : 'w'; 
          parts[3] = '-'; 
          if (parts[1] == 'w') {
             try { parts[5] = (int.parse(parts[5]) + 1).toString(); } catch(e) {}
          }
          String newFen = parts.join(' ');
          _chess.load(newFen); 
          fenHistory.add(newFen);
       } else {
          try {
             _chess.move(cleanMove);
             fenHistory.add(_chess.fen);
          } catch (e) {
             print("Replay Error: Could not parse move $cleanMove");
          }
       }
    }
    
    jumpToStart();
  }

  void _addToMoveHistory(String cleanMove) {
    String fancyMove = cleanMove;
    bool isWhite = (moveHistorySan.length % 2 == 0);

    if (isWhite) {
      fancyMove = fancyMove.replaceAll('K', '♔').replaceAll('Q', '♕').replaceAll('R', '♖').replaceAll('B', '♗').replaceAll('N', '♘');
    } else {
      fancyMove = fancyMove.replaceAll('K', '♚').replaceAll('Q', '♛').replaceAll('R', '♜').replaceAll('B', '♝').replaceAll('N', '♞');
    }
    moveHistorySan.add(fancyMove);
  }
  
  void jumpToLatest() {
    if (fenHistory.isEmpty) return;
    SoundController.instance.playClick(); 
    currentMoveIndex.value = fenHistory.length - 1;
    displayFen.value = fenHistory.last;
  }

  void goToPrevious() {
    if (currentMoveIndex.value > 0) {
      currentMoveIndex.value--;
      displayFen.value = fenHistory[currentMoveIndex.value];
      SoundController.instance.playMove();
    }
  }

  void goToNext() {
    if (currentMoveIndex.value < fenHistory.length - 1) {
      currentMoveIndex.value++;
      String currentFen = fenHistory[currentMoveIndex.value];
      displayFen.value = currentFen;
      
      final tempBoard = chess_lib.Chess();
      tempBoard.load(currentFen);
      
      if (tempBoard.in_checkmate || tempBoard.in_stalemate || tempBoard.in_draw) {
         SoundController.instance.playGameEnd();
      } 
      else {
         int moveListIndex = currentMoveIndex.value - 1;
         if (moveListIndex >= 0 && moveListIndex < moveHistorySan.length) {
             String moveSan = moveHistorySan[moveListIndex];
             
             if (moveSan.contains('+')) {
                SoundController.instance.playCheck();
             } else if (moveSan.contains('x')) {
                SoundController.instance.playCapture();
             } else {
                SoundController.instance.playMove();
             }
         } else {
             SoundController.instance.playMove();
         }
      }
    }
  }

  void jumpToStart() {
    if (fenHistory.isNotEmpty) {
      SoundController.instance.playClick(); 
      currentMoveIndex.value = 0;
      displayFen.value = fenHistory[0];
    }
  }

  void jumpToMove(int index) {
    int target = index + 1;
    if (target < fenHistory.length) {
      SoundController.instance.playClick(); 
      currentMoveIndex.value = target;
      displayFen.value = fenHistory[target];
    }
  }
}
