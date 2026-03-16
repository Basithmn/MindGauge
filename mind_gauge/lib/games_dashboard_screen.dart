import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ui_components.dart';
import 'zip_game_screen.dart';
import 'mini_sudoku_game_screen.dart';
import 'tango_game_screen.dart';
import 'color_blend_game_screen.dart';

class GamesDashboardScreen extends StatelessWidget {
  const GamesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Current date format: "Thursday, Mar 12"
    final String currentDateStr = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect over fun, daily games',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Prep your mind for the workday and compare results.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            _GameCard(
              title: 'Zip',
              issueNumber: '#360',
              date: currentDateStr,
              description: 'Use your pathfinding skills to move through the grid.',
              buttonColor: const Color(0xFFE56B24),
              headerGradient: const LinearGradient(
                colors: [Color(0xFFF6A05A), Color(0xFFF9603A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              iconWidget: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9A873),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black87, width: 2),
                ),
                child: Center(
                  child: Text(
                    'Z',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 1))],
                    ),
                  ),
                ),
              ),
              onSolve: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ZipGameScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _GameCard(
              title: 'Sudoku',
              issueNumber: '#213',
              date: currentDateStr,
              description: 'Good for fans of the classic Sudoku puzzles.',
              buttonColor: const Color(0xFF3B9B62),
              headerGradient: const LinearGradient(
                colors: [Color(0xFFE0F2E9), Color(0xFFD4ECD8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              iconWidget: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F5EA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black87, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.grid_3x3, color: Color(0xFF3B9B62), size: 36),
                ),
              ),
              onSolve: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const MiniSudokuGameScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _GameCard(
              title: 'Tango',
              issueNumber: '#521',
              date: currentDateStr,
              description: 'Use your reasoning skills to fill every cell.',
              buttonColor: const Color(0xFF4C668A),
              headerGradient: const LinearGradient(
                colors: [Color(0xFFFDE8A5), Color(0xFFA5C5F2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              iconWidget: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black87, width: 2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: Container(color: const Color(0xFFA5C5F2))),
                          Expanded(child: Container(color: Colors.white)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: Container(color: Colors.white)),
                          Expanded(child: Container(color: const Color(0xFFFCAE3D))),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              onSolve: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const TangoGameScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _GameCard(
              title: 'Color Blend',
              issueNumber: '#042',
              date: currentDateStr,
              description: 'Relax your mind by restoring the color gradient to perfect harmony.',
              buttonColor: const Color(0xFFAC5FE6),
              headerGradient: const LinearGradient(
                colors: [Color(0xFFE8D5F6), Color(0xFFCBA1ED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              iconWidget: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black87, width: 2),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A1128), Color(0xFFFF66CC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.palette, color: Colors.white, size: 28),
                ),
              ),
              onSolve: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ColorBlendGameScreen()),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

}

class _GameCard extends StatelessWidget {
  final String title;
  final String issueNumber;
  final String date;
  final String description;
  final Color buttonColor;
  final Gradient headerGradient;
  final Widget iconWidget;
  final VoidCallback onSolve;

  const _GameCard({
    required this.title,
    required this.issueNumber,
    required this.date,
    required this.description,
    required this.buttonColor,
    required this.headerGradient,
    required this.iconWidget,
    required this.onSolve,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section (Gradient background + white card overlay)
          Stack(
            children: [
              // Gradient Background Top
              Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: headerGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
              ),
              // Floating White Card Content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      iconWidget,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  issueNumber,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              date,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: onSolve,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Solve',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Description section below
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
