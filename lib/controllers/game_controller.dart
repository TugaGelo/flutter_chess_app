import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../controllers/auth_controller.dart';

class GameController extends GetxController {
  static GameController instance = Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  RxString gameId = ''.obs;
  RxString myColor = ''.obs;
  RxString fen = ''.obs; 
  RxBool isMyTurn = false.obs;
  RxString gameOverMessage = ''.obs;
  
  final chess_lib.Chess _chess = chess_lib.Chess();

  void setGame(String id, String colorId) {
    gameId.value = id;
    myColor.value = (colorId == AuthController.instance.user!.uid) ? 'w' : 'b';
    print("Game initialized! ID: $id, Color: ${myColor.value}");
    _connectToGameStream();
  }

  void _connectToGameStream() {
    _db.collection('games').doc(gameId.value).snapshots().listen((snapshot) {
      if (!snapshot.exists) return;

      var data = snapshot.data() as Map<String, dynamic>;
      String serverFen = data['fen'];
      
      _chess.load(serverFen);
      
      fen.value = serverFen;
      
      isMyTurn.value = (_chess.turn == chess_lib.Color.WHITE && myColor.value == 'w') ||
                       (_chess.turn == chess_lib.Color.BLACK && myColor.value == 'b');

      if (_chess.in_checkmate) {
        gameOverMessage.value = isMyTurn.value ? "You Lost!" : "You Won!";
      } else if (_chess.in_draw) {
        gameOverMessage.value = "Draw!";
      }
    });
  }

  Future<void> makeMove({required String from, required String to, String? promotion}) async {
    if (!isMyTurn.value) {
      print("Not my turn!"); 
      return;
    }

    try {
      final moveMap = {'from': from, 'to': to};
      if (promotion != null) {
        moveMap['promotion'] = promotion;
      }

      bool success = _chess.move(moveMap);
      
      if (success) {
        await _db.collection('games').doc(gameId.value).update({
          'fen': _chess.fen,
          'pgn': _chess.pgn(),
          'lastMove': {'from': from, 'to': to, 'promotion': promotion, 'by': myColor.value}
        });
        print("Move sent: $from -> $to");
      } else {
        print("Move rejected by local engine");
        fen.refresh(); 
      }
    } catch (e) {
      print("Move Error: $e");
      fen.refresh();
    }
  }
}
