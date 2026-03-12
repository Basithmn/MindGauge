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

  late List<List<Color?>> grid;
  Color? activeColor;
  bool isComplete = false;

  @override
  void initState() {
    super.initState();
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

  void _handleInteraction(int row, int col) {
    if (isComplete) return;

    final cellColor = grid[row][col];
    
    // If tapping an endpoint, set it as the active color to draw
    bool isEndpoint = false;
    Color? endpointColor;
    endpoints.forEach((color, positions) {
      if (positions.contains(Offset(col.toDouble(), row.toDouble()))) {
        isEndpoint = true;
        endpointColor = color;
      }
    });

    setState(() {
      if (isEndpoint) {
        // Start dragging from this endpoint
        activeColor = endpointColor;
        // Optionally clear existing path for this color, except endpoints
        _clearPath(activeColor!);
      } else if (activeColor != null) {
        // If we are dragging/tapping an empty cell with an active color, color it
        grid[row][col] = activeColor;
      }
      
      _checkWinCondition();
    });
  }
  
  void _clearPath(Color color) {
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (grid[r][c] == color) {
          bool isEndpoint = false;
          if (endpoints[color]!.contains(Offset(c.toDouble(), r.toDouble()))) {
             isEndpoint = true;
          }
          if (!isEndpoint) {
            grid[r][c] = null;
          }
        }
      }
    }
  }

  void _checkWinCondition() {
    // A simplified win check for demonstration
    // Ensure all endpoints are connected (simplified: just check if grid is full and no nulls)
    bool allFilled = true;
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (grid[r][c] == null) {
          allFilled = false;
          break;
        }
      }
    }
    if (allFilled) {
      isComplete = true;
      _showWinDialog();
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
      appBar: AppBar(
        title: const Text('Zip'),
        backgroundColor: const Color(0xFFE56B24),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Connect matching colored dots. Fill the entire grid to win.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onPanUpdate: (details) {
                  // Basic rudimentary drag-to-draw
                  RenderBox box = context.findRenderObject() as RenderBox;
                  // Calculating exact cell from drag is complicated here due to padding, 
                  // using a simplified approach or just relying on taps for now.
                },
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridSize,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: gridSize * gridSize,
                  itemBuilder: (context, index) {
                    final row = index ~/ gridSize;
                    final col = index % gridSize;
                    final cellColor = grid[row][col];

                    bool isEndpoint = false;
                    endpoints.forEach((c, pos) {
                      if (pos.contains(Offset(col.toDouble(), row.toDouble()))) {
                        isEndpoint = true;
                      }
                    });

                    return GestureDetector(
                      onPanDown: (_) => _handleInteraction(row, col),
                      onPanUpdate: (_) => _handleInteraction(row, col),
                      onTap: () => _handleInteraction(row, col),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cellColor?.withOpacity(isEndpoint ? 1.0 : 0.6) ?? Colors.grey[200],
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: isEndpoint
                            ? Center(
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
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
