import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/game_controller.dart';

class MatchmakingController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  RxBool isSearching = false.obs;

  Future<void> startMatchmaking() async {
    isSearching.value = true;
    String myUid = AuthController.instance.user!.uid;

    try {
      var snapshot = await _db.collection('matchmaking')
          .where('status', isEqualTo: 'waiting')
          .where('createdBy', isNotEqualTo: myUid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var gameDoc = snapshot.docs.first;
        String gameId = gameDoc.id;

        print("Found game! Joining $gameId");

        await _db.collection('matchmaking').doc(gameId).update({
          'status': 'playing',
          'black': myUid,
          'blackName': AuthController.instance.user!.email,
        });

        await _createGameRecord(gameId, gameDoc['white'], myUid);

        GameController.instance.setGame(gameId, 'black');
        _goToGameScreen();

      } else {
        print("No games found. Creating a new room...");
        
        DocumentReference docRef = await _db.collection('matchmaking').add({
          'createdBy': myUid,
          'white': myUid,
          'whiteName': AuthController.instance.user!.email,
          'black': '',
          'blackName': '',
          'status': 'waiting',
          'createdAt': FieldValue.serverTimestamp(),
        });

        _waitForOpponent(docRef.id);
      }

    } catch (e) {
      print("Error in matchmaking: $e");
      Get.snackbar("Error", "Matchmaking failed");
      isSearching.value = false;
    }
  }

  void _waitForOpponent(String docId) {
    _db.collection('matchmaking').doc(docId).snapshots().listen((snapshot) {
      if (!snapshot.exists) return;

      var data = snapshot.data() as Map<String, dynamic>;
      
      if (data['status'] == 'playing') {
        print("Player joined! Starting game...");
        GameController.instance.setGame(docId, 'white');
        _goToGameScreen();
      }
    });
  }

  Future<void> _createGameRecord(String gameId, String whiteId, String blackId) async {
    await _db.collection('games').doc(gameId).set({
      'white': whiteId,
      'black': blackId,
      'pgn': '',
      'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      'lastMove': null,
    });
  }

  void _goToGameScreen() {
    isSearching.value = false;
    Get.snackbar("Success", "Game Started! You are ${GameController.instance.myColor.value}");
  }
}