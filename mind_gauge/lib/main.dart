import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models.dart';
import 'ui_components.dart';
import 'services.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- CONFIGURATION ---
// Global instance of FirebaseAuth
final FirebaseAuth _auth = FirebaseAuth.instance;
// const String _apiBaseUrl = 'http://172.16.7.248:5000'; // Define API URL if needed later

// --- SERVICE LAYER AND DATA STRUCTURES ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MindGaugeApp());
}

class MindGaugeApp extends StatelessWidget {
  const MindGaugeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MindGauge',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// 1. SPLASH SCREEN
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
void initState() {
  super.initState();
  _navigate();
}

Future<void> _navigate() async {
  await Future.delayed(const Duration(seconds: 3));

  if (!mounted) return;

  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    return;
  }

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (!doc.exists) {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    return;
  }

  final profile = UserProfile.fromDatabase(doc.data()!, user);

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => MainDashboard(userProfile: profile),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'mind_gauge_logo.jpeg',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.psychology_outlined,
                  size: 150,
                  color: AppColors.primary,
                );
              },
            ),
            const SizedBox(height: 30),
            const Text('MINDGAUGE', style: kTitleStyle),
            const SizedBox(height: 10),
            const Text('Measure your Mental Health Status', style: kSubtitleStyle),
          ],
        ),
      ),
    );
  }
}
// 2. AUTH SCREEN (REGISTER/LOGIN CHOICE)
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.psychology_outlined, size: 100, color: AppColors.primary),
              const SizedBox(height: 20),
              const Text('MINDGAUGE', style: kTitleStyle),
              const SizedBox(height: 5),
              const Text('Measure your Mental Health Status', style: kSubtitleStyle),
              const Spacer(),
              StyledButton(
                text: 'REGISTER',
                onPressed: () => _navigateToRegister(context),
              ),
              const SizedBox(height: 25),
              StyledButton(
                text: 'LOGIN',
                onPressed: () => _navigateToLogin(context),
                color: AppColors.secondary,
                shadowColor: AppColors.secondary.withOpacity(0.7),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
// 4. REGISTER SCREEN
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isLoading = false;

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    setState(() { _isLoading = true; });

    final int? age = int.tryParse(_ageController.text);
    
    // Safety check for age (validation should handle this, but for try-catch clarity)
    if (age == null) {
       setState(() { _isLoading = false; });
       if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Registration failed: Invalid age provided.')),
           );
       }
       return;
    }

    try {
      final userProfile = await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text,
        age: age,
        location: _locationController.text,
      );

      setState(() { _isLoading = false; });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful! Welcome, ${userProfile.name}. Please log in.')),
        );
        Navigator.of(context).pop(); 
      }
    } on String catch (errorCode) {
      setState(() { _isLoading = false; });
      
      String message = 'Registration failed. Please try again.';
      if (errorCode == 'email-already-in-use') {
        message = 'The email address is already in use.';
      } else if (errorCode == 'weak-password') {
        message = 'The password must be at least 6 characters.';
      } else if (errorCode == 'invalid-email') {
        message = 'The email address is not valid.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An unexpected error occurred: $e')));
      }
    }
  }

  // FIX: Added dispose method
  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.secondary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: Text('MINDGAUGE', style: kTitleStyle)),
                const SizedBox(height: 30),
                CustomTextField(
                  label: 'E-mail id', 
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value!.isEmpty) return 'Email is required';
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return 'Enter a valid email';
                    return null;
                  },
                ),
                CustomTextField(
                  label: 'Name', 
                  controller: _nameController,
                  validator: (value) => value!.isEmpty ? 'Name is required' : null,
                ),
                CustomTextField(
                  label: 'Age', 
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Age is required';
                    if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Must be a valid age';
                    return null;
                  },
                ),
                CustomTextField(
                  label: 'Password', 
                  isPassword: true, 
                  controller: _passwordController,
                  validator: (value) => value!.length < 6 ? 'Password must be at least 6 chars' : null,
                ),
                CustomTextField(
                  label: 'Location', 
                  controller: _locationController,
                  validator: (value) => value!.isEmpty ? 'Location is required' : null,
                ),
                const SizedBox(height: 50),
                _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : Center(
                      child: StyledButton(
                        text: 'REGISTER',
                        onPressed: _handleRegister,
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

