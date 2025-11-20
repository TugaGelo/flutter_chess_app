import 'package:get/get.dart';

class GameController extends GetxController {
  static GameController instance = Get.find();

  RxString currentGameId = ''.obs;
  RxString myColor = ''.obs;
  RxBool isMyTurn = false.obs;
  
  void setGame(String id, String color) {
    currentGameId.value = id;
    myColor.value = color;
    print("Game Set! ID: $id, Color: $color");
  }
}