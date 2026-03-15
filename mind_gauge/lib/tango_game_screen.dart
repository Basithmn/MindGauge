import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ui_components.dart';

class TangoGameScreen extends StatefulWidget {
  const TangoGameScreen({super.key});

  @override
  State<TangoGameScreen> createState() => _TangoGameScreenState();
}

class _TangoGameScreenState extends State<TangoGameScreen> {
  final int gridSize = 6;
  
  // 0: empty, 1: blue, 2: yellow
  static final List<List<List<int>>> _dailyPuzzles = [
    [ // Day 1
      [0, 1, 0, 0, 2, 0],
      [0, 1, 0, 1, 0, 2],
      [2, 0, 0, 1, 0, 0],
      [0, 2, 2, 0, 0, 1],
      [0, 0, 0, 2, 2, 0],
      [1, 0, 1, 0, 0, 0],
    ],
    [ // Day 2
      [0, 0, 1, 0, 0, 2],
      [0, 2, 0, 0, 2, 0],
      [1, 0, 0, 2, 0, 0],
      [0, 0, 1, 0, 0, 1],
      [0, 1, 0, 0, 1, 0],
      [2, 0, 0, 1, 0, 0],
    ],
    [ // Day 3
      [0, 2, 0, 1, 0, 0],
      [0, 0, 1, 0, 0, 2],
      [2, 0, 0, 2, 0, 0],
      [0, 0, 2, 0, 0, 1],
      [0, 1, 0, 0, 1, 0],
      [1, 0, 0, 1, 0, 0],
    ],
  ];

  late List<List<int>> initialGrid;
  late List<List<int>> grid;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    int dayOfYear = int.parse(DateFormat("D").format(DateTime.now()));
    int index = dayOfYear % _dailyPuzzles.length;
    initialGrid = _dailyPuzzles[index];
    grid = List.generate(gridSize, (r) => List.from(initialGrid[r]));
    setState(() {});
  }

  void _onCellTapped(int row, int col) {
    if (initialGrid[row][col] != 0) return;

    setState(() {
      grid[row][col] = (grid[row][col] + 1) % 3;
    });

    _checkWinCondition();
  }

  void _checkWinCondition() {
    if (_isGridFull() && _isGridValid()) {
      _showWinDialog();
    }
  }

  bool _isGridFull() {
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (grid[r][c] == 0) return false;
      }
    }
    return true;
  }

  bool _isGridValid() {
    // 1. Check counts per row/col (must be 3 of each color)
    for (int i = 0; i < gridSize; i++) {
       int rowBlue = 0, rowYellow = 0;
       int colBlue = 0, colYellow = 0;
       for (int j = 0; j < gridSize; j++) {
          if (grid[i][j] == 1) rowBlue++;
          if (grid[i][j] == 2) rowYellow++;
          if (grid[j][i] == 1) colBlue++;
          if (grid[j][i] == 2) colYellow++;
       }
       if (rowBlue != 3 || rowYellow != 3 || colBlue != 3 || colYellow != 3) {
         return false;
       }
    }

    // 2. Check consecutive matching colors (no more than 2 in a row/col)
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize - 2; j++) {
        // Row check
        if (grid[i][j] != 0 && grid[i][j] == grid[i][j+1] && grid[i][j] == grid[i][j+2]) return false;
        // Col check
        if (grid[j][i] != 0 && grid[j][i] == grid[j+1][i] && grid[j][i] == grid[j+2][i]) return false;
      }
    }

    // 3. Check for unique rows and cols
    for (int i = 0; i < gridSize; i++) {
       for (int k = i + 1; k < gridSize; k++) {
         bool rowSame = true;
         bool colSame = true;
         for (int j = 0; j < gridSize; j++) {
            if (grid[i][j] != grid[k][j]) rowSame = false;
            if (grid[j][i] != grid[j][k]) colSame = false;
         }
         if (rowSame || colSame) return false;
       }
    }

    return true;
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Puzzle Solved!'),
        content: const Text('You successfully found the Tango patterns and completed today\'s challenge!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetGame();
            },
            child: const Text('Play Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C668A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Back to Games'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tango'),
        backgroundColor: const Color(0xFF4C668A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Fill the grid with Blue and Yellow. No 3 of the same color in a row. Equal colors per line. No identical lines.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black87, width: 3),
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridSize,
                      ),
                      itemCount: gridSize * gridSize,
                      itemBuilder: (context, index) {
                        final row = index ~/ gridSize;
                        final col = index % gridSize;
                        final value = grid[row][col];
                        final isInitial = initialGrid[row][col] != 0;

                        Color cellColor = Colors.white;
                        if (value == 1) cellColor = const Color(0xFFA5C5F2); // Blue
                        if (value == 2) cellColor = const Color(0xFFFCAE3D); // Yellow

                        return GestureDetector(
                          onTap: () => _onCellTapped(row, col),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cellColor,
                              border: Border.all(color: Colors.black54, width: 0.5),
                            ),
                            child: isInitial
                                ? Center(
                                    child: Icon(
                                      Icons.lock,
                                      size: 16,
                                      color: Colors.black.withOpacity(0.3),
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
            padding: const EdgeInsets.all(20.0),
            child: StyledButton(
              text: 'Reset Puzzle',
              onPressed: _resetGame,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
