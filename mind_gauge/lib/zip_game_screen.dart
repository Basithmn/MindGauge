import 'package:flutter/material.dart';
import 'ui_components.dart';

class ZipGameScreen extends StatefulWidget {
  const ZipGameScreen({super.key});

  @override
  State<ZipGameScreen> createState() => _ZipGameScreenState();
}

class _ZipGameScreenState extends State<ZipGameScreen> {
  final int gridSize = 5;
  
  // Game puzzle definition: Endpoints to connect
  final Map<Color, List<Offset>> endpoints = {
    Colors.red: [const Offset(0, 0), const Offset(4, 4)],
    Colors.blue: [const Offset(0, 4), const Offset(4, 0)],
    Colors.green: [const Offset(2, 0), const Offset(2, 4)],
    Colors.orange: [const Offset(0, 2), const Offset(4, 2)],
  };

  List<Point<int>> path = [];
  bool isComplete = false;

  late Map<Point<int>, int> _puzzleClues;

  // A collection of different 5x5 Hamiltonian paths (snaking, spirals, etc.) 
  // to provide random layouts upon each game reset.
  final List<Map<Point<int>, int>> _puzzleLevels = [
    {
      Point(4, 0): 1, Point(4, 4): 5, Point(0, 4): 9, Point(0, 0): 13,
      Point(3, 0): 16, Point(3, 3): 19, Point(1, 1): 25,
    },
    { // Horizontal Snake
      Point(0, 0): 1, Point(0, 4): 5, Point(1, 4): 6, Point(1, 0): 10,
      Point(2, 0): 11, Point(2, 4): 15, Point(3, 4): 16, Point(3, 0): 20,
      Point(4, 0): 21, Point(4, 4): 25,
    },
    { // Inward Spiral
      Point(0, 0): 1, Point(0, 4): 5, Point(4, 4): 9, Point(4, 0): 13,
      Point(1, 0): 16, Point(1, 3): 19, Point(3, 3): 21, Point(3, 1): 23,
      Point(2, 2): 25,
    },
    { // Vertical Snake
      Point(0, 0): 1, Point(4, 0): 5, Point(4, 1): 6, Point(0, 1): 10,
      Point(0, 2): 11, Point(4, 2): 15, Point(4, 3): 16, Point(0, 3): 20,
      Point(0, 4): 21, Point(4, 4): 25,
    },
    { // Outward Spiral
      Point(2, 2): 1, Point(1, 1): 5, Point(3, 3): 9, Point(0, 4): 13,
      Point(0, 0): 17, Point(4, 0): 21, Point(4, 4): 25,
    }
  ];

  @override
  void initState() {
    super.initState();
    _puzzleClues = _puzzleLevels[0]; // init default
    _resetGame();
  }

  void _resetGame() {
    grid = List.generate(gridSize, (_) => List.filled(gridSize, null));
    // Place endpoints on the grid
    for (var entry in endpoints.entries) {
      grid[entry.value[0].dy.toInt()][entry.value[0].dx.toInt()] = entry.key;
      grid[entry.value[1].dy.toInt()][entry.value[1].dx.toInt()] = entry.key;
    }
    activeColor = null;
    isComplete = false;
    setState(() {});
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
      if (_puzzleClues[currentPoint] == 1) {
        setState(() {
          path.add(currentPoint);
        });
      }
    } else {
      setState(() {
        if (path.contains(currentPoint)) {
          // Truncate path to where the user dragged back to (Undo tracking)
          int idx = path.indexOf(currentPoint);
          if (idx < path.length - 1) {
            path = path.sublist(0, idx + 1);
          }
        } 
        else {
          Point<int> lastPoint = path.last;
          if ((lastPoint.x - currentPoint.x).abs() + (lastPoint.y - currentPoint.y).abs() == 1) {
            // Constraints: If this cell has a clue, does it match the coming length?
            if (_puzzleClues.containsKey(currentPoint) && _puzzleClues[currentPoint] != path.length + 1) {
              return; // Block adding
            }
            path.add(currentPoint);
            _checkWinCondition();
          }
        }
      });
    }
  }

  void _checkWinCondition() {
    if (path.length == gridSize * gridSize) {
      isComplete = true;
      Future.delayed(const Duration(milliseconds: 300), _showWinDialog);
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Puzzle Solved!'),
        content: const Text('You successfully navigated the grid.'),
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
        title: const Text('ZIP', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4.0)),
        backgroundColor: bgNavy,
        foregroundColor: neonCyan,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header / Instructions
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: const Text(
              "Connect the dots in order to fill every cell.",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
          
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      Size boardSize = Size(constraints.maxWidth, constraints.maxHeight);
                      return GestureDetector(
                        onPanStart: (details) => _handlePan(details.localPosition, boardSize),
                        onPanUpdate: (details) => _handlePan(details.localPosition, boardSize),
                        child: Stack(
                          children: [
                            // 1. Grid Background
                            Container(
                              decoration: BoxDecoration(
                                color: bgNavy,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: neonCyan.withValues(alpha: 0.3), width: 2),
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
                                pathColor: neonCyan,
                                startColor: neonMagenta,
                              ),
                            ),
                            
                            // 3. Foreground Texts
                            GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridSize,
                              ),
                              itemCount: gridSize * gridSize,
                              itemBuilder: (context, index) {
                                Point<int> p = Point(index ~/ gridSize, index % gridSize);
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
  final Color pathColor;
  final Color startColor;

  _PathPainter({
    required this.gridSize,
    required this.path,
    required this.clues,
    required this.emptyColor,
    required this.pathColor,
    required this.startColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellW = size.width / gridSize;
    final double cellH = size.height / gridSize;
    final double nodeRadius = (cellW < cellH ? cellW : cellH) * 0.28;

    // 1. Draw empty nodes (and special styling for clue nodes)
    final Paint emptyPaint = Paint()..color = emptyColor..style = PaintingStyle.fill;
    final Paint clueBorderPaint = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        Offset center = Offset(c * cellW + cellW / 2, r * cellH + cellH / 2);
        Point<int> p = Point(r, c);
        
        if (clues.containsKey(p)) {
          // Draw bordered circle for unvisited clue nodes
          canvas.drawCircle(center, nodeRadius, Paint()..color = const Color(0xFF0A1128)..style = PaintingStyle.fill);
          canvas.drawCircle(center, nodeRadius, clueBorderPaint);
        } else {
          // Normal empty connector node
          canvas.drawCircle(center, nodeRadius * 0.4, emptyPaint);
        }
      }
    }

    // 2. Draw thick stroke path
    if (path.isNotEmpty) {
      final Paint linePaint = Paint()
        ..color = pathColor
        ..strokeWidth = nodeRadius * 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      Path linePath = Path();
      for (int i = 0; i < path.length; i++) {
        Offset center = Offset(path[i].y * cellW + cellW / 2, path[i].x * cellH + cellH / 2);
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
        Offset center = Offset(p.y * cellW + cellW / 2, p.x * cellH + cellH / 2);
        
        // Emphasize the starting node with a different color (Magenta)
        if (clues[p] == 1) {
          canvas.drawCircle(center, nodeRadius * 0.9, Paint()..color = startColor..style = PaintingStyle.fill);
        } 
        else if (clues.containsKey(p)) {
           // Emphasize other matched clues (White)
           canvas.drawCircle(center, nodeRadius * 0.9, Paint()..color = Colors.white..style = PaintingStyle.fill);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) => true;
}

