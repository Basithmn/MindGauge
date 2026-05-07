import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:confetti/confetti.dart';
import 'ui_components.dart';
import 'services/score_service.dart';

class MiniSudokuGameScreen extends StatefulWidget {
  const MiniSudokuGameScreen({super.key});

  @override
  State<MiniSudokuGameScreen> createState() => _MiniSudokuGameScreenState();
}

class _MiniSudokuGameScreenState extends State<MiniSudokuGameScreen> {
  late List<List<int>> initialGrid;
  late List<List<int>> grid;
  Point<int>? _selectedCell;

  late ConfettiController _confettiController;
  Timer? _timer;
  int _secondsElapsed = 0;
  int? _bestTime;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadBestTime();
    _resetGame();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBestTime() async {
    final best = await ScoreService.getBestTime('sudoku_6x6');
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

  List<List<int>> _generatePuzzle() {
    List<List<int>> baseGrid = [
      [1, 2, 3, 4, 5, 6],
      [4, 5, 6, 1, 2, 3],
      [2, 3, 1, 5, 6, 4],
      [5, 6, 4, 2, 3, 1],
      [3, 1, 2, 6, 4, 5],
      [6, 4, 5, 3, 1, 2],
    ];

    Random rand = Random();

    // Swap rows within blocks
    for (int blockStart = 0; blockStart < 6; blockStart += 2) {
      if (rand.nextBool()) {
        List<int> temp = baseGrid[blockStart];
        baseGrid[blockStart] = baseGrid[blockStart + 1];
        baseGrid[blockStart + 1] = temp;
      }
    }

    // Swap columns within blocks
    for (int blockStart = 0; blockStart < 6; blockStart += 3) {
      List<int> offsets = [0, 1, 2];
      offsets.shuffle(rand);
      for (int r = 0; r < 6; r++) {
        List<int> blockCols = [
          baseGrid[r][blockStart],
          baseGrid[r][blockStart + 1],
          baseGrid[r][blockStart + 2]
        ];
        baseGrid[r][blockStart] = blockCols[offsets[0]];
        baseGrid[r][blockStart + 1] = blockCols[offsets[1]];
        baseGrid[r][blockStart + 2] = blockCols[offsets[2]];
      }
    }

    // Map numbers
    List<int> nums = [1, 2, 3, 4, 5, 6];
    nums.shuffle(rand);
    for (int r = 0; r < 6; r++) {
      for (int c = 0; c < 6; c++) {
        baseGrid[r][c] = nums[baseGrid[r][c] - 1];
      }
    }

    // Erase cells
    int cellsToErase = 20 + rand.nextInt(6);
    initialGrid = List.generate(6, (r) => List.from(baseGrid[r]));
    while(cellsToErase > 0) {
      int r = rand.nextInt(6);
      int c = rand.nextInt(6);
      if (initialGrid[r][c] != 0) {
        initialGrid[r][c] = 0;
        cellsToErase--;
      }
    }

    return List.generate(6, (r) => List.from(initialGrid[r]));
  }

  void _resetGame() {
    grid = _generatePuzzle();
    _selectedCell = null;
    _startTimer();
    setState(() {});
  }

  bool _isValidMove(int row, int col, int value) {
    // Check row and column
    for (int i = 0; i < 6; i++) {
      if (i != col && grid[row][i] == value) return false;
      if (i != row && grid[i][col] == value) return false;
    }
    // Check 2x3 block (2 rows, 3 cols)
    int blockRow = (row ~/ 2) * 2;
    int blockCol = (col ~/ 3) * 3;
    for (int r = 0; r < 2; r++) {
      for (int c = 0; c < 3; c++) {
        if ((blockRow + r != row || blockCol + c != col) && 
            grid[blockRow + r][blockCol + c] == value) {
          return false;
        }
      }
    }
    return true;
  }

  void _onCellTapped(int row, int col) {
    if (initialGrid[row][col] != 0) {
      setState(() {
        _selectedCell = null; // Deselect if tapping a fixed cell
      });
      return;
    }

    setState(() {
      _selectedCell = Point(row, col);
    });
  }

  void _onNumberPadTapped(int value) {
    if (_selectedCell == null) return;

    int row = _selectedCell!.x;
    int col = _selectedCell!.y;

    setState(() {
      grid[row][col] = value;
    });

    if (value != 0 && !_isValidMove(row, col, value)) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Careful! This number conflicts with another in the same row, column, or block.'),
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    _checkWinCondition();
  }

  void _checkWinCondition() {
    if (_isGridFull() && _isGridValid()) {
      _handleWin();
    }
  }

  Future<void> _handleWin() async {
    _timer?.cancel();
    
    await ScoreService.setBestTime('sudoku_6x6', _secondsElapsed);
    await _loadBestTime();

    if (_secondsElapsed <= 180) {
      _confettiController.play();
    }

    _showWinDialog();
  }

  bool _isGridFull() {
    for (int r = 0; r < 6; r++) {
      for (int c = 0; c < 6; c++) {
        if (grid[r][c] == 0) return false;
      }
    }
    return true;
  }

  bool _isGridValid() {
    // Check rows and columns
    for (int i = 0; i < 6; i++) {
      Set<int> rowSet = {};
      Set<int> colSet = {};
      for (int j = 0; j < 6; j++) {
        rowSet.add(grid[i][j]);
        colSet.add(grid[j][i]);
      }
      if (rowSet.length != 6 || colSet.length != 6) return false;
    }

    // Check 2x3 blocks (6 blocks total)
    for (int blockRow = 0; blockRow < 6; blockRow += 2) {
      for (int blockCol = 0; blockCol < 6; blockCol += 3) {
        Set<int> blockSet = {};

        for (int r = 0; r < 2; r++) {
          for (int c = 0; c < 3; c++) {
            blockSet.add(grid[blockRow + r][blockCol + c]);
          }
        }

        if (blockSet.length != 6) return false;
      }
    }

    return true;
  }

  void _showWinDialog() {
    bool over3Mins = _secondsElapsed > 180;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          over3Mins ? 'Great perseverance!' : 'Puzzle Solved!',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B9B62))
        ),
        content: Text(
          over3Mins 
            ? 'You finished in ${_formatTime(_secondsElapsed)}.\nBetter luck next time for a faster solve!'
            : 'You successfully navigated the 6x6 matrix in ${_formatTime(_secondsElapsed)}!'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetGame();
            },
            child: const Text('Play Again', style: TextStyle(color: Color(0xFF3B9B62))),
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
        title: const Text('Sudoku (6x6)'),
        backgroundColor: const Color(0xFF3B9B62),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Time: ${_formatTime(_secondsElapsed)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _bestTime != null ? 'Streak: ${_formatTime(_bestTime!)}' : 'Streak: --:--',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3B9B62)),
                    ),
                  ],
                ),
              ),
              Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
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
                                crossAxisCount: 6,
                              ),
                          itemCount: 36, // 6x6
                          itemBuilder: (context, index) {
                            final row = index ~/ 6;
                            final col = index % 6;
                            final value = grid[row][col];
                            final isInitial = initialGrid[row][col] != 0;
                            final isSelected = _selectedCell?.x == row && _selectedCell?.y == col;

                            // Calculate border widths for 2x3 subgrids
                            final double topBorder = (row > 0 && row % 2 == 0)
                                ? 2.5
                                : 0.5;
                            final double leftBorder = (col > 0 && col % 3 == 0)
                                ? 2.5
                                : 0.5;

                            Color cellColor = isInitial ? Colors.grey[200]! : Colors.white;
                            if (isSelected) {
                              cellColor = const Color(0xFFCDECDC); // Light green highlight
                            }

                            return GestureDetector(
                              onTap: () => _onCellTapped(row, col),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cellColor,
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
                                      fontSize: 24, // Larger for 6x6
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
              
              // Number Pad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (int i = 1; i <= 6; i++)
                      _buildNumberPadButton(i.toString(), () => _onNumberPadTapped(i)),
                    _buildNumberPadButton('⌫', () => _onNumberPadTapped(0), isErase: true),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
                child: TextButton.icon(
                  onPressed: _resetGame,
                  icon: const Icon(Icons.refresh, color: AppColors.secondary),
                  label: const Text('Reset Puzzle', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                ),
              ),
              const HowToPlayCard(
                rules: [
                  Text('Fill the grid with numbers 1-6.', style: TextStyle(fontSize: 16)),
                  Text('Each row must contain unique numbers from 1 to 6.', style: TextStyle(fontSize: 16)),
                  Text('Each column must contain unique numbers from 1 to 6.', style: TextStyle(fontSize: 16)),
                  Text('Each 2x3 block must contain unique numbers from 1 to 6.', style: TextStyle(fontSize: 16)),
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

  Widget _buildNumberPadButton(String label, VoidCallback onTap, {bool isErase = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isErase ? Colors.red[100] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isErase ? Colors.red : const Color(0xFF3B9B62), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, 2),
              blurRadius: 4,
            )
          ]
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isErase ? Colors.red : const Color(0xFF3B9B62),
            ),
          ),
        ),
      ),
    );
  }
}
