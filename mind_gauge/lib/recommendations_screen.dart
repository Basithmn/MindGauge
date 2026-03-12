import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import 'ui_components.dart';
import 'puzzle_game_screen.dart';
import 'zip_game_screen.dart';
import 'mini_sudoku_game_screen.dart';
import 'tango_game_screen.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  List<String> _getRecommendations(String domainName) {
    switch (domainName) {
      case 'Depression':
        return [
          'Maintain a daily routine with consistent sleep and wake times.',
          'Engage in regular physical activity, even light walking.',
          'Practice journaling to express thoughts and emotions.',
        ];
      case 'Anxiety':
        return [
          'Practice slow breathing or grounding techniques.',
          'Limit caffeine and stimulants.',
          'Break tasks into smaller, manageable steps.',
        ];
      case 'Sleep Problems':
        return [
          'Maintain a fixed sleep schedule.',
          'Avoid screens at least one hour before bedtime.',
          'Create a quiet, dark, and comfortable sleep environment.',
        ];
      default:
        return [
          'Maintain healthy daily habits.',
          'Monitor symptoms over time.',
          'Seek professional help if symptoms persist.',
        ];
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: Text("Please log in."))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('assessments')
                  .orderBy('clientTimestamp', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No recommendations available.\nComplete a symptom check-in first.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                final latestDoc = snapshot.data!.docs.first;
                final List issues = latestDoc['issues'] ?? [];

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // --- CLINICAL ADVICE SECTION ---
                    const Text(
                      'CLINICAL ADVICE',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (issues.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Text(
                          "No clinical issues detected. Stay healthy!",
                        ),
                      )
                    else
                      ...issues.map((issue) {
                        final String domain = issue['domainName'] ?? 'General';
                        final recommendations = _getRecommendations(domain);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardColor,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Advice for $domain",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...recommendations.map(
                                (rec) => Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("• "),
                                      Expanded(child: Text(rec)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    // --- RELAXATION GAMES SECTION ---
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
                      title: 'Memory Game',
                      issueNumber: '#P01',
                      date: DateFormat('EEEE, MMM d').format(DateTime.now()),
                      description:
                          'Improve focus by finding pairs of hidden symbols.',
                      buttonColor: AppColors.primary,
                      headerGradient: const LinearGradient(
                        colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
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
                        child: const Center(
                          child: Icon(
                            Icons.psychology,
                            color: AppColors.primary,
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
                      issueNumber: '#Z360',
                      date: DateFormat('EEEE, MMM d').format(DateTime.now()),
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
                        child: const Center(
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
                      issueNumber: '#S213',
                      date: DateFormat('EEEE, MMM d').format(DateTime.now()),
                      description:
                          'Good for fans of the classic Sudoku puzzles.',
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
                      issueNumber: '#T521',
                      date: DateFormat('EEEE, MMM d').format(DateTime.now()),
                      description:
                          'Use your reasoning skills to fill every cell.',
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
                                    child: Container(
                                      color: const Color(0xFFA5C5F2),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Container(color: Colors.white),
                                  ),
                                  Expanded(
                                    child: Container(
                                      color: const Color(0xFFFCAE3D),
                                    ),
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
                    const SizedBox(height: 30),

                    // --- PERSONALIZED RELIEF SECTION ---
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) return Container();
                        final userData =
                            userSnapshot.data!.data() as Map<String, dynamic>?;
                        final List<String> interests = List<String>.from(
                          userData?['interests'] ?? [],
                        );

                        if (interests.isEmpty) return Container();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 15,
                                    mainAxisSpacing: 15,
                                    childAspectRatio: 1.1,
                                  ),
                              itemCount: interests.length,
                              itemBuilder: (context, idx) {
                                final interest = interests[idx];
                                // Create a unique gradient for each card based on index
                                final gradients = [
                                  [
                                    const Color(0xFF00C8C8),
                                    const Color(0xFF007A7A),
                                  ],
                                  [
                                    const Color(0xFF6A11CB),
                                    const Color(0xFF2575FC),
                                  ],
                                  [
                                    const Color(0xFFFF5F6D),
                                    const Color(0xFFFFC371),
                                  ],
                                  [
                                    const Color(0xFF3CA55C),
                                    const Color(0xFFB5AC49),
                                  ],
                                  [
                                    const Color(0xFF1CB5E0),
                                    const Color(0xFF000851),
                                  ],
                                ];
                                final currentGradient =
                                    gradients[idx % gradients.length];

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
                                          color: currentGradient[0].withOpacity(
                                            0.3,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Top accent circle for detail
                                        Positioned(
                                          right: -20,
                                          top: -20,
                                          child: Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.1,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
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
                          ],
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
          Stack(
            children: [
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
