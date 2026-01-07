import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;

class ChessUtils {
  static int getPieceDiceValue(chess_lib.PieceType type) {
    switch (type) {
      case chess_lib.PieceType.PAWN: return 1;
      case chess_lib.PieceType.KNIGHT: return 2;
      case chess_lib.PieceType.BISHOP: return 3;
      case chess_lib.PieceType.ROOK: return 4;
      case chess_lib.PieceType.QUEEN: return 5;
      case chess_lib.PieceType.KING: return 6;
      default: return 0;
    }
  }

  static Widget getPieceWidget(String char) {
    switch (char) {
      case 'P': return WhitePawn();
      case 'N': return WhiteKnight();
      case 'B': return WhiteBishop();
      case 'R': return WhiteRook();
      case 'Q': return WhiteQueen();
      case 'K': return WhiteKing();
      case 'p': return BlackPawn();
      case 'n': return BlackKnight();
      case 'b': return BlackBishop();
      case 'r': return BlackRook();
      case 'q': return BlackQueen();
      case 'k': return BlackKing();
      default: return const SizedBox();
    }
  }

  static List<String> parseServerMoves(List<dynamic> serverMoves) {
    List<String> groupedMoves = [];
    String currentGroup = "";
    String lastColor = "";

    for (var moveObj in serverMoves) {
      String rawMove = moveObj.toString();
      String colorPrefix = "";
      String cleanMove = rawMove;

      if (rawMove.length > 2 && rawMove[1] == ':') {
        colorPrefix = rawMove.substring(0, 1);
        cleanMove = rawMove.substring(2);
      }

      if (colorPrefix == 'w') {
        cleanMove = cleanMove.replaceAll('K', '♔').
                              replaceAll('Q', '♕').
                              replaceAll('R', '♖').
                              replaceAll('B', '♗').
                              replaceAll('N', '♘');
      } else if (colorPrefix == 'b') {
        cleanMove = cleanMove.replaceAll('K', '♔').
                              replaceAll('Q', '♕').
                              replaceAll('R', '♜').
                              replaceAll('B', '♝').
                              replaceAll('N', '♞');
      }

      if (cleanMove == "Pass") {
        if (currentGroup.isNotEmpty) groupedMoves.add(currentGroup);
        groupedMoves.add("Pass");
        currentGroup = "";
        lastColor = colorPrefix == 'w' ? 'b' : 'w';
        continue;
      }

      if (colorPrefix == lastColor && colorPrefix.isNotEmpty) {
        if (currentGroup.isNotEmpty) currentGroup += ", ";
        currentGroup += cleanMove;
      } else {
        if (currentGroup.isNotEmpty) groupedMoves.add(currentGroup);
        currentGroup = cleanMove;
        lastColor = colorPrefix;
      }
    }
    if (currentGroup.isNotEmpty) groupedMoves.add(currentGroup);
    return groupedMoves;
  }
}
