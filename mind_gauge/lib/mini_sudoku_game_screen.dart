import 'package:flutter/material.dart';
import 'ui_components.dart';

class MiniSudokuGameScreen extends StatefulWidget {
  const MiniSudokuGameScreen({super.key});

  @override
  State<MiniSudokuGameScreen> createState() => _MiniSudokuGameScreenState();
}

class _MiniSudokuGameScreenState extends State<MiniSudokuGameScreen> {
  // A simple 4x4 Sudoku puzzle
  // 0 represents an empty, mutable cell
  final List<List<int>> initialGrid = [
    [1, 0, 0, 4],
    [0, 2, 0, 0],
    [0, 0, 3, 0],
    [4, 0, 0, 2],
  ];

  late List<List<int>> grid;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    grid = List.generate(4, (r) => List.from(initialGrid[r]));
    setState(() {});
  }

  void _onCellTapped(int row, int col) {
    // Only mutable if it was 0 initially
    if (initialGrid[row][col] != 0) return;

    setState(() {
      grid[row][col] = (grid[row][col] + 1) % 5;
    });

    _checkWinCondition();
  }

  void _checkWinCondition() {
    if (_isGridFull() && _isGridValid()) {
      _showWinDialog();
    }
  }

  bool _isGridFull() {
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (grid[r][c] == 0) return false;
      }
    }
    return true;
  }

  bool _isGridValid() {
    // Check rows and columns
    for (int i = 0; i < 4; i++) {
      Set<int> rowSet = {};
      Set<int> colSet = {};
      for (int j = 0; j < 4; j++) {
        rowSet.add(grid[i][j]);
        colSet.add(grid[j][i]);
      }
      if (rowSet.length != 4 || colSet.length != 4) return false;
    }

    // Check 2x2 blocks
    for (int r = 0; r < 4; r += 2) {
      for (int c = 0; c < 4; c += 2) {
        Set<int> blockSet = {};
        blockSet.add(grid[r][c]);
        blockSet.add(grid[r][c + 1]);
        blockSet.add(grid[r + 1][c]);
        blockSet.add(grid[r + 1][c + 1]);
        if (blockSet.length != 4) return false;
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
        content: const Text('You successfully solved the Mini Sudoku.'),
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
        title: const Text('Mini Sudoku'),
        backgroundColor: const Color(0xFF3B9B62),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Fill the grid with numbers 1-4. Each row, column, and 2x2 block must contain unique numbers.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                      ),
                      itemCount: 16,
                      itemBuilder: (context, index) {
                        final row = index ~/ 4;
                        final col = index % 4;
                        final value = grid[row][col];
                        final isInitial = initialGrid[row][col] != 0;

                        // Calculate border widths for 2x2 subgrids
                        final double topBorder = (row % 2 == 0 && row != 0) ? 2.0 : 0.5;
                        final double leftBorder = (col % 2 == 0 && col != 0) ? 2.0 : 0.5;

                        return GestureDetector(
                          onTap: () => _onCellTapped(row, col),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isInitial ? Colors.grey[200] : Colors.white,
                              border: Border(
                                top: BorderSide(color: Colors.black, width: topBorder),
                                left: BorderSide(color: Colors.black, width: leftBorder),
                                bottom: const BorderSide(color: Colors.black, width: 0.5),
                                right: const BorderSide(color: Colors.black, width: 0.5),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                value == 0 ? '' : value.toString(),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: isInitial ? FontWeight.bold : FontWeight.w500,
                                  color: isInitial ? Colors.black87 : const Color(0xFF3B9B62),
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
