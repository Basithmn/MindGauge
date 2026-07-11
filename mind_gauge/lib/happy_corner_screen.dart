import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ui_components.dart';
import 'puzzle_game_screen.dart';
import 'zip_game_screen.dart';
import 'mini_sudoku_game_screen.dart';
import 'tango_game_screen.dart';
import 'photos_section.dart';
import 'services.dart';

class HappyCornerScreen extends StatelessWidget {
  const HappyCornerScreen({super.key});

  Future<void> _launchYoutube(String interest) async {
    String query = interest;
    switch (interest) {
      case 'Reading books':
        query = 'book recommendations 2026';
        break;
      case 'Listening to music':
        query = 'relaxing music for stress relief';
        break;
      case 'Watching movies / web series':
        query = 'best web series 2025 trailer';
        break;
      case 'Playing video games':
        query = 'top video games 2025 gameplay';
        break;
      case 'Playing sports (cricket, football, badminton)':
        query = 'sports match highlights';
        break;
      case 'Drawing / sketching':
        query = 'easy drawing tutorials';
        break;
      case 'Dancing':
        query = 'dance choreography for beginners';
        break;
      case 'Singing':
        query = 'popular songs karaoke with lyrics';
        break;
      case 'Traveling':
        query = 'top travel destinations 2026';
        break;
      case 'Photography':
        query = 'photography tips for beginners';
        break;
      case 'Cooking / baking':
        query = 'quick and easy recipes';
        break;
      case 'Gardening':
        query = 'gardening tips for home';
        break;
      case 'Cycling':
        query = 'best cycling routes and tips';
        break;
      case 'Swimming':
        query = 'swimming techniques for beginners';
        break;
      case 'Writing (stories, poems, journaling)':
        query = 'creative writing prompts';
        break;
      case 'Learning new skills online':
        query = 'top skills to learn in 2026';
        break;
      case 'Browsing the internet':
        query = 'interesting websites to browse';
        break;
      case 'Social media content creation':
        query = 'content creation tips for beginners';
        break;
      case 'Fitness / gym workouts':
        query = 'home workout for beginners';
        break;
      case 'Yoga':
        query = 'gentle yoga for stress relief';
        break;
    }

    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse(
      'https://www.youtube.com/results?search_query=$encodedQuery',
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildGameFlashcard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.primary.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            Icon(icon, color: AppColors.primary, size: 32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String currentDateStr = DateFormat(
      'EEEE, MMM d',
    ).format(DateTime.now());

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Moments'),
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text("Please log in.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moments'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text("No user data found."));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final List<String> interests = List<String>.from(
            userData['interests'] ?? [],
          );
          final List<String> photos = List<String>.from(
            userData['photos'] ?? [],
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- 1. PHOTOS SECTION ---
              PhotosSection(initialPhotos: photos, isReadOnly: true),

              const SizedBox(height: 30),

              // --- 2. PERSONALIZED RELIEF SECTION (INTERESTS) ---
              if (interests.isNotEmpty) ...[
                const Text(
                  'PERSONALIZED RELIEF',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Watch videos related to your interests to feel better instantly.",
                  style: TextStyle(
                    color: AppColors.text,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 15),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: interests.length,
                  itemBuilder: (context, idx) {
                    final interest = interests[idx];
                    final gradients = [
                      [const Color(0xFF00C8C8), const Color(0xFF007A7A)],
                      [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
                      [const Color(0xFFFF5F6D), const Color(0xFFFFC371)],
                      [const Color(0xFF3CA55C), const Color(0xFFB5AC49)],
                      [const Color(0xFF1CB5E0), const Color(0xFF000851)],
                    ];
                    final currentGradient = gradients[idx % gradients.length];

                    return InkWell(
                      onTap: () => _launchYoutube(interest),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: currentGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: currentGradient[0].withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -20,
                              top: -20,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    interest,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],

              // --- 3. RELAXATION GAMES SECTION ---
              const Text(
                'RELAXATION GAMES',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 15),
              _GameCard(
                title: 'Matching Cards',
                issueNumber: '',
                date: currentDateStr,
                description:
                    'A relaxing puzzle to ease your mind and find focus.',
                buttonColor: const Color(0xFF6B4C9A),
                headerGradient: const LinearGradient(
                  colors: [Color(0xFF9D84B7), Color(0xFF6B4C9A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                iconWidget: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4D9F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black87, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.extension,
                      color: Color(0xFF6B4C9A),
                      size: 36,
                    ),
                  ),
                ),
                onSolve: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PuzzleGameScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _GameCard(
                title: 'Zip',
                issueNumber: '',
                date: currentDateStr,
                description:
                    'Use your pathfinding skills to move through the grid.',
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
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 2,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                onSolve: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ZipGameScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _GameCard(
                title: 'Mini Sudoku',
                issueNumber: '',
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
                    child: Icon(
                      Icons.grid_3x3,
                      color: Color(0xFF3B9B62),
                      size: 36,
                    ),
                  ),
                ),
                onSolve: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MiniSudokuGameScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _GameCard(
                title: 'Tango',
                issueNumber: '',
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
                            Expanded(
                              child: Container(color: const Color(0xFFA5C5F2)),
                            ),
                            Expanded(child: Container(color: Colors.white)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(child: Container(color: Colors.white)),
                            Expanded(
                              child: Container(color: const Color(0xFFFCAE3D)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                onSolve: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TangoGameScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          );
        },
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                                    fontSize: 15,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Solve',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
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
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
