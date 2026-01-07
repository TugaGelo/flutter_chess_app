import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'chess_utils.dart';

class ChessRuleEngine {
  
  static String? findKingSquare(chess_lib.Chess chess, chess_lib.Color color) {
    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    final ranks = ['1', '2', '3', '4', '5', '6', '7', '8'];
    
    for (var file in files) {
      for (var rank in ranks) {
        String square = '$file$rank';
        final piece = chess.get(square);
        if (piece != null && piece.type == chess_lib.PieceType.KING && piece.color == color) {
          return square;
        }
      }
    }
    return null;
  }

  static bool canMakeAnyDiceMove(chess_lib.Chess chess, List<int> dice) {
    final tempGame = chess_lib.Chess();
    tempGame.load(chess.fen);
    
    List<dynamic> allMoves = tempGame.moves({'asObjects': true});
    
    for (var move in allMoves) {
      chess_lib.PieceType type;
      if (move is Map) type = move['piece']; 
      else type = move.piece; 
      
      int diceValue = ChessUtils.getPieceDiceValue(type);
      if (dice.contains(diceValue)) {
        return true; 
      }
    }
    return false;
  }

  static bool isMoveLegalForDice(chess_lib.Chess chess, String square, List<int> dice) {
    final piece = chess.get(square);
    if (piece == null) return false;
    
    int val = ChessUtils.getPieceDiceValue(piece.type);
    return dice.contains(val);
  }

  static Map<String, Color> getHighlights({
    required chess_lib.Chess chess, 
    required String square, 
    required bool isDiceMode,
    required List<int> currentDice
  }) {
    final newHighlights = <String, Color>{};

    if (isDiceMode) {
       if (!isMoveLegalForDice(chess, square, currentDice)) {
          return {};
       }
    }

    final moves = chess.moves({'square': square, 'verbose': true});
    
    if (chess.in_check) {
      String? kingSquare = findKingSquare(chess, chess.turn);
      if (kingSquare != null) {
        newHighlights[kingSquare] = Colors.red.withOpacity(0.6);
      }
    }

    newHighlights[square] = const Color(0xFF64B5F6).withOpacity(0.6); 

    for (var move in moves) {
      String targetSquare = move['to']; 
      newHighlights[targetSquare] = const Color(0xFF81C784).withOpacity(0.6); 
    }

    return newHighlights;
  }

  static bool isPromotion(chess_lib.Chess chess, String from, String to) {
    final piece = chess.get(from);
    if (piece == null || piece.type != chess_lib.PieceType.PAWN) return false;
    if (piece.color == chess_lib.Color.WHITE && to.endsWith('8')) return true;
    if (piece.color == chess_lib.Color.BLACK && to.endsWith('1')) return true;
    return false;
  }
}
