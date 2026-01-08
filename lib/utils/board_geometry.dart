class BoardGeometry {
  static List<int> getSquareIndices(String square, bool isBlackAtBottom) {
    final fileChar = square[0];
    final rankChar = square[1];

    int fileIndex = fileChar.codeUnitAt(0) - 'a'.codeUnitAt(0);
    int rankIndex = int.parse(rankChar) - 1;
    int visualRow = isBlackAtBottom ? rankIndex : (7 - rankIndex);
    int visualCol = isBlackAtBottom ? (7 - fileIndex) : fileIndex;

    return [visualRow, visualCol];
  }
}
