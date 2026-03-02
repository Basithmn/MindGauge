import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ui_components.dart';

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
        query = 'book recommendations 2024';
        break;
      case 'Listening to music':
        query = 'relaxing music for stress relief';
        break;
      case 'Watching movies / web series':
        query = 'best web series 2024 trailer';
        break;
      case 'Playing video games':
        query = 'top video games 2024 gameplay';
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
        query = 'top travel destinations 2024';
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
        query = 'top skills to learn in 2024';
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
                                    childAspectRatio: 1.4,
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
