import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:confetti/confetti.dart';
import 'ui_components.dart';
import 'services/score_service.dart';

const Color bgNavy = Color(0xFF0A1128);
const Color neonCyan = AppColors.primary;
const Color neonMagenta = Color(0xFFFF00FF);

class ZipGameScreen extends StatefulWidget {
  const ZipGameScreen({super.key});

  @override
  State<ZipGameScreen> createState() => _ZipGameScreenState();
}

class _ZipGameScreenState extends State<ZipGameScreen> {
  final int gridSize = 6;

  List<Point<int>> path = [];
  bool isComplete = false;

  late Map<Point<int>, int> _puzzleClues;
  int _totalLandmarks = 0;
  int _nextExpectedLandmark = 1;
  late Point<int> _startPoint;

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
    final best = await ScoreService.getBestTime('zip_6x6');
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
    List<Point<int>> solutionPath = _generateHamiltonianPath();
    
    Random rand = Random();
    int numClues = rand.nextInt(4) + 5; // 5 to 8 clues total
    
    List<int> clueIndices = [0, 35]; // Start and end always included
    while (clueIndices.length < numClues) {
      int idx = rand.nextInt(34) + 1; // 1 to 34
      if (!clueIndices.contains(idx)) {
        clueIndices.add(idx);
      }
    }
    clueIndices.sort();
    
    _puzzleClues = {};
    for (int i = 0; i < clueIndices.length; i++) {
      _puzzleClues[solutionPath[clueIndices[i]]] = i + 1;
    }
    
