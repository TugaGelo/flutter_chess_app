import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/game_controller.dart';
import '../views/game_view.dart';

class MatchmakingController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  RxBool isSearching = false.obs;

  Future<void> startMatchmaking() async {
    isSearching.value = true;
    String myUid = AuthController.instance.user!.uid;
    String myName = AuthController.instance.firestoreUser.value?.username ?? "Unknown";

    try {
      var snapshot = await _db.collection('matchmaking')
          .where('status', isEqualTo: 'waiting')
          .where('createdBy', isNotEqualTo: myUid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var gameDoc = snapshot.docs.first;
        String gameId = gameDoc.id;
        String whiteName = gameDoc['whiteName'] ?? "Opponent";

        print("Found game! Joining $gameId");

        await _db.collection('matchmaking').doc(gameId).update({
          'status': 'playing',
          'black': myUid,
          'blackName': myName,
        });

        await _createGameRecord(
            gameId, 
            gameDoc['white'], 
            myUid, 
            whiteName, 
            myName
        );

        GameController.instance.setGame(gameId, 'b');
        _goToGameScreen();

      } else {
        print("No games found. Creating a new room...");
        
        DocumentReference docRef = await _db.collection('matchmaking').add({
          'createdBy': myUid,
          'white': myUid,
          'whiteName': myName,
          'black': '',
          'blackName': '',
          'status': 'waiting',
          'createdAt': FieldValue.serverTimestamp(),
        });

        _waitForOpponent(docRef.id);
      }

    } catch (e) {
      print("Error in matchmaking: $e");
      isSearching.value = false;
    }
  }

  void _waitForOpponent(String docId) {
    _db.collection('matchmaking').doc(docId).snapshots().listen((snapshot) {
      if (!snapshot.exists) return;

      var data = snapshot.data() as Map<String, dynamic>;
      
      if (data['status'] == 'playing') {
        print("Player joined! Starting game...");
        GameController.instance.setGame(docId, 'w');
        _goToGameScreen();
      }
    });
  }

  Future<void> _createGameRecord(String gameId, String whiteId, String blackId, String whiteName, String blackName) async {
    await _db.collection('games').doc(gameId).set({
      'white': whiteId,
      'black': blackId,
      'whiteName': whiteName,
      'blackName': blackName,
      'pgn': '',
      'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      'lastMove': null,
      'date': FieldValue.serverTimestamp(),
    });
  }

  void _goToGameScreen() {
    isSearching.value = false;
    Get.to(() => const GameView());
  }
}
