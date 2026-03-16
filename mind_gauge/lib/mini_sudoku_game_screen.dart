import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ui_components.dart';

class MiniSudokuGameScreen extends StatefulWidget {
  const MiniSudokuGameScreen({super.key});

  @override
  State<MiniSudokuGameScreen> createState() => _MiniSudokuGameScreenState();
}

class _MiniSudokuGameScreenState extends State<MiniSudokuGameScreen> {
  // 0 represents an empty, mutable cell
  final List<List<int>> initialGrid = [
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9],
  ];

  late List<List<int>> grid;
  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    grid = List.generate(9, (r) => List.from(initialGrid[r]));
    setState(() {});
  }

  void _onCellTapped(int row, int col) {
    if (initialGrid[row][col] != 0) return;

    setState(() {
      // Cycles from 0 -> 1 ... -> 9 -> 0
      grid[row][col] = (grid[row][col] + 1) % 10;
    });

    _checkWinCondition();
  }

  void _checkWinCondition() {
    if (_isGridFull() && _isGridValid()) {
      _showWinDialog();
    }
  }

  bool _isGridFull() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] == 0) return false;
      }
    }
    return true;
  }

  bool _isGridValid() {
    // Check rows and columns
    for (int i = 0; i < 9; i++) {
      Set<int> rowSet = {};
      Set<int> colSet = {};
      for (int j = 0; j < 9; j++) {
        rowSet.add(grid[i][j]);
        colSet.add(grid[j][i]);
      }
      if (rowSet.length != 9 || colSet.length != 9) return false;
    }

    // Check 3x3 blocks (nine blocks total)
    for (int blockRow = 0; blockRow < 9; blockRow += 3) {
      for (int blockCol = 0; blockCol < 9; blockCol += 3) {
        Set<int> blockSet = {};

        for (int r = 0; r < 3; r++) {
          for (int c = 0; c < 3; c++) {
            blockSet.add(grid[blockRow + r][blockCol + c]);
          }
        }

        if (blockSet.length != 9) return false;
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
        content: const Text('You successfully navigated the 9x9 matrix.'),
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
              backgroundColor: const Color(0xFF3B9B62),
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
        title: const Text('Sudoku (9x9)'),
        backgroundColor: const Color(0xFF3B9B62),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Fill the grid with numbers 1-9. Each row, column, and 3x3 block must contain unique numbers.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 9,
                          ),
                      itemCount: 81, // 9x9
                      itemBuilder: (context, index) {
                        final row = index ~/ 9;
                        final col = index % 9;
                        final value = grid[row][col];
                        final isInitial = initialGrid[row][col] != 0;

                        // Calculate border widths for 3x3 subgrids
                        final double topBorder = (row > 0 && row % 3 == 0)
                            ? 2.5
                            : 0.5;
                        final double leftBorder = (col > 0 && col % 3 == 0)
                            ? 2.5
                            : 0.5;

                        return GestureDetector(
                          onTap: () => _onCellTapped(row, col),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isInitial
                                  ? Colors.grey[200]
                                  : Colors.white,
                              border: Border(
                                top: BorderSide(
                                  color: Colors.black,
                                  width: topBorder,
                                ),
                                left: BorderSide(
                                  color: Colors.black,
                                  width: leftBorder,
                                ),
                                bottom: const BorderSide(
                                  color: Colors.black,
                                  width: 0.5,
                                ),
                                right: const BorderSide(
                                  color: Colors.black,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                value == 0 ? '' : value.toString(),
                                style: TextStyle(
                                  fontSize: 18, // Scaled down for 9x9 fit
                                  fontWeight: isInitial
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isInitial
                                      ? Colors.black87
                                      : const Color(0xFF3B9B62),
                                ),
                              ),
                            ),
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
