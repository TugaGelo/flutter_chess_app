import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class HistoryController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  RxList<DocumentSnapshot> allGames = <DocumentSnapshot>[].obs;
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _bindHistoryStream();
  }

  void _bindHistoryStream() {
    _db.collection('games')
       .orderBy('date', descending: true)
       .snapshots()
       .listen((snapshot) {
         allGames.assignAll(snapshot.docs);
         isLoading.value = false;
    });
  }
  
  Future<void> deleteGame(String gameId) async {
    await _db.collection('games').doc(gameId).delete();
  }
  
  String getResultText(Map<String, dynamic> gameData) {
    String myUid = AuthController.instance.user!.uid;
    String winner = gameData['winner'] ?? '';
    
    if (winner.isEmpty) return "In Progress";
    if (winner == 'draw') return "Draw";
    
    bool isMeWhite = gameData['white'] == myUid;
    bool isMeBlack = gameData['black'] == myUid;

    if (isMeWhite || isMeBlack) {
      if (winner == 'w' && isMeWhite) return "You Won";
      if (winner == 'b' && isMeBlack) return "You Won";
      return "You Lost";
    } else {
      if (winner == 'w') return "White Won";
      if (winner == 'b') return "Black Won";
    }
    
    return "Finished";
  }
}
