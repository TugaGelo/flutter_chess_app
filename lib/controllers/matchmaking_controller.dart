import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/game_controller.dart';
import '../views/game_view.dart';

class MatchmakingController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String defaultFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  RxBool isSearching = false.obs;

  Future<void> joinQueue(String mode) async {
    isSearching.value = true;
    String myUid = AuthController.instance.user!.uid;

    try {
      var snapshot = await _db.collection('games')
          .where('status', isEqualTo: 'waiting')
          .where('mode', isEqualTo: mode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        if (doc['white'] == myUid) {
           _startGame(doc.id, 'w');
           return;
        }
        await _db.collection('games').doc(doc.id).update({'black': myUid, 'status': 'playing'});
        _startGame(doc.id, 'b');
      } else {
        var ref = await _db.collection('games').add({
          'white': myUid, 'black': '', 'status': 'waiting', 'mode': mode,
          'fen': defaultFen, 'pgn': '', 'moves': [], 'dice': [1,2,3],
          'createdAt': FieldValue.serverTimestamp(),
        });
        _listenForOpponent(ref.id);
      }
    } catch (e) {
      isSearching.value = false;
      Get.snackbar("Error", "$e");
    }
  }

  void _listenForOpponent(String gameId) {
    _db.collection('games').doc(gameId).snapshots().listen((snap) {
      if (snap.exists && snap.data()!['status'] == 'playing') _startGame(gameId, 'w');
    });
  }

  void _startGame(String id, String color) {
    isSearching.value = false;
    if (!Get.isRegistered<GameController>()) Get.put(GameController());
    GameController.instance.setGame(id, color);
    Get.off(() => const GameView());
  }
}
