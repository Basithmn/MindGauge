import 'package:flutter/material.dart';
import 'models.dart';
import 'services.dart';
import 'ui_components.dart';
import 'interests_section.dart';
import 'photos_section.dart';


class InterestsScreen extends StatelessWidget {
  final UserProfile userProfile;

  const InterestsScreen({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Interests'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            InterestsSection(
              initialInterests: userProfile.interests,
              onInterestsChanged: (newInterests) async {
                await FirebaseUserService().saveInterests(
                  userProfile.userId,
                  newInterests,
                );
                // Update local profile state
                userProfile.interests.clear();
                userProfile.interests.addAll(newInterests);
              },
            ),
            const SizedBox(height: 20),
            PhotosSection(
              initialPhotos: userProfile.photos,
              onPhotosChanged: (newPhotos) async {
                await FirebaseUserService().savePhotos(
                  userProfile.userId,
                  newPhotos,
                );
                // Update local profile state
                userProfile.photos.clear();
                userProfile.photos.addAll(newPhotos);
              },
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              "Engaging in your hobbies can significantly improve your mood and mental well-being.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: AppColors.text,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
