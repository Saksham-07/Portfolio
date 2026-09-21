import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ==========================================
// 1. ISOLATED CARD MODEL
// ==========================================
class MemoryCard {
  final IconData icon;
  final ValueNotifier<bool> isFlipped = ValueNotifier(false);
  final ValueNotifier<bool> isMatched = ValueNotifier(false);

  MemoryCard(this.icon);

  void dispose() {
    isFlipped.dispose();
    isMatched.dispose();
  }
}

// ==========================================
// 2. GAME ENGINE (Zero Global Rebuilds)
// ==========================================
class MemoryGameEngine {
  final List<IconData> _baseIcons = [
    Icons.computer, Icons.bug_report, Icons.gamepad, Icons.coffee,
    Icons.code, Icons.storage, Icons.security, Icons.rocket_launch,
  ];

  late List<MemoryCard> cards;
  final ValueNotifier<int> score = ValueNotifier(0);
  final ValueNotifier<bool> isGameOver = ValueNotifier(false);

  int _previousIndex = -1;
  bool _isProcessing = false;

  MemoryGameEngine() {
    _initCards();
  }

  void _initCards() {
    final rawIcons = [..._baseIcons, ..._baseIcons];
    rawIcons.shuffle(math.Random());
    cards = rawIcons.map((icon) => MemoryCard(icon)).toList();
    score.value = 0;
    isGameOver.value = false;
    _previousIndex = -1;
    _isProcessing = false;
  }

  void resetGame() {
    for (var card in cards) {
      card.dispose();
    }
    _initCards();
  }

  void handleTap(int index) {
    if (_isProcessing || cards[index].isFlipped.value || cards[index].isMatched.value) return;

    cards[index].isFlipped.value = true;

    if (_previousIndex == -1) {
      _previousIndex = index;
    } else {
      _isProcessing = true;
      if (cards[_previousIndex].icon == cards[index].icon) {
        // Match!
        cards[_previousIndex].isMatched.value = true;
        cards[index].isMatched.value = true;
        score.value += 10;
        _previousIndex = -1;
        _isProcessing = false;

        if (cards.every((card) => card.isMatched.value)) {
          isGameOver.value = true;
        }
      } else {
        // No Match, flip back after a short delay
        final prev = _previousIndex;
        Timer(const Duration(milliseconds: 800), () {
          cards[prev].isFlipped.value = false;
          cards[index].isFlipped.value = false;
          _previousIndex = -1;
          _isProcessing = false;
        });
      }
    }
  }

  void dispose() {
    score.dispose();
    isGameOver.dispose();
    for (var card in cards) {
      card.dispose();
    }
  }
}

// ==========================================
// 3. WIDGET CONTROLLER
// ==========================================
class NeoMemoryGame extends StatefulWidget {
  const NeoMemoryGame({super.key});

  @override
  State<NeoMemoryGame> createState() => _NeoMemoryGameState();
}

class _NeoMemoryGameState extends State<NeoMemoryGame> {
  late MemoryGameEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = MemoryGameEngine();
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  void _restartGame() {
    // We only call setState here because we are completely destroying and recreating
    // the entire list of MemoryCard objects, requiring the Grid to remap them.
    setState(() {
      _engine.resetGame();
    });
  }

  Widget _buildBackSide() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF90CDF4),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
      ),
      child: const Center(
        child: Icon(Icons.help_outline, size: 24, color: Colors.black54),
      ),
    );
  }

  Widget _buildFrontSide(IconData icon, bool isMatched) {
    return Container(
      decoration: BoxDecoration(
        color: isMatched ? const Color(0xFF68D391) : Colors.white,
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: Center(
        child: Icon(icon, size: 32, color: Colors.black),
      ),
    );
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
                  decoration: const BoxDecoration(color: Color(0xFF0F172A)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: 16,
                        itemBuilder: (context, index) {
                          final card = _engine.cards[index];

                          // 🔥 Listens ONLY to this specific card's flip/match states
                          return AnimatedBuilder(
                            animation: Listenable.merge([card.isFlipped, card.isMatched]),
                            builder: (context, _) {
                              final isRevealed = card.isFlipped.value || card.isMatched.value;

                              return TweenAnimationBuilder(
                                tween: Tween<double>(begin: 0, end: isRevealed ? 1 : 0),
                                duration: const Duration(milliseconds: 300),
                                builder: (context, double value, child) {
                                  final angle = value * math.pi;
                                  final isFrontVisible = value >= 0.5;

                                  return GestureDetector(
                                    onTap: () => _engine.handleTap(index),
                                    child: Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, 0.002)
                                        ..rotateY(angle),
                                      child: isFrontVisible
                                          ? Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.rotationY(math.pi),
                                        child: _buildFrontSide(card.icon, card.isMatched.value),
                                      )
                                          : _buildBackSide(),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),

                      // Score Badge
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF6E05E),
                            border: Border(left: BorderSide(color: Colors.black, width: 2), bottom: BorderSide(color: Colors.black, width: 2)),
                          ),
                          child: ValueListenableBuilder<int>(
                              valueListenable: _engine.score,
                              builder: (context, scoreValue, _) {
                                return Text('PTS:$scoreValue', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, fontFamily: 'monospace'));
                              }
                          ),
                        ),
                      ),

                      // Game Over Overlay
                      ValueListenableBuilder<bool>(
                          valueListenable: _engine.isGameOver,
                          builder: (context, isGameOverValue, _) {
                            if (!isGameOverValue) return const SizedBox.shrink();

                            return Center(
                              child: GestureDetector(
                                onTap: _restartGame,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF68D391),
                                    border: Border.all(color: Colors.black, width: 4),
                                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                                  ),
                                  child: const Text(
                                    'YOU WIN!\nTAP TO RESTART',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'monospace'),
                                  ),
                                ),
                              ),
                            );
                          }
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