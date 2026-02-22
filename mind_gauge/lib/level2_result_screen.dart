import 'package:flutter/material.dart';
import 'services.dart';
import 'ui_components.dart';
import 'dashboard_screen.dart';
import 'risk_trends_screen.dart';
import 'professionals_screen.dart';
import 'models.dart';

class Level2ResultScreen extends StatefulWidget {
  final String domainName;
  final String diagnosis;
  final List<int> scores;
  final UserProfile userProfile;

  const Level2ResultScreen({
    super.key,
    required this.domainName,
    required this.diagnosis,
    required this.scores,
    required this.userProfile,
  });

  @override
  State<Level2ResultScreen> createState() => _Level2ResultScreenState();
}

class _Level2ResultScreenState extends State<Level2ResultScreen> {
  final FirebaseUserService _userService = FirebaseUserService();
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _saveResult();
  }

  Future<void> _saveResult() async {
    try {
      await _userService.saveLevel2Result(
        userId: widget.userProfile.userId,
        domainName: widget.domainName,
        diagnosis: widget.diagnosis,
        scores: widget.scores,
      );
      if (mounted) {
        setState(() {
          _isSaved = true;
        });
      }
    } catch (e) {
      print("Error saving Level 2 result: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Result'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Force use of shortcuts
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 20),
            Text(
              '${widget.domainName} Level 2 Result',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Clinical Severity Index:",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.diagnosis,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Divider(height: 30),
                  const Text(
                    "This Level 2 measure uses a comprehensive clinical scale. It confirms the preliminary screener findings with higher precision and diagnostic confidence.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            if (_isSaved)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    "Saved to your profile history",
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            const SizedBox(height: 60),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              "NEXT STEPS & SHORTCUTS",
              style: TextStyle(
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            _ShortcutItem(
              icon: Icons.dashboard_outlined,
              label: "Go to Dashboard",
              onTap: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) =>
                      MainDashboard(userProfile: widget.userProfile),
                ),
                (route) => false,
              ),
            ),
            _ShortcutItem(
              icon: Icons.trending_up,
              label: "View Risk Trends",
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RiskTrendsScreen()),
              ),
            ),
            _ShortcutItem(
              icon: Icons.medical_services_outlined,
              label: "Get Professional Help",
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfessionalsScreen()),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ShortcutItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShortcutItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: AppColors.secondary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        tileColor: Colors.white,
      ),
    );
  }
}
