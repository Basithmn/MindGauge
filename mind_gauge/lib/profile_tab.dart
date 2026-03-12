import 'package:flutter/material.dart';
import 'ui_components.dart';
import 'interests_screen.dart';
import 'professionals_screen.dart';
import 'models.dart';

class ProfileTab extends StatelessWidget {
  final UserProfile userProfile;

  const ProfileTab({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & More'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // USER INFO CARD
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 30),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${userProfile.name}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Age: ${userProfile.age} | Location: ${userProfile.location}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${userProfile.email}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.text,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const Text(
            'PERSONALIZATION',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 15),
          _ProfileCard(
            title: 'My Interests & Photos',
            icon: Icons.favorite,
            color: Colors.pink,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => InterestsScreen(userProfile: userProfile),
                ),
              );
            },
          ),
          
          const SizedBox(height: 30),
          
          const Text(
            'SUPPORT',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 15),
          _ProfileCard(
            title: 'Contact Professionals',
            icon: Icons.local_hospital,
            color: Colors.redAccent,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfessionalsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.text, size: 16),
          ],
        ),
      ),
    );
  }
}
