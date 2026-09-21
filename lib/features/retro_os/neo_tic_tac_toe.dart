import 'package:flutter/material.dart';

// ==========================================
// 1. ISOLATED GAME ENGINE (Zero Global Rebuilds)
// ==========================================
class TicTacToeEngine {
  final List<ValueNotifier<String>> board = List.generate(9, (_) => ValueNotifier(''));
  final ValueNotifier<bool> isXTurn = ValueNotifier(true);
  final ValueNotifier<String> winner = ValueNotifier('');

  void handleTap(int index) {
    if (board[index].value != '' || winner.value != '') return;

    board[index].value = isXTurn.value ? 'X' : 'O';
    isXTurn.value = !isXTurn.value;
    _checkWinner();
  }

  void _checkWinner() {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6]
    ];

    for (var line in lines) {
      final a = board[line[0]].value;
      if (a != '' && a == board[line[1]].value && a == board[line[2]].value) {
        winner.value = a;
        return;
      }
    }

    if (!board.any((cell) => cell.value == '')) {
      winner.value = 'DRAW';
    }
  }

  void resetGame() {
    for (var cell in board) {
      cell.value = ''; // Updates seamlessly without triggering a UI rebuild cascade
    }
    isXTurn.value = true;
    winner.value = '';
  }

  void dispose() {
    for (var cell in board) {
      cell.dispose();
    }
    isXTurn.dispose();
    winner.dispose();
  }
}

// ==========================================
// 2. WIDGET CONTROLLER
// ==========================================
class NeoTicTacToe extends StatefulWidget {
  const NeoTicTacToe({super.key});

  @override
  State<NeoTicTacToe> createState() => _NeoTicTacToeState();
}

class _NeoTicTacToeState extends State<NeoTicTacToe> {
  final TicTacToeEngine _engine = TicTacToeEngine();

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            color: const Color(0xFFF4EFE6),
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                        ),
                        itemCount: 9,
                        itemBuilder: (context, index) {
                          // 🔥 Listens ONLY to this specific cell!
                          return ValueListenableBuilder<String>(
                            valueListenable: _engine.board[index],
                            builder: (context, cellValue, _) {
                              return GestureDetector(
                                onTap: () => _engine.handleTap(index),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                                  ),
                                  child: Center(
                                    child: Text(
                                      cellValue,
                                      style: TextStyle(
                                        fontSize: 64,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'monospace',
                                        color: cellValue == 'X' ? const Color(0xFFFF5F56) : const Color(0xFF90CDF4),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // Score/Turn Badge
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF6E05E),
                            border: Border(
                              left: BorderSide(color: Colors.black, width: 2),
                              bottom: BorderSide(color: Colors.black, width: 2),
                            ),
                          ),
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_engine.winner, _engine.isXTurn]),
                            builder: (context, _) {
                              return Text(
                                _engine.winner.value != '' ? 'END' : (_engine.isXTurn.value ? 'P1: X' : 'P2: O'),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, fontFamily: 'monospace'),
                              );
                            },
                          ),
                        ),
                      ),

                      // Game Over Overlay
                      ValueListenableBuilder<String>(
                        valueListenable: _engine.winner,
                        builder: (context, winnerValue, _) {
                          if (winnerValue == '') return const SizedBox.shrink();

                          return Center(
                            child: GestureDetector(
                              onTap: _engine.resetGame,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: winnerValue == 'DRAW' ? const Color(0xFFF6E05E) : const Color(0xFF68D391),
                                  border: Border.all(color: Colors.black, width: 4),
                                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                                ),
                                child: Text(
                                  winnerValue == 'DRAW' ? 'DRAW\nTAP TO RESTART' : '$winnerValue WINS!\nTAP TO RESTART',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'monospace'),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}