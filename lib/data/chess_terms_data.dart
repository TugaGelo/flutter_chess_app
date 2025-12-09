import '../models/chess_term.dart';

final List<ChessTerm> chessTerms = [
  // ===========================================================================
  // ⚔️ TACTICS & ATTACKS
  // ===========================================================================
  ChessTerm(
    title: "The Pin",
    description: "A piece cannot move because it would expose a more valuable piece (usually the King or Queen) behind it.",
    fen: "r1b1kbnr/pppp1ppp/2n5/4p3/4P2q/2N5/PPPP1PPP/R1BQKBNR w KQkq - 0 1",
  ),
  ChessTerm(
    title: "The Fork",
    description: "A tactic where a single piece attacks two or more of the opponent's pieces at the same time.",
    fen: "rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2",
  ),
  ChessTerm(
    title: "The Skewer",
    description: "Similar to a pin, but the more valuable piece is in front. It must move, exposing the weaker piece behind it.",
    fen: "8/8/8/3q4/8/8/3R4/3K4 w - - 0 1",
  ),
  ChessTerm(
    title: "Discovered Attack",
    description: "Moving a piece to reveal an attack from a piece standing behind it.",
    fen: "rnbqkbnr/ppp2ppp/8/3pp3/3P4/5N2/PPP1PPPP/RNBQKB1R w KQkq - 0 3",
  ),
  ChessTerm(
    title: "Double Check",
    description: "A check delivered by two pieces simultaneously. The King MUST move; the pieces cannot be blocked or captured.",
    fen: "rnb1kbnr/ppp2ppp/8/3pp3/3P4/5N2/PPP1PPP1/RNBQKB1q w Qkq - 0 1", 
  ),
  ChessTerm(
    title: "Zwischenzug",
    description: "German for 'Intermediate Move'. Inserting a surprising check or threat before playing the expected move.",
    fen: "r1bqk2r/pppp1ppp/2n2n2/4p3/1bB1P3/2N2N2/PPPP1PPP/R1BQK2R w KQkq - 0 1",
  ),
  ChessTerm(
    title: "X-Ray Attack",
    description: "A piece attacks a square or piece through another piece.",
    fen: "3r4/8/8/8/8/8/3R4/3K4 w - - 0 1",
  ),
  ChessTerm(
    title: "Overloading",
    description: "A defensive piece is tasked with protecting too many squares or pieces at once.",
    fen: "6k1/5ppp/8/8/8/2r5/1R6/6K1 w - - 0 1",
  ),
  ChessTerm(
    title: "Deflection",
    description: "Forcing an enemy piece to leave a square where it is performing a vital defensive task.",
    fen: "rnbqkbnr/pppp1ppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1",
  ),
  ChessTerm(
    title: "Decoy",
    description: "Luring an enemy piece (often the King) to a square where it will be vulnerable.",
    fen: "rnbqkbnr/pppp1ppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1",
  ),
  ChessTerm(
    title: "Windmill",
    description: "A devastating series of discovered checks and captures, usually involving a Rook and Bishop.",
    fen: "6k1/5ppp/8/8/8/8/1B6/R5K1 w - - 0 1", // Famous Torre vs Lasker pattern
  ),

  // ===========================================================================
  // 💀 CHECKMATES
  // ===========================================================================
  ChessTerm(
    title: "Back Rank Mate",
    description: "The King is trapped behind its own pawns and gets checkmated by a Rook or Queen on the back rank.",
    fen: "6k1/5ppp/8/8/8/8/8/3R2K1 w - - 0 1",
  ),
  ChessTerm(
    title: "Smothered Mate",
    description: "The King is surrounded by its own pieces and cannot escape a Knight's check.",
    fen: "6rk/5Npp/8/8/8/8/8/7K w - - 0 1",
  ),
  ChessTerm(
    title: "Scholar's Mate",
    description: "A quick 4-move checkmate that targets the weak f7 pawn using the Queen and Bishop.",
    fen: "r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 4 4",
  ),
  ChessTerm(
    title: "Fool's Mate",
    description: "The fastest possible checkmate in chess (2 moves), capitalizing on White opening the g-file and h-file.",
    fen: "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3",
  ),
  ChessTerm(
    title: "Anastasia's Mate",
    description: "A mate involving a Knight and Rook, where the Knight traps the King against the side of the board.",
    fen: "5r1k/5P1p/8/8/8/8/8/3R3K w - - 0 1",
  ),
  ChessTerm(
    title: "Arabian Mate",
    description: "A checkmate pattern using a Rook and Knight, often on h7 or g8.",
    fen: "7k/7p/8/6N1/8/8/8/6RK w - - 0 1",
  ),
  ChessTerm(
    title: "Boden's Mate",
    description: "Two Bishops on criss-crossing diagonals deliver checkmate.",
    fen: "2kr4/8/8/8/8/2B5/8/3B4 w - - 0 1",
  ),
  ChessTerm(
    title: "Opera Mate",
    description: "Named after Morphy's Opera Game. A Rook mates on the back rank, protected by a Bishop.",
    fen: "4k3/4p3/8/8/8/8/3B4/3R4 w - - 0 1",
  ),
  ChessTerm(
    title: "Hook Mate",
    description: "A mate involving a Rook, Knight, and Pawn working together to trap the King.",
    fen: "8/8/8/8/4N3/8/5P2/3R2K1 w - - 0 1",
  ),

  // ===========================================================================
  // 🧠 CONCEPTS & RULES
  // ===========================================================================
  ChessTerm(
    title: "Zugzwang",
    description: "German for 'Compulsion to move'. A situation where ANY move a player makes weakens their position.",
    fen: "8/8/8/8/8/3k4/3p4/3K4 b - - 0 1",
  ),
  ChessTerm(
    title: "Stalemate",
    description: "The player whose turn it is has no legal moves but is NOT in check. The game ends in a Draw.",
    fen: "8/8/8/8/8/2k5/2p5/2K5 w - - 0 1",
  ),
  ChessTerm(
    title: "En Passant",
    description: "A special pawn capture. If a pawn moves two squares forward, an adjacent pawn can capture it as if it only moved one.",
    fen: "rnbqkbnr/pp1ppppp/8/2pP4/8/8/PPP1PPPP/RNBQKBNR w KQkq c6 0 3",
  ),
  ChessTerm(
    title: "Castling",
    description: "A special move to protect the King and develop the Rook. The King moves two squares, and the Rook hops over.",
    fen: "r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/2N2N2/PPPP1PPP/R1BQ1RK1 b kq - 0 1",
  ),
  ChessTerm(
    title: "Fianchetto",
    description: "Developing a Bishop to the long diagonal (b2/g2 or b7/g7) to control the center from a distance.",
    fen: "rn1qkbnr/pbpppppp/1p6/8/8/1P6/PBPPPPPP/RN1QKBNR w KQkq - 2 3",
  ),
  ChessTerm(
    title: "Gambit",
    description: "Sacrificing material (usually a pawn) in the opening to gain an advantage in development or position.",
    fen: "rnbqkbnr/ppp1pppp/8/3p4/2PP4/8/PP2PPPP/RNBQKBNR b KQkq c3 0 2",
  ),
  ChessTerm(
    title: "The Outpost",
    description: "A square protected by a pawn that cannot be attacked by an enemy pawn. Ideal for Knights.",
    fen: "8/8/3p4/4N3/3P4/8/8/8 w - - 0 1",
  ),
  ChessTerm(
    title: "Isolated Pawn",
    description: "A pawn that has no friendly pawns on the adjacent files. It can be a weakness or an attacking asset.",
    fen: "8/8/8/3P4/8/8/8/8 w - - 0 1",
  ),
  ChessTerm(
    title: "Passed Pawn",
    description: "A pawn with no opposing pawns to stop it from advancing to the 8th rank to promote.",
    fen: "8/4P3/8/8/8/8/8/8 w - - 0 1",
  ),
  ChessTerm(
    title: "Promotion",
    description: "When a pawn reaches the furthest rank, it must be exchanged for a Queen, Rook, Bishop, or Knight.",
    fen: "8/4P3/8/8/8/8/8/8 w - - 0 1",
  ),

  // ===========================================================================
  // 📖 OPENINGS (White)
  // ===========================================================================
  ChessTerm(
    title: "Ruy Lopez",
    description: "One of the oldest and most popular openings (1. e4 e5 2. Nf3 Nc6 3. Bb5).",
    fen: "r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 3 3",
  ),
  ChessTerm(
    title: "Italian Game",
    description: "A classic opening (1. e4 e5 2. Nf3 Nc6 3. Bc4), focusing on rapid development and control of the center.",
    fen: "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 3 3",
  ),
  ChessTerm(
    title: "Queen's Gambit",
    description: "White sacrifices a pawn (1. d4 d5 2. c4) to gain control of the center.",
    fen: "rnbqkbnr/ppp1pppp/8/3p4/2PP4/8/PP2PPPP/RNBQKBNR b KQkq c3 0 2",
  ),
  ChessTerm(
    title: "London System",
    description: "A solid, systemic opening for White where the dark-squared Bishop is developed to f4 early.",
    fen: "rnbqkbnr/ppp1pppp/8/3p4/3P1B2/8/PPP1PPPP/RN1QKBNR b KQkq - 1 2",
  ),
  ChessTerm(
    title: "King's Gambit",
    description: "An aggressive, romantic opening (1. e4 e5 2. f4) looking to attack the Black King early.",
    fen: "rnbqkbnr/pppp1ppp/8/4p3/4PP2/8/PPPP2PP/RNBQKBNR b KQkq - 0 2",
  ),
  ChessTerm(
    title: "English Opening",
    description: "A flank opening starting with 1. c4, controlling the center from the side.",
    fen: "rnbqkbnr/pppppppp/8/8/2P5/8/PP1PPPPP/RNBQKBNR b KQkq c3 0 1",
  ),
  ChessTerm(
    title: "Reti Opening",
    description: "A hypermodern opening (1. Nf3) that controls the center with pieces rather than pawns initially.",
    fen: "rnbqkbnr/pppppppp/8/8/8/5N2/PPPPPPPP/RNBQKB1R b KQkq - 1 1",
  ),

  // ===========================================================================
  // 🛡️ OPENINGS (Black)
  // ===========================================================================
  ChessTerm(
    title: "Sicilian Defense",
    description: "The most popular and aggressive response to 1. e4 (1... c5), leading to complex, unbalanced games.",
    fen: "rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2",
  ),
  ChessTerm(
    title: "French Defense",
    description: "A solid and resilient defense (1. e4 e6), often leading to closed positions with a pawn chain.",
    fen: "rnbqkbnr/pppp1ppp/4p3/8/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2",
  ),
  ChessTerm(
    title: "Caro-Kann Defense",
    description: "Known for its solidity (1. e4 c6), similar to the French but the light-squared bishop isn't trapped.",
    fen: "rnbqkbnr/pp1ppppp/2p5/8/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2",
  ),
  ChessTerm(
    title: "King's Indian Defense",
    description: "A hypermodern defense (1. d4 Nf6 2. c4 g6) where Black allows White to build a center to attack it later.",
    fen: "rnbqkb1r/pppppp1p/5np1/8/2PP4/8/PP2PPPP/RNBQKBNR w KQkq - 0 3",
  ),
  ChessTerm(
    title: "Nimzo-Indian Defense",
    description: "A highly respected defense against 1. d4, preventing White from playing e4.",
    fen: "rnbqk2r/pppp1ppp/4pn2/8/1bPP4/2N5/PP2PPPP/R1BQKBNR w KQkq - 2 4",
  ),
  ChessTerm(
    title: "Scandinavian Defense",
    description: "Black immediately challenges the center with 1. e4 d5.",
    fen: "rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2",
  ),

  // ===========================================================================
  // 🏁 ENDGAME CONCEPTS
  // ===========================================================================
  ChessTerm(
    title: "Opposition",
    description: "Kings facing each other with one square in between. The side NOT to move has the 'Opposition' and advantage.",
    fen: "8/8/8/8/4k3/4P3/4K3/8 w - - 0 1",
  ),
  ChessTerm(
    title: "Lucena Position",
    description: "The key to winning Rook and Pawn endings. The King bridges out from in front of the pawn.",
    fen: "1R6/8/8/8/8/1k6/1p6/1K6 w - - 0 1",
  ),
  ChessTerm(
    title: "Philidor Position",
    description: "The most important drawing technique in Rook and Pawn endings.",
    fen: "2R5/8/8/8/4k3/8/r7/3K4 w - - 0 1",
  ),
  ChessTerm(
    title: "Triangulation",
    description: "A King maneuver to lose a tempo and put the opponent in Zugzwang.",
    fen: "8/8/8/3k4/8/3K4/3P4/8 w - - 0 1",
  ),
];
