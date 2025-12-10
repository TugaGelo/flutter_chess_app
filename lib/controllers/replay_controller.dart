import 'package:get/get.dart';
import 'package:bishop/bishop.dart' as bishop;
import 'package:squares/squares.dart' as squares;

class ReplayController extends GetxController {
  RxString whiteName = ''.obs;
  RxString blackName = ''.obs;
  RxString gameResult = ''.obs;
  
  RxList<String> moves = <String>[].obs;
  List<String> fenHistory = [];
  RxInt index = (-1).obs;

  late squares.BoardController boardController;
  late bishop.Game _game;

  @override
  void onInit() {
    super.onInit();
    _initGame();
  }

  void _initGame() {
    _game = bishop.Game(variant: bishop.Variant.standard());
    fenHistory = [_game.fen];
    _updateBoardState();
  }

  void loadGame(Map<String, dynamic> data) {
    whiteName.value = data['whiteName'] ?? 'White';
    blackName.value = data['blackName'] ?? 'Black';
    String pgn = data['pgn'] ?? '';

    moves.clear();
    index.value = -1;
    _game = bishop.Game(variant: bishop.Variant.standard());
    fenHistory = [_game.fen];

    if (pgn.isNotEmpty) {
      try {
        final fullGame = bishop.gameFromPgn(pgn);
        final replayGame = bishop.Game(variant: bishop.Variant.standard());
        
        for (var historyItem in fullGame.history) {
          var pgnMove = historyItem.move;
          
          var legalMoves = replayGame.generateLegalMoves();
          try {
            var matchingMove = legalMoves.firstWhere((m) => 
              m.from == pgnMove?.from && m.to == pgnMove?.to
            );
            
            String moveString = replayGame.toSan(matchingMove);
            
            replayGame.makeMove(matchingMove);
            fenHistory.add(replayGame.fen);
            moves.add(moveString);
            
          } catch (e) {
            print("Skipping invalid move in replay");
          }
        }
      } catch (e) {
        print("PGN Error: $e");
      }
    }
    
    _updateBoardState();
  }

  void _updateBoardState() {
    int dataIndex = index.value + 1;
    if (dataIndex < 0 || dataIndex >= fenHistory.length) dataIndex = 0;
    
    String currentFen = fenHistory[dataIndex];

    boardController = squares.BoardController(
      state: _createBoardState(currentFen),
      playState: squares.PlayState.finished,
      pieceSet: squares.PieceSet.merida(),
      theme: squares.BoardTheme.brown,
      onMove: (_) {},
    );
    update();
  }

  squares.BoardState _createBoardState(String fen) {
    String fenBoard = fen.split(' ')[0];
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

    return squares.BoardState(board: boardList);
  }

  void next() { 
    if (index.value < moves.length - 1) { 
      index++; 
      _updateBoardState(); 
    } 
  }
  
  void prev() { 
    if (index.value > -1) { 
      index--; 
      _updateBoardState(); 
    } 
  }
  
  void jumpToStart() { index.value = -1; _updateBoardState(); }
  void jumpToLatest() { index.value = moves.length - 1; _updateBoardState(); }
  void goToPrevious() => prev();
  void goToNext() => next();
  void jumpToMove(int i) { index.value = i; _updateBoardState(); }
}
