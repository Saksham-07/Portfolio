import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 1. ISOLATED GAME STATE (No UI Rebuilds)
class _GameState {
  final List<math.Point<int>> snake;
  final math.Point<int> food;

  _GameState(this.snake, this.food);
}

class NeoSnakeGame extends StatefulWidget {
  const NeoSnakeGame({super.key});

  @override
  State<NeoSnakeGame> createState() => _NeoSnakeGameState();
}

class _NeoSnakeGameState extends State<NeoSnakeGame> {
  static const int gridSize = 15;

  // UI States (Only change on start/death)
  bool isPlaying = false;
  bool isGameOver = false;
  int score = 0;

  // Game Loop Logic
  late ValueNotifier<_GameState> _gameStateNotifier;
  List<math.Point<int>> _snake = [const math.Point(7, 7)];
  math.Point<int> _food = const math.Point(10, 10);
  math.Point<int> _direction = const math.Point(1, 0);
  math.Point<int> _nextDirection = const math.Point(1, 0);

  Timer? timer;
  final FocusNode _focusNode = FocusNode();
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _gameStateNotifier = ValueNotifier(_GameState(_snake, _food));
  }

  @override
  void dispose() {
    timer?.cancel();
    _focusNode.dispose();
    _gameStateNotifier.dispose();
    super.dispose();
  }

  void startGame() {
    _snake = [const math.Point(7, 7)];
    _direction = const math.Point(1, 0);
    _nextDirection = const math.Point(1, 0);
    _spawnFood();

    // Only call setState ONCE to hide the "Start" button
    setState(() {
      score = 0;
      isPlaying = true;
      isGameOver = false;
    });

    _focusNode.requestFocus();
    timer?.cancel();
    // Start the invisible logic loop
    timer = Timer.periodic(const Duration(milliseconds: 150), (Timer t) => _gameTick());
  }

  void _spawnFood() {
    math.Point<int> newFood;
    do {
      newFood = math.Point(_random.nextInt(gridSize), _random.nextInt(gridSize));
    } while (_snake.contains(newFood));
    _food = newFood;
  }

  void _gameTick() {
    _direction = _nextDirection;
    final newHead = math.Point(_snake.first.x + _direction.x, _snake.first.y + _direction.y);

    // Death Check
    if (newHead.x < 0 || newHead.x >= gridSize ||
        newHead.y < 0 || newHead.y >= gridSize ||
        _snake.contains(newHead)) {
      timer?.cancel();
      // Only call setState when the game ends to show the overlay
      setState(() {
        isPlaying = false;
        isGameOver = true;
      });
      return;
    }

    _snake.insert(0, newHead);

    if (newHead == _food) {
      // Update score UI (this is lightweight)
      setState(() {
        score += 10;
      });
      _spawnFood();
    } else {
      _snake.removeLast();
    }

    // 🔥 THE MAGIC: Update the canvas without rebuilding the Widget Tree!
    _gameStateNotifier.value = _GameState(List.from(_snake), _food);
  }

  void _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp && _direction.y != 1) {
        _nextDirection = const math.Point(0, -1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown && _direction.y != -1) {
        _nextDirection = const math.Point(0, 1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft && _direction.x != 1) {
        _nextDirection = const math.Point(-1, 0);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight && _direction.x != -1) {
        _nextDirection = const math.Point(1, 0);
      }
    }
  }

  void _changeDirection(math.Point<int> newDir) {
    if ((newDir.x != 0 && _direction.x != -newDir.x) || (newDir.y != 0 && _direction.y != -newDir.y)) {
      _nextDirection = newDir;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: KeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: _handleKey,
            child: GestureDetector(
              onTap: !isPlaying ? startGame : null,
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
                          // 🔥 LISTENS DIRECTLY TO GAME LOOP
                          ValueListenableBuilder<_GameState>(
                            valueListenable: _gameStateNotifier,
                            builder: (context, state, _) {
                              return CustomPaint(
                                painter: _SnakePainter(state.snake, state.food, gridSize),
                              );
                            },
                          ),

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
                              child: Text(
                                'PTS:$score',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, fontFamily: 'monospace'),
                              ),
                            ),
                          ),

                          if (!isPlaying)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isGameOver ? const Color(0xFFFF5F56) : const Color(0xFF90CDF4),
                                  border: Border.all(color: Colors.black, width: 4),
                                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                                ),
                                child: Text(
                                  isGameOver ? 'GAME OVER\nTAP TO RESTART' : 'TAP TO START',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'monospace'),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        if (MediaQuery.of(context).size.width < 600)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.black, width: 4)),
              color: Color(0xFFF4EFE6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDpadBtn(Icons.arrow_left, const math.Point(-1, 0)),
                Column(
                  children: [
                    _buildDpadBtn(Icons.arrow_drop_up, const math.Point(0, -1)),
                    const SizedBox(height: 8),
                    _buildDpadBtn(Icons.arrow_drop_down, const math.Point(0, 1)),
                  ],
                ),
                _buildDpadBtn(Icons.arrow_right, const math.Point(1, 0)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDpadBtn(IconData icon, math.Point<int> dir) {
    return GestureDetector(
      onTap: () => _changeDirection(dir),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
        ),
        child: Icon(icon, size: 32, color: Colors.black),
      ),
    );
  }
}

// PAINTER REMAINS EXACTLY THE SAME!
class _SnakePainter extends CustomPainter {
  final List<math.Point<int>> snake;
  final math.Point<int> food;
  final int gridSize;

  _SnakePainter(this.snake, this.food, this.gridSize);

  @override
  void paint(Canvas canvas, Size size) {
    final double cellSize = size.width / gridSize;

    final Paint gridLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for(int i = 0; i <= gridSize; i++) {
      double pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), gridLinePaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), gridLinePaint);
    }

    final Paint borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint snakePaint = Paint()..color = const Color(0xFF68D391);
    final Paint headPaint = Paint()..color = const Color(0xFF27C93F);
    final Paint foodPaint = Paint()..color = const Color(0xFFFFB6B9);

    final foodRect = Rect.fromLTWH(
        food.x * cellSize + 2,
        food.y * cellSize + 2,
        cellSize - 4, cellSize - 4
    );
    canvas.drawRect(foodRect, foodPaint);
    canvas.drawRect(foodRect, borderPaint);

    for (int i = 0; i < snake.length; i++) {
      final rect = Rect.fromLTWH(
          snake[i].x * cellSize + 1,
          snake[i].y * cellSize + 1,
          cellSize - 2, cellSize - 2
      );
      canvas.drawRect(rect, i == 0 ? headPaint : snakePaint);
      canvas.drawRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnakePainter oldDelegate) => true;
}