import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ui_components.dart';
import 'models.dart';
import 'services.dart';
import 'login_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;

  const EditProfileScreen({super.key, required this.userProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late UserProfile _currentProfile;
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.userProfile;
  }

  Future<void> _updateField<T>(
    String field,
    String title,
    TextInputType keyboardType,
    T Function(String) parser,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: field == 'age'
          ? _currentProfile.age.toString()
          : field == 'name'
          ? _currentProfile.name
          : field == 'location'
          ? _currentProfile.location
          : '',
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update $title'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: 'New $title',
              border: const OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty
                    ? 'Please enter a valid $title'
                    : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final parsedValue = parser(controller.text.trim());
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({field: parsedValue}, SetOptions(merge: true));

          if (mounted) {
            setState(() {
              if (field == 'name') {
                _currentProfile = _currentProfile.copyWith(
                  name: parsedValue as String,
                );
              } else if (field == 'age') {
                _currentProfile = _currentProfile.copyWith(
                  legacyAge: parsedValue as int,
                );
              } else if (field == 'location') {
                _currentProfile = _currentProfile.copyWith(
                  location: parsedValue as String,
                );
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title updated successfully.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update $title: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentProfile.birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.secondary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _currentProfile.birthDate) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentProfile.userId)
            .update({'birthDate': Timestamp.fromDate(picked)});
        
        if (mounted) {
          setState(() {
            _currentProfile = _currentProfile.copyWith(birthDate: picked);
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Birthdate updated successfully.')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: $e')),
          );
        }
      }
    }
  }

  Future<void> _updateEmailField() async {
    final TextEditingController controller = TextEditingController(text: _currentProfile.email);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Email'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'New Email',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter a valid email';
              if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return 'Please enter a valid email address';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final newEmail = controller.text.trim();
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && newEmail != user.email) {
          // ignore: deprecated_member_use
          await user.verifyBeforeUpdateEmail(newEmail);
          
          if (mounted) {
            setState(() {
              _currentProfile = _currentProfile.copyWith(email: newEmail);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email updated successfully.')),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          String msg = e.message ?? 'An error occurred';
          if (e.code == 'requires-recent-login') {
            msg = 'Security restriction: Please log out and back in before changing your email.';
          } else if (e.code == 'operation-not-allowed') {
            msg = 'This operation is not allowed right now.';
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update email: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    setState(() => _isLoading = true);
    try {
      await _authService.resetPassword(widget.userProfile.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _authService.deleteAccount();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar / Info display
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 30),

                    // Information List
                    _buildProfileItem(
                      'Email',
                      _currentProfile.email,
                      _updateEmailField,
                    ),
                    const Divider(),
                    _buildProfileItem(
                      'Name',
                      _currentProfile.name,
                      () => _updateField<String>(
                        'name',
                        'Name',
                        TextInputType.name,
                        (val) => val,
                      ),
                    ),
                    const Divider(),
                    _buildProfileItem(
                      'Birthdate',
                      _currentProfile.birthDate != null
                          ? '${_currentProfile.birthDate!.year}-${_currentProfile.birthDate!.month.toString().padLeft(2, '0')}-${_currentProfile.birthDate!.day.toString().padLeft(2, '0')}'
                          : 'Not set',
                      _updateBirthDate,
                    ),
                    const Divider(),
                    _buildProfileItem(
                      'Age',
                      _currentProfile.age.toString(),
                    ),
                    const Divider(),
                    _buildProfileItem(
                      'Location',
                      _currentProfile.location,
                      () => _updateField<String>(
                        'location',
                        'Location',
                        TextInputType.text,
                        (val) => val,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    const Divider(height: 60, thickness: 1),

                    // Security block
                    const Text(
                      'Account & Security',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.lock_reset, color: AppColors.secondary),
                      label: const Text('Send Password Reset Email'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: const BorderSide(color: AppColors.secondary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _resetPassword,
                    ),
                    const SizedBox(height: 15),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.logout, color: AppColors.primary),
                      label: const Text('Logout Default Account'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _logout,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete My Account'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: BorderSide(color: Colors.red.shade200),
                        elevation: 0,
                      ),
                      onPressed: _deleteAccount,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileItem(String label, String value, [VoidCallback? onUpdate]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          if (onUpdate != null)
            TextButton.icon(
              onPressed: onUpdate,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Update'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}
