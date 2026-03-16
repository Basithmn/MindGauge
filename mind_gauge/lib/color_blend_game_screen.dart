import 'package:flutter/material.dart';
import 'dart:math';
import 'ui_components.dart';

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

  // Gradient anchors
  final Color topLeft = const Color(0xFF0A1128);       // Deep Navy
  final Color topRight = const Color(0xFF00FFCC);      // Electric Cyan
  final Color bottomLeft = const Color(0xFF3B1E54);    // Deep Purple
  final Color bottomRight = const Color(0xFFFF66CC);   // Soft Magenta

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    tiles = [];
    selectedIndex = null;

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
      _showWinDialog();
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Perfect Harmony!'),
        content: const Text('You successfully restored the color gradient. Your mind is relaxed and focused.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeGame();
            },
            child: const Text('Play Again'),
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
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Swap the tiles to form a perfect color gradient. The corner tiles are locked in place.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          Expanded(
            child: Center(
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
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: StyledButton(
              text: 'Rescramble Grid',
              onPressed: _initializeGame,
              color: const Color(0xFFAC5FE6),
            ),
          ),
        ],
      ),
    );
  }
}
