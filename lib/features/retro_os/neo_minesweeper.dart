import 'dart:math' as math;
import 'package:flutter/material.dart';

// ==========================================
// 1. ISOLATED CELL STATE
// ==========================================
class CellState {
  final bool isRevealed;
  final bool isFlagged;
  final bool isMine;
  final int adjacentMines;

  CellState({
    this.isRevealed = false,
    this.isFlagged = false,
    this.isMine = false,
    this.adjacentMines = 0,
  });

  CellState copyWith({bool? isRevealed, bool? isFlagged, bool? isMine, int? adjacentMines}) {
    return CellState(
      isRevealed: isRevealed ?? this.isRevealed,
      isFlagged: isFlagged ?? this.isFlagged,
      isMine: isMine ?? this.isMine,
      adjacentMines: adjacentMines ?? this.adjacentMines,
    );
  }
}

// ==========================================
// 2. HYPER-OPTIMIZED GAME ENGINE
// ==========================================
class MinesweeperEngine {
  final int rows = 9;
  final int cols = 9;
  final int totalMines = 10;

  late List<ValueNotifier<CellState>> board;
  final ValueNotifier<String> gameState = ValueNotifier('playing'); // playing, won, lost
  final ValueNotifier<int> flagsPlaced = ValueNotifier(0);

  bool _isFirstTap = true;

  MinesweeperEngine() {
    _initBoard();
  }

  void _initBoard() {
    board = List.generate(rows * cols, (_) => ValueNotifier(CellState()));
    gameState.value = 'playing';
    flagsPlaced.value = 0;
    _isFirstTap = true;
  }

  void resetGame() {
    for (var cell in board) {
      cell.value = CellState();
    }
    gameState.value = 'playing';
    flagsPlaced.value = 0;
    _isFirstTap = true;
  }

  void _placeMines(int safeIndex) {
    int minesPlaced = 0;
    final rand = math.Random();

    while (minesPlaced < totalMines) {
      int index = rand.nextInt(rows * cols);
      // Don't place a mine on the first click or if one already exists
      if (index != safeIndex && !board[index].value.isMine) {
        board[index].value = board[index].value.copyWith(isMine: true);
        minesPlaced++;
      }
    }

    // Calculate adjacent numbers
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        int idx = r * cols + c;
        if (!board[idx].value.isMine) {
          int count = 0;
          for (int i = -1; i <= 1; i++) {
            for (int j = -1; j <= 1; j++) {
              int nr = r + i;
              int nc = c + j;
              if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
                if (board[nr * cols + nc].value.isMine) count++;
              }
            }
          }
          board[idx].value = board[idx].value.copyWith(adjacentMines: count);
        }
      }
    }
  }

  void handleTap(int index) {
    if (gameState.value != 'playing' || board[index].value.isFlagged || board[index].value.isRevealed) return;

    if (_isFirstTap) {
      _placeMines(index);
      _isFirstTap = false;
    }

    if (board[index].value.isMine) {
      _triggerGameOver();
      return;
    }

    _floodFillReveal(index);
    _checkWinCondition();
  }

  void handleLongPress(int index) {
    if (gameState.value != 'playing' || board[index].value.isRevealed) return;

    final cell = board[index].value;
    board[index].value = cell.copyWith(isFlagged: !cell.isFlagged);
    flagsPlaced.value += !cell.isFlagged ? 1 : -1;
  }

  void _floodFillReveal(int index) {
    if (board[index].value.isRevealed || board[index].value.isFlagged) return;

    board[index].value = board[index].value.copyWith(isRevealed: true);

    if (board[index].value.adjacentMines == 0) {
      int r = index ~/ cols;
      int c = index % cols;

      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          int nr = r + i;
          int nc = c + j;
          if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
            _floodFillReveal(nr * cols + nc);
          }
        }
      }
    }
  }

  void _triggerGameOver() {
    gameState.value = 'lost';
    for (int i = 0; i < board.length; i++) {
      if (board[i].value.isMine) {
        board[i].value = board[i].value.copyWith(isRevealed: true);
      }
    }
  }

  void _checkWinCondition() {
    int revealedCount = 0;
    for (var cell in board) {
      if (cell.value.isRevealed) revealedCount++;
    }
    if (revealedCount == (rows * cols) - totalMines) {
      gameState.value = 'won';
      // Auto-flag remaining mines
      for (int i = 0; i < board.length; i++) {
        if (board[i].value.isMine && !board[i].value.isFlagged) {
          board[i].value = board[i].value.copyWith(isFlagged: true);
        }
      }
      flagsPlaced.value = totalMines;
    }
  }

  void dispose() {
    for (var cell in board) {
      cell.dispose();
    }
    gameState.dispose();
    flagsPlaced.dispose();
  }
}

// ==========================================
// 3. WIDGET CONTROLLER
// ==========================================
class NeoMinesweeper extends StatefulWidget {
  const NeoMinesweeper({super.key});

  @override
  State<NeoMinesweeper> createState() => _NeoMinesweeperState();
}

class _NeoMinesweeperState extends State<NeoMinesweeper> {
  late MinesweeperEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = MinesweeperEngine();
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  Color _getNumberColor(int count) {
    switch (count) {
      case 1: return Colors.blue[700]!;
      case 2: return Colors.green[700]!;
      case 3: return Colors.red[600]!;
      case 4: return Colors.purple[700]!;
      case 5: return Colors.orange[800]!;
      default: return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top HUD Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black, width: 4)),
            color: Color(0xFFF4EFE6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Mine Counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: ValueListenableBuilder<int>(
                  valueListenable: _engine.flagsPlaced,
                  builder: (context, flags, _) {
                    final remaining = (_engine.totalMines - flags).toString().padLeft(3, '0');
                    return Text(
                      remaining,
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'monospace'),
                    );
                  },
                ),
              ),

              // Reset Face Button
              GestureDetector(
                onTap: _engine.resetGame,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6E05E),
                    border: Border.all(color: Colors.black, width: 3),
                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                  ),
                  child: ValueListenableBuilder<String>(
                    valueListenable: _engine.gameState,
                    builder: (context, state, _) {
                      IconData icon = Icons.sentiment_satisfied_alt;
                      if (state == 'won') icon = Icons.sentiment_very_satisfied;
                      if (state == 'lost') icon = Icons.sentiment_very_dissatisfied;
                      return Icon(icon, size: 24, color: Colors.black);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Game Board Area
        Expanded(
          child: Container(
            width: double.infinity,
            color: const Color(0xFFF4EFE6),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    border: Border.all(color: Colors.black, width: 4),
                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 9,
                    ),
                    itemCount: 81,
                    itemBuilder: (context, index) {
                      return ValueListenableBuilder<CellState>(
                        valueListenable: _engine.board[index],
                        builder: (context, cell, _) {
                          return GestureDetector(
                            onTap: () => _engine.handleTap(index),
                            onSecondaryTap: () => _engine.handleLongPress(index), // Right click
                            onLongPress: () => _engine.handleLongPress(index), // Mobile hold
                            child: Container(
                              decoration: BoxDecoration(
                                color: cell.isRevealed ? Colors.white : const Color(0xFF90CDF4),
                                border: Border(
                                  top: BorderSide(color: cell.isRevealed ? Colors.grey[300]! : Colors.white, width: cell.isRevealed ? 1 : 2),
                                  left: BorderSide(color: cell.isRevealed ? Colors.grey[300]! : Colors.white, width: cell.isRevealed ? 1 : 2),
                                  right: BorderSide(color: cell.isRevealed ? Colors.grey[300]! : Colors.black, width: cell.isRevealed ? 1 : 2),
                                  bottom: BorderSide(color: cell.isRevealed ? Colors.grey[300]! : Colors.black, width: cell.isRevealed ? 1 : 2),
                                ),
                              ),
                              child: Center(
                                child: _buildCellContent(cell),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCellContent(CellState cell) {
    if (cell.isFlagged) {
      return const Icon(Icons.flag, size: 18, color: Color(0xFFFF5F56));
    }
    if (!cell.isRevealed) {
      return const SizedBox.shrink();
    }
    if (cell.isMine) {
      return Container(
        decoration: const BoxDecoration(color: Color(0xFFFF5F56)),
        child: const Center(child: Icon(Icons.brightness_high, size: 18, color: Colors.black)),
      );
    }
    if (cell.adjacentMines > 0) {
      return Text(
        cell.adjacentMines.toString(),
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 16,
          fontFamily: 'monospace',
          color: _getNumberColor(cell.adjacentMines),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}