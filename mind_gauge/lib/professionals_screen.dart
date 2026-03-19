import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:url_launcher/url_launcher.dart';

import 'models.dart';
import 'ui_components.dart';
class ProfessionalsScreen extends StatelessWidget {
  const ProfessionalsScreen({super.key});

  // Helper function to get location from the user profile in Firestore
  Future<String> _fetchLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "All";
    
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data()?['location'] ?? "All";
  }

  // Helper function to launch the phone dialer
  Future<void> _launchCaller(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (!await launchUrl(url)) {
      // ignore: avoid_print
      print("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _fetchLocation(),
      builder: (context, locationSnapshot) {
        // Show a loading spinner while we find the user's city
        if (locationSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final userLoc = locationSnapshot.data ?? "All";

        // Once we have the location, we build the actual screen
        return Scaffold(
          appBar: AppBar(
            title: Text(userLoc == "All" ? 'Professionals' : 'Doctors in $userLoc'),
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('professionals')
                .where('location', isEqualTo: userLoc)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];

              // Handle "No Results" for specific location
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text("No professionals found in $userLoc"),
                      const SizedBox(height: 20),
                      // Fallback button to see everyone
                      StyledButton(
                        text: "Show All Doctors",
                        onPressed: () {
                           // Navigate to the same screen but bypass location check
                           Navigator.of(context).pushReplacement(
                             MaterialPageRoute(builder: (_) => const ProfessionalsScreenAll())
                           );
                        },
                      )
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final prof = Professional.fromFirestore(docs[index]);
                  return _infoTile(
                    title: prof.name,
                    subtitle: "${prof.specialty}\n${prof.hospital}",
                    trailing: prof.phone,
                    onPhonePressed: prof.phone != null ? () => _launchCaller(prof.phone!) : null,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _infoTile({required String title, required String subtitle, String? trailing, VoidCallback? onPhonePressed}) {
    return Card(
      color: AppColors.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: trailing != null 
          ? IconButton(
              icon: const Icon(Icons.phone, color: AppColors.secondary),
              onPressed: onPhonePressed,
            ) 
          : null,
      ),
    );
  }
}

class ProfessionalsScreenAll extends StatelessWidget {
  const ProfessionalsScreenAll({super.key});

  // Helper function to launch the phone dialer
  Future<void> _launchCaller(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (!await launchUrl(url)) {
      // ignore: avoid_print
      print("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Professionals"),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('professionals').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final docs = snapshot.data?.docs ?? [];
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final prof = Professional.fromFirestore(docs[index]);
              // Using a consistent style across the app
              return Card(
                color: AppColors.cardColor,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(prof.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${prof.specialty}\nLocation: ${prof.location}"), // Now this works!
                  isThreeLine: true,
                  trailing: prof.phone != null 
                    ? IconButton(
                        icon: const Icon(Icons.phone, color: AppColors.secondary),
                        onPressed: () => _launchCaller(prof.phone!),
                      )
                    : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}