import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:confetti/confetti.dart';
import 'ui_components.dart';
import 'services/score_service.dart';

class TangoGameScreen extends StatefulWidget {
  const TangoGameScreen({super.key});

  @override
  State<TangoGameScreen> createState() => _TangoGameScreenState();
}

class _TangoGameScreenState extends State<TangoGameScreen> {
  final int gridSize = 6;
  
  late List<List<int>> initialGrid;
  late List<List<int>> grid;
  late List<List<String>> hConstraints; // 6x5
  late List<List<String>> vConstraints; // 5x6

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
    final best = await ScoreService.getBestTime('tango');
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

  void _generatePuzzle() {
    List<List<int>> solvedGrid = List.generate(gridSize, (_) => List.filled(gridSize, 0));
    Random rand = Random();
    
    bool isValidForGen(int r, int c, int val) {
      solvedGrid[r][c] = val;
      // Consec row
      for(int i=0; i<gridSize-2; i++) {
        if(solvedGrid[r][i]!=0 && solvedGrid[r][i]==solvedGrid[r][i+1] && solvedGrid[r][i]==solvedGrid[r][i+2]) { solvedGrid[r][c]=0; return false; }
      }
      // Consec col
      for(int i=0; i<gridSize-2; i++) {
        if(solvedGrid[i][c]!=0 && solvedGrid[i][c]==solvedGrid[i+1][c] && solvedGrid[i][c]==solvedGrid[i+2][c]) { solvedGrid[r][c]=0; return false; }
      }
      // Count row
      int c1=0, c2=0;
      for(int i=0; i<gridSize; i++) {
        if(solvedGrid[r][i]==1) c1++;
        if(solvedGrid[r][i]==2) c2++;
      }
      if(c1>3 || c2>3) { solvedGrid[r][c]=0; return false; }
      
      // Count col
      c1=0; c2=0;
      for(int i=0; i<gridSize; i++) {
        if(solvedGrid[i][c]==1) c1++;
        if(solvedGrid[i][c]==2) c2++;
      }
      if(c1>3 || c2>3) { solvedGrid[r][c]=0; return false; }
      
      // Unique rows
      if(c == gridSize-1) {
        for(int i=0; i<r; i++) {
          bool same = true;
          for(int j=0; j<gridSize; j++) if(solvedGrid[i][j]!=solvedGrid[r][j]) same = false;
          if(same) { solvedGrid[r][c]=0; return false; }
        }
      }
      // Unique cols
      if(r == gridSize-1) {
        for(int i=0; i<c; i++) {
          bool same = true;
          for(int j=0; j<gridSize; j++) if(solvedGrid[j][i]!=solvedGrid[j][c]) same = false;
          if(same) { solvedGrid[r][c]=0; return false; }
        }
      }
      
      solvedGrid[r][c]=0;
      return true;
    }
    
    bool solve(int r, int c) {
      if(r == gridSize) return true;
      int nextR = c == gridSize-1 ? r + 1 : r;
      int nextC = c == gridSize-1 ? 0 : c + 1;
      
      List<int> vals = [1, 2];
      vals.shuffle(rand);
      for(int v in vals) {
        if(isValidForGen(r, c, v)) {
          solvedGrid[r][c] = v;
          if(solve(nextR, nextC)) return true;
          solvedGrid[r][c] = 0;
        }
      }
      return false;
    }
    
    solve(0, 0);

    hConstraints = List.generate(gridSize, (_) => List.filled(gridSize-1, ''));
    vConstraints = List.generate(gridSize-1, (_) => List.filled(gridSize, ''));
    
    // Place ~14 constraints
    int placed = 0;
    while(placed < 14) {
      if(rand.nextBool()) { // horizontal
        int r = rand.nextInt(gridSize);
        int c = rand.nextInt(gridSize-1);
        if(hConstraints[r][c] == '') {
          hConstraints[r][c] = (solvedGrid[r][c] == solvedGrid[r][c+1]) ? '=' : 'x';
          placed++;
        }
      } else { // vertical
        int r = rand.nextInt(gridSize-1);
        int c = rand.nextInt(gridSize);
        if(vConstraints[r][c] == '') {
          vConstraints[r][c] = (solvedGrid[r][c] == solvedGrid[r+1][c]) ? '=' : 'x';
          placed++;
        }
      }
    }

    initialGrid = List.generate(gridSize, (_) => List.filled(gridSize, 0));
    // Keep ~8 cells
    int kept = 0;
    while(kept < 8) {
      int r = rand.nextInt(gridSize);
      int c = rand.nextInt(gridSize);
      if(initialGrid[r][c] == 0) {
        initialGrid[r][c] = solvedGrid[r][c];
        kept++;
      }
    }
  }

  void _resetGame() {
    _generatePuzzle();
    grid = List.generate(gridSize, (r) => List.from(initialGrid[r]));
    _startTimer();
    setState(() {});
  }

  bool _isValidLocalMove(int row, int col, int value) {
    int oldVal = grid[row][col];
    grid[row][col] = value;
    
    bool isValid = true;
    
    // 1. Check max 3 of the same color
    int rowCount = 0;
    int colCount = 0;
    for (int i = 0; i < gridSize; i++) {
      if (grid[row][i] == value) rowCount++;
      if (grid[i][col] == value) colCount++;
    }
    if (rowCount > 3 || colCount > 3) isValid = false;

    // 2. Check no 3 consecutive
    if (isValid) {
      for (int i = 0; i < gridSize - 2; i++) {
        if (grid[row][i] != 0 && grid[row][i] == grid[row][i+1] && grid[row][i] == grid[row][i+2]) isValid = false;
        if (grid[i][col] != 0 && grid[i][col] == grid[i+1][col] && grid[i][col] == grid[i+2][col]) isValid = false;
      }
    }

    // 3. Check constraints
    if (isValid) {
      // Left constraint
      if (col > 0 && hConstraints[row][col-1] != '' && grid[row][col-1] != 0) {
        if (hConstraints[row][col-1] == '=' && grid[row][col-1] != value) isValid = false;
        if (hConstraints[row][col-1] == 'x' && grid[row][col-1] == value) isValid = false;
      }
      // Right constraint
      if (col < gridSize-1 && hConstraints[row][col] != '' && grid[row][col+1] != 0) {
        if (hConstraints[row][col] == '=' && grid[row][col+1] != value) isValid = false;
        if (hConstraints[row][col] == 'x' && grid[row][col+1] == value) isValid = false;
      }
      // Top constraint
      if (row > 0 && vConstraints[row-1][col] != '' && grid[row-1][col] != 0) {
        if (vConstraints[row-1][col] == '=' && grid[row-1][col] != value) isValid = false;
        if (vConstraints[row-1][col] == 'x' && grid[row-1][col] == value) isValid = false;
      }
      // Bottom constraint
      if (row < gridSize-1 && vConstraints[row][col] != '' && grid[row+1][col] != 0) {
        if (vConstraints[row][col] == '=' && grid[row+1][col] != value) isValid = false;
        if (vConstraints[row][col] == 'x' && grid[row+1][col] == value) isValid = false;
      }
    }

    grid[row][col] = oldVal;
    return isValid;
  }

  void _onCellTapped(int row, int col) {
    if (initialGrid[row][col] != 0) return;

    int nextValue = (grid[row][col] + 1) % 3;
    
    if (nextValue != 0 && !_isValidLocalMove(row, col, nextValue)) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid move! Check the rules and =/x constraints.'),
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() {
      grid[row][col] = nextValue;
    });

    _checkWinCondition();
  }

  void _checkWinCondition() {
    if (_isGridFull() && _isGridValid()) {
      _handleWin();
    }
  }

  Future<void> _handleWin() async {
    _timer?.cancel();
    
    await ScoreService.setBestTime('tango', _secondsElapsed);
    await _loadBestTime();

    if (_secondsElapsed <= 180) {
      _confettiController.play();
    }

    _showWinDialog();
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
        if (grid[i][j] != 0 && grid[i][j] == grid[i][j+1] && grid[i][j] == grid[i][j+2]) return false;
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

    // 4. Check constraints
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize-1; c++) {
        if (hConstraints[r][c] == '=' && grid[r][c] != grid[r][c+1]) return false;
        if (hConstraints[r][c] == 'x' && grid[r][c] == grid[r][c+1]) return false;
      }
    }
    for (int r = 0; r < gridSize-1; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (vConstraints[r][c] == '=' && grid[r][c] != grid[r+1][c]) return false;
        if (vConstraints[r][c] == 'x' && grid[r][c] == grid[r+1][c]) return false;
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
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4C668A))
        ),
        content: Text(
          over3Mins 
            ? 'You finished in ${_formatTime(_secondsElapsed)}.\nBetter luck next time for a faster solve!'
            : 'You successfully deduced the patterns in ${_formatTime(_secondsElapsed)}!'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetGame();
            },
            child: const Text('Play Again', style: TextStyle(color: Color(0xFF4C668A))),
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
      backgroundColor: const Color(0xFFF9FAFB), // Soft background
      appBar: AppBar(
        title: const Text('Tango'),
        backgroundColor: const Color(0xFF4C668A),
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4C668A)),
                    ),
                  ],
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        children: [
                          // Cells
                          GridView.builder(
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

                              Widget? cellContent;
                              if (value == 1) {
                                cellContent = const Icon(Icons.nightlight_round, color: Color(0xFF3B82F6), size: 32); // Blue Moon
                              } else if (value == 2) {
                                cellContent = const Icon(Icons.wb_sunny, color: Color(0xFFF59E0B), size: 32); // Orange Sun
                              }

                              return GestureDetector(
                                onTap: () => _onCellTapped(row, col),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isInitial ? const Color(0xFFE5E7EB) : Colors.white,
                                    border: Border.all(color: Colors.grey.shade400, width: 0.5),
                                  ),
                                  child: Center(
                                    child: cellContent,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Constraints Overlay
                          IgnorePointer(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return CustomPaint(
                                  size: Size(constraints.maxWidth, constraints.maxHeight),
                                  painter: _ConstraintPainter(
                                    gridSize: gridSize,
                                    hConstraints: hConstraints,
                                    vConstraints: vConstraints,
                                  ),
                                );
                              },
                            ),
                          ),
                          // Outer Border
                          IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black87, width: 3),
                              ),
                            ),
                          ),
                        ],
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
              const HowToPlayCard(
                rules: [
                  Text('Fill the grid so that each cell contains either a Sun ☀️ or a Moon 🌙.', style: TextStyle(fontSize: 16)),
                  Text('No more than 2 Suns or Moons may be next to each other, either vertically or horizontally.', style: TextStyle(fontSize: 16)),
                  Text('Each row (and column) must contain the same number of Suns and Moons.', style: TextStyle(fontSize: 16)),
                  Text('Cells separated by an = sign must be of the same type.', style: TextStyle(fontSize: 16)),
                  Text('Cells separated by an x sign must be of the opposite type.', style: TextStyle(fontSize: 16)),
                  Text('Each puzzle has one right answer and can be solved via deduction.', style: TextStyle(fontSize: 16)),
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

class _ConstraintPainter extends CustomPainter {
  final int gridSize;
  final List<List<String>> hConstraints;
  final List<List<String>> vConstraints;

  _ConstraintPainter({
    required this.gridSize,
    required this.hConstraints,
    required this.vConstraints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellW = size.width / gridSize;
    final double cellH = size.height / gridSize;

    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    void drawConstraint(String text, Offset center) {
      if (text == '') return;
      
      // Draw background circle to hide the border line
      canvas.drawCircle(
        center, 
        10, 
        Paint()..color = const Color(0xFFF9FAFB)..style = PaintingStyle.fill
      );

      textPainter.text = TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
      );
    }

    // Draw horizontal constraints (between columns)
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize - 1; c++) {
        Offset center = Offset((c + 1) * cellW, (r + 0.5) * cellH);
        drawConstraint(hConstraints[r][c], center);
      }
    }

    // Draw vertical constraints (between rows)
    for (int r = 0; r < gridSize - 1; r++) {
      for (int c = 0; c < gridSize; c++) {
        Offset center = Offset((c + 0.5) * cellW, (r + 1) * cellH);
        drawConstraint(vConstraints[r][c], center);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConstraintPainter oldDelegate) => true;
}