    _startPoint = solutionPath[0];
    _totalLandmarks = clueIndices.length;
  }

  List<Point<int>> _generateHamiltonianPath() {
    Random rand = Random();
    
    while(true) {
      List<List<bool>> visited = List.generate(gridSize, (_) => List.filled(gridSize, false));
      List<Point<int>> currentPath = [];
      
      Point<int> start = Point(rand.nextInt(gridSize), rand.nextInt(gridSize));
      
      bool dfs(Point<int> curr) {
        currentPath.add(curr);
        visited[curr.x][curr.y] = true;
        
        if (currentPath.length == gridSize * gridSize) return true;
        
        List<Point<int>> neighbors = [
          Point(curr.x - 1, curr.y),
          Point(curr.x + 1, curr.y),
          Point(curr.x, curr.y - 1),
          Point(curr.x, curr.y + 1),
        ];
        
        neighbors.shuffle(rand);
        
        // Warnsdorff's heuristic
        neighbors.sort((a, b) {
          int countA = _countUnvisited(a, visited, gridSize);
          int countB = _countUnvisited(b, visited, gridSize);
          return countA.compareTo(countB);
        });

        for (var n in neighbors) {
          if (n.x >= 0 && n.x < gridSize && n.y >= 0 && n.y < gridSize && !visited[n.x][n.y]) {
            if (dfs(n)) return true;
          }
        }
        
        currentPath.removeLast();
        visited[curr.x][curr.y] = false;
        return false;
      }
      
      if (dfs(start)) {
        return currentPath;
      }
    }
  }

  int _countUnvisited(Point<int> p, List<List<bool>> visited, int size) {
    if (p.x < 0 || p.x >= size || p.y < 0 || p.y >= size) return 999;
    int count = 0;
    List<Point<int>> neighbors = [
      Point(p.x - 1, p.y), Point(p.x + 1, p.y),
      Point(p.x, p.y - 1), Point(p.x, p.y + 1),
    ];
    for (var n in neighbors) {
      if (n.x >= 0 && n.x < size && n.y >= 0 && n.y < size && !visited[n.x][n.y]) {
        count++;
      }
    }
    return count;
  }

  void _resetGame() {
    _generatePuzzle();
    isComplete = false;
    path.clear();
    _recalculateProgress();
    _startTimer();
    setState(() {});
  }

  void _recalculateProgress() {
    _nextExpectedLandmark = 1;
    for (var p in path) {
      if (_puzzleClues.containsKey(p)) {
        if (_puzzleClues[p] == _nextExpectedLandmark) {
          _nextExpectedLandmark++;
        }
      }
    }
  }

  void _showWrongMoveAlert(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handlePan(Offset localPosition, Size boardSize) {
    if (isComplete) return;

    double cellWidth = boardSize.width / gridSize;
    double cellHeight = boardSize.height / gridSize;

    int col = (localPosition.dx / cellWidth).floor();
    int row = (localPosition.dy / cellHeight).floor();

    if (row < 0 || row >= gridSize || col < 0 || col >= gridSize) return;

    Point<int> currentPoint = Point(row, col);

    if (path.isEmpty) {
      if (currentPoint == _startPoint) {
        setState(() {
          path.add(currentPoint);
          _recalculateProgress();
        });
      }
    } else {
      setState(() {
        if (path.contains(currentPoint)) {
          // Truncate path to where the user dragged back to (Undo tracking)
          int idx = path.indexOf(currentPoint);
          if (idx < path.length - 1) {
            path = path.sublist(0, idx + 1);
            _recalculateProgress();
          }
        } else {
          Point<int> lastPoint = path.last;
          if ((lastPoint.x - currentPoint.x).abs() +
                  (lastPoint.y - currentPoint.y).abs() == 1) {
            
            // Validation: Hit a landmark out of order?
            if (_puzzleClues.containsKey(currentPoint)) {
              int clueVal = _puzzleClues[currentPoint]!;
              if (clueVal > _nextExpectedLandmark) {
                _showWrongMoveAlert('Invalid move! Find landmark $_nextExpectedLandmark first.');
                return;
              }
              // If it's < _nextExpectedLandmark, they somehow missed it or it's a bug.
              // Actually, if it's already in the path, it would have been caught above.
            }
            
            path.add(currentPoint);
            _recalculateProgress();
            _checkWinCondition();
          }
        }
      });
    }
  }

  void _checkWinCondition() {
    if (path.length == gridSize * gridSize && _nextExpectedLandmark > _totalLandmarks) {
      isComplete = true;
      _handleWin();
    }
  }

  Future<void> _handleWin() async {
    _timer?.cancel();
    
    await ScoreService.setBestTime('zip_6x6', _secondsElapsed);
    await _loadBestTime();

    if (_secondsElapsed <= 180) {
      _confettiController.play();
    }

    Future.delayed(const Duration(milliseconds: 300), _showWinDialog);
  }

  void _showWinDialog() {
    bool over3Mins = _secondsElapsed > 180;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          over3Mins ? 'Great perseverance!' : 'Puzzle Solved!',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE56B24))
        ),
        content: Text(
          over3Mins 
            ? 'You finished in ${_formatTime(_secondsElapsed)}.\nBetter luck next time for a faster solve!'
            : 'You successfully connected all landmarks in ${_formatTime(_secondsElapsed)}!'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetGame();
            },
            child: const Text('Play Again', style: TextStyle(color: Color(0xFFE56B24))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to dashboard
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE56B24),
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
      backgroundColor: bgNavy,
      appBar: AppBar(
        title: const Text(
          'ZIP',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4.0),
        ),
        backgroundColor: bgNavy,
        foregroundColor: neonCyan,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              // Header / Instructions
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Time: ${_formatTime(_secondsElapsed)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _bestTime != null ? 'Streak: ${_formatTime(_bestTime!)}' : 'Streak: --:--',
                      style: const TextStyle(
                        color: neonCyan,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              Center(
                child: AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          Size boardSize = Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );
                          return GestureDetector(
                            onPanStart: (details) =>
                                _handlePan(details.localPosition, boardSize),
                            onPanUpdate: (details) =>
                                _handlePan(details.localPosition, boardSize),
                            child: Stack(
                              children: [
                                // 1. Grid Background
                                Container(
                                  decoration: BoxDecoration(
                                    color: bgNavy,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: neonCyan.withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                  ),
                                ),

                                // 2. Custom Path Painter
                                CustomPaint(
                                  size: boardSize,
                                  painter: _PathPainter(
                                    gridSize: gridSize,
                                    path: path,
                                    clues: _puzzleClues,
                                    emptyColor: Colors.white.withValues(alpha: 0.1),
                                    startColor: neonMagenta,
                                    endColor: neonCyan,
                                  ),
                                ),

                                // 3. Foreground Texts
                                GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: gridSize,
                                      ),
                                  itemCount: gridSize * gridSize,
                                  itemBuilder: (context, index) {
                                    Point<int> p = Point(
                                      index ~/ gridSize,
                                      index % gridSize,
                                    );
                                    if (_puzzleClues.containsKey(p)) {
                                      bool visited = path.contains(p);
                                      return Center(
                                        child: Text(
                                          '${_puzzleClues[p]}',
                                          style: TextStyle(
                                            color: visited ? bgNavy : Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 20,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

              // Controls
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Row(
                  children: [
                    Expanded(
                      child: StyledButton(
                        text: 'Undo',
                        onPressed: () {
                          if (path.length > 1) {
                            setState(() {
                              path.removeLast();
                              _recalculateProgress();
                            });
                          }
                        },
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StyledButton(
                        text: 'Reset',
                        onPressed: _resetGame,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
              const HowToPlayCard(
                rules: [
                  Text('Connect all the dots in a single continuous path.', style: TextStyle(fontSize: 16)),
                  Text('You must visit the numbered landmarks in order (1, 2, 3...).', style: TextStyle(fontSize: 16)),
                  Text('The path must cover every single cell on the board.', style: TextStyle(fontSize: 16)),
                  Text('The path cannot cross itself.', style: TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 40),
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

class _PathPainter extends CustomPainter {
  final int gridSize;
  final List<Point<int>> path;
  final Map<Point<int>, int> clues;
  final Color emptyColor;
  final Color startColor;
  final Color endColor;

  _PathPainter({
    required this.gridSize,
    required this.path,
    required this.clues,
    required this.emptyColor,
    required this.startColor,
    required this.endColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellW = size.width / gridSize;
    final double cellH = size.height / gridSize;
    final double nodeRadius = (cellW < cellH ? cellW : cellH) * 0.28;

    // 1. Draw empty nodes (and special styling for clue nodes)
    final Paint emptyPaint = Paint()
      ..color = emptyColor
      ..style = PaintingStyle.fill;
    final Paint clueBorderPaint = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        Offset center = Offset(c * cellW + cellW / 2, r * cellH + cellH / 2);
        Point<int> p = Point(r, c);

        if (clues.containsKey(p)) {
          canvas.drawCircle(
            center,
            nodeRadius,
            Paint()
              ..color = const Color(0xFF0A1128)
              ..style = PaintingStyle.fill,
          );
          canvas.drawCircle(center, nodeRadius, clueBorderPaint);
        } else {
          canvas.drawCircle(center, nodeRadius * 0.4, emptyPaint);
        }
      }
    }

    // 2. Draw thick stroke path with flowing gradient
    if (path.isNotEmpty) {
      final Rect bounds = Rect.fromLTWH(0, 0, size.width, size.height);
      final Paint linePaint = Paint()
        ..shader = LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds)
        ..strokeWidth = nodeRadius * 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      Path linePath = Path();
      for (int i = 0; i < path.length; i++) {
        Offset center = Offset(
          path[i].y * cellW + cellW / 2,
          path[i].x * cellH + cellH / 2,
        );
        if (i == 0) {
          linePath.moveTo(center.dx, center.dy);
        } else {
          linePath.lineTo(center.dx, center.dy);
        }
      }
      canvas.drawPath(linePath, linePaint);

      // 3. Overdraw highlighted nodes for smoothing
      for (int i = 0; i < path.length; i++) {
        Point<int> p = path[i];
        Offset center = Offset(
          p.y * cellW + cellW / 2,
          p.x * cellH + cellH / 2,
        );

        if (clues.containsKey(p)) {
          canvas.drawCircle(
            center,
            nodeRadius * 0.9,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.fill,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) => true;
}
