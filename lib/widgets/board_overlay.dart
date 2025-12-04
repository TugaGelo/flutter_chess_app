import 'package:flutter/material.dart';

class BoardOverlay extends StatelessWidget {
  final bool isBlackAtBottom;

  const BoardOverlay({super.key, required this.isBlackAtBottom});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
        itemCount: 64,
        itemBuilder: (context, index) {
          int row = index ~/ 8;
          int col = index % 8;

          String rankText = "";
          String fileText = "";
          
          if (col == 0) {
             int rankNum = isBlackAtBottom ? (row + 1) : (8 - row);
             rankText = rankNum.toString();
          }

          if (row == 7) {
             int charCode = isBlackAtBottom ? ('h'.codeUnitAt(0) - col) : ('a'.codeUnitAt(0) + col);
             fileText = String.fromCharCode(charCode);
          }

          bool isLightSquare = (row + col) % 2 == 0;
          Color textColor = isLightSquare 
              ? const Color(0xFFB58863)
              : const Color(0xFFF0D9B5);

          return Stack(
            children: [
              if (rankText.isNotEmpty)
                Positioned(
                  top: 2,
                  left: 2,
                  child: Text(
                    rankText,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
              if (fileText.isNotEmpty)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Text(
                    fileText,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
