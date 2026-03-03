import 'package:flutter/material.dart';
class AppColors {
  static const Color primary = Color(0xFF00C8C8); // Bright Cyan
  static const Color secondary = Color(0xFF007A7A); // Darker Teal
  static const Color background = Color(0xFFF7FFF7); // Off-White/Minty Background
  static const Color cardColor = Color(0xFFEEF7E8); // Light Green Card
  static const Color text = Color(0xFF2C3E50); // Dark text
  static const Color buttonShadow = Color(0xAA00C8C8);
  static const Color warning = Color(0xFFFF9800); // Amber for warnings/mild
  static const Color danger = Color(0xFFE53935); // Red for severe
}

const TextStyle kTitleStyle = TextStyle(
  color: AppColors.secondary,
  fontSize: 32,
  fontWeight: FontWeight.w900,
  letterSpacing: 1.5,
);

const TextStyle kSubtitleStyle = TextStyle(
  color: AppColors.primary,
  fontSize: 16,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.5,
);

// --- MAIN APP WIDGET ---



// --- WIDGETS ---

class StyledButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color shadowColor;

  const StyledButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = AppColors.primary,
    this.shadowColor = AppColors.buttonShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(25),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            elevation: 0,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomTextField extends StatefulWidget {
  final String label;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator; 
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    required this.label,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: widget.controller,
            obscureText: _obscureText,
            style: const TextStyle(color: AppColors.text),
            validator: widget.validator,
            keyboardType: widget.keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              suffixIcon: widget.isPassword ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.secondary,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ) : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: AppColors.danger, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: AppColors.danger, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
