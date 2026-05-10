import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:confetti/confetti.dart';
import 'ui_components.dart';
import 'services/score_service.dart';

class ColorBlendGameScreen extends StatefulWidget {
  const ColorBlendGameScreen({super.key});

  @override
  State<ColorBlendGameScreen> createState() => _ColorBlendGameScreenState();
}

class Tile {
  final int correctIndex;
  int currentIndex;
  final Color color;
  final bool isLocked;

  Tile({
    required this.correctIndex,
    required this.currentIndex,
    required this.color,
    required this.isLocked,
  });
}

class _ColorBlendGameScreenState extends State<ColorBlendGameScreen> {
  final int gridSize = 5;
  late List<Tile> tiles;
  int? selectedIndex;

  late Color topLeft;
  late Color topRight;
  late Color bottomLeft;
  late Color bottomRight;

  final List<List<Color>> _palettes = [
    // Original Neon
    [const Color(0xFF0A1128), const Color(0xFF00FFCC), const Color(0xFF3B1E54), const Color(0xFFFF66CC)],
    // Sunset
    [const Color(0xFFFF512F), const Color(0xFFDD2476), const Color(0xFFF09819), const Color(0xFFEDDE5D)],
    // Ocean
    [const Color(0xFF2193b0), const Color(0xFF6dd5ed), const Color(0xFF000046), const Color(0xFF1CB5E0)],
    // Forest
    [const Color(0xFF11998e), const Color(0xFF38ef7d), const Color(0xFF000000), const Color(0xFF0f9b0f)],
    // Berry
    [const Color(0xFFbc4e9c), const Color(0xFFf80759), const Color(0xFF5f2c82), const Color(0xFF49a09d)],
  ];

  late ConfettiController _confettiController;
  Timer? _timer;
  int _secondsElapsed = 0;
  int? _bestTime;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadBestTime();
    _initializeGame();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBestTime() async {
    final best = await ScoreService.getBestTime('color_blend');
    if (mounted) {
      setState(() {
        _bestTime = best;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsElapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _initializeGame() {
    tiles = [];
    selectedIndex = null;

    Random rand = Random();
    List<Color> palette = _palettes[rand.nextInt(_palettes.length)];
    List<Color> corners = List.from(palette)..shuffle(rand);
    topLeft = corners[0];
    topRight = corners[1];
    bottomLeft = corners[2];
    bottomRight = corners[3];

    // Generate colors
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        double xRatio = col / (gridSize - 1);
        double yRatio = row / (gridSize - 1);

        Color topColor = Color.lerp(topLeft, topRight, xRatio)!;
        Color bottomColor = Color.lerp(bottomLeft, bottomRight, xRatio)!;
        Color finalColor = Color.lerp(topColor, bottomColor, yRatio)!;

        int index = row * gridSize + col;
        // Lock corners
        bool isLocked = (row == 0 && col == 0) ||
            (row == 0 && col == gridSize - 1) ||
            (row == gridSize - 1 && col == 0) ||
            (row == gridSize - 1 && col == gridSize - 1);

        tiles.add(Tile(
          correctIndex: index,
          currentIndex: index,
          color: finalColor,
          isLocked: isLocked,
        ));
      }
    }

    _scrambleTiles();
    _startTimer();
  }

  void _scrambleTiles() {
    List<Tile> unlockedTiles = tiles.where((t) => !t.isLocked).toList();
    unlockedTiles.shuffle(Random());

    int unlockedIdx = 0;
    for (int i = 0; i < tiles.length; i++) {
      if (!tiles[i].isLocked) {
        Tile swapped = unlockedTiles[unlockedIdx];
        swapped.currentIndex = i;
        tiles[i] = swapped;
        unlockedIdx++;
      }
    }

    setState(() {});
  }

  void _onTileTap(int index) {
    if (tiles[index].isLocked) return;

    setState(() {
      if (selectedIndex == null) {
        selectedIndex = index;
      } else {
        if (selectedIndex == index) {
          selectedIndex = null;
        } else {
          // Swap
          Tile temp = tiles[selectedIndex!];
          tiles[selectedIndex!] = tiles[index];
          tiles[index] = temp;

          tiles[selectedIndex!].currentIndex = selectedIndex!;
          tiles[index].currentIndex = index;

          // Check for wrong move
          bool selectedIsCorrectNow = tiles[selectedIndex!].correctIndex == tiles[selectedIndex!].currentIndex;
          bool targetIsCorrectNow = tiles[index].correctIndex == tiles[index].currentIndex;

          if (!selectedIsCorrectNow && !targetIsCorrectNow) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Neither tile is in its correct place. Keep trying!'),
                duration: Duration(milliseconds: 1500),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          selectedIndex = null;
          _checkWinCondition();
        }
      }
    });
  }

  void _checkWinCondition() {
    bool isWin = true;
    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i].correctIndex != tiles[i].currentIndex) {
        isWin = false;
        break;
      }
    }

    if (isWin) {
      _handleWin();
    }
  }

  Future<void> _handleWin() async {
    _timer?.cancel();
    
    await ScoreService.setBestTime('color_blend', _secondsElapsed);
    await _loadBestTime();

    if (_secondsElapsed <= 180) {
      _confettiController.play();
    }

    _showWinDialog();
  }

  void _showWinDialog() {
    bool over3Mins = _secondsElapsed > 180;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          over3Mins ? 'Great perseverance!' : 'Perfect Harmony!',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFAC5FE6))
        ),
        content: Text(
          over3Mins 
            ? 'You finished in ${_formatTime(_secondsElapsed)}.\nBetter luck next time for a faster solve!'
            : 'You successfully restored the color gradient in ${_formatTime(_secondsElapsed)}! Your mind is relaxed and focused.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeGame();
            },
            child: const Text('Play Again', style: TextStyle(color: Color(0xFFAC5FE6))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFAC5FE6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Soothing soft background
      appBar: AppBar(
        title: const Text('Color Blend'),
        backgroundColor: const Color(0xFFAC5FE6),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Time: ${_formatTime(_secondsElapsed)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                    ),
                    Text(
                      _bestTime != null ? 'Streak: ${_formatTime(_bestTime!)}' : 'Streak: --:--',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFAC5FE6)),
                    ),
                  ],
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridSize,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: gridSize * gridSize,
                        itemBuilder: (context, index) {
                          final tile = tiles[index];
                          final isSelected = selectedIndex == index;

                          return GestureDetector(
                            onTap: () => _onTileTap(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: tile.color,
                                borderRadius: BorderRadius.circular(tile.isLocked ? 12 : 4),
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: isSelected ? 3 : 0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : [],
                              ),
                              child: tile.isLocked
                                  ? const Center(
                                      child: Icon(
                                        Icons.circle,
                                        color: Colors.white30,
                                        size: 8,
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: StyledButton(
                  text: 'Rescramble Grid',
                  onPressed: _initializeGame,
                  color: const Color(0xFFAC5FE6),
                ),
              ),
              const HowToPlayCard(
                rules: [
                  Text('Swap the inner tiles to form a perfect, seamless color gradient across the entire board.', style: TextStyle(fontSize: 16)),
                  Text('The four corner tiles are locked in place to guide you.', style: TextStyle(fontSize: 16)),
                  Text('Tap a tile to select it, then tap another to swap their positions.', style: TextStyle(fontSize: 16)),
                ],
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}