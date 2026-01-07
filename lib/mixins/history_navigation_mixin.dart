import 'package:get/get.dart';

mixin HistoryNavigationMixin on GetxController {
  RxList<String> get fenHistory;
  RxInt get currentMoveIndex;
  RxString get displayFen;

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
