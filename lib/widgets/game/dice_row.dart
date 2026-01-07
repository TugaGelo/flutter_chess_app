import 'package:flutter/material.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';
import '../../controllers/game_controller.dart';

class DiceRow extends StatelessWidget {
  final bool isActive;
  final List<int> diceValues;
  final bool isBottom;
  final bool isWhitePieces;
  final GameController controller;

  const DiceRow({
    super.key,
    required this.isActive,
    required this.diceValues,
    required this.isBottom,
    required this.isWhitePieces,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    const Color activeBorder = Color(0xFFB58863);
    const Color activeBg = Color(0xFFF0D9B5);
    const Color inactiveColor = Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < 3; i++)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: (isActive && i < diceValues.length) ? activeBg : Colors.grey[200],
                border: Border.all(
                  color: (isActive && i < diceValues.length) ? activeBorder : inactiveColor,
                  width: 2
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: (isActive && i < diceValues.length)
                    ? SizedBox(
                        width: 28,
                        height: 28,
                        child: _getPieceWidgetForDice(diceValues[i]),
                      )
                    : null,
              ),
            ),

          if (isBottom && isActive && !controller.canMakeAnyMove.value)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: ElevatedButton(
                onPressed: () => controller.passTurn(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeBorder,
                  foregroundColor: Colors.white
                ),
                child: const Text("PASS", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
        ],
      ),
    );
  }

  Widget _getPieceWidgetForDice(int val) {
    if (isWhitePieces) {
      switch(val) {
        case 1: return WhitePawn();
        case 2: return WhiteKnight();
        case 3: return WhiteBishop();
        case 4: return WhiteRook();
        case 5: return WhiteQueen();
        case 6: return WhiteKing();
        default: return const SizedBox();
      }
    } else {
      switch(val) {
        case 1: return BlackPawn();
        case 2: return BlackKnight();
        case 3: return BlackBishop();
        case 4: return BlackRook();
        case 5: return BlackQueen();
        case 6: return BlackKing();
        default: return const SizedBox();
      }
    }
  }
}
