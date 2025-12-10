import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmployeeStyle {
  // Colors - Employee Theme
  static const Color primaryColor = Color(0xFF00D4FF);
  static const Color secondaryColor = Color(0xFF6C5CE7);
  static const Color accentColor = Color(0xFF00B894);
  static const Color backgroundColor = Color(0xFF0F1419);
  static const Color cardColor = Color(0xFF1A1F26);
  static const Color successColor = Color(0xFF00D9A3);
  static const Color warningColor = Color(0xFFFFA502);
  static const Color errorColor = Color(0xFFFF4757);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB2BAC2);
  static const Color borderColor = Color(0xFF2D3748);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF0099FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F1419), Color(0xFF1A1F26)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00D9A3), Color(0xFF00B894)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles
  static TextStyle get headingLarge => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get headingMedium => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get headingSmall => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static TextStyle get labelText => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static TextStyle get buttonText => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static TextStyle get displayText => GoogleFonts.orbitron(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    letterSpacing: 2,
  );

  // Input Decoration
  static InputDecoration getInputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: bodyMedium.copyWith(color: textSecondary),
      hintStyle: bodyMedium.copyWith(color: textSecondary.withOpacity(0.6)),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: primaryColor, size: 22)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
    );
  }

  // Button Styles
  static ButtonStyle getPrimaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: primaryColor.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ).copyWith(backgroundColor: WidgetStateProperty.all(Colors.transparent));
  }

  static BoxDecoration getPrimaryButtonDecoration() {
    return BoxDecoration(
      gradient: primaryGradient,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static ButtonStyle getSecondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: primaryColor,
      side: const BorderSide(color: primaryColor, width: 2),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  // Card Decoration
  static BoxDecoration getCardDecoration() {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(0.1),
          blurRadius: 30,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration getGlowCardDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [cardColor, cardColor.withOpacity(0.8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(0.2),
          blurRadius: 40,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration getImageContainerDecoration() {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: primaryColor.withOpacity(0.5), width: 2),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(0.3),
          blurRadius: 25,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Profile Card Decoration
  static BoxDecoration getProfileCardDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [cardColor, backgroundColor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: primaryColor.withOpacity(0.4), width: 2),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(0.2),
          blurRadius: 35,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  // Spacing
  static const double spacingXS = 8.0;
  static const double spacingS = 16.0;
  static const double spacingM = 24.0;
  static const double spacingL = 32.0;
  static const double spacingXL = 48.0;

  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  // Padding helpers
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(spacingS);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(spacingM);
    } else {
      return const EdgeInsets.all(spacingL);
    }
  }

  static double getResponsiveWidth(BuildContext context) {
    if (isMobile(context)) {
      return MediaQuery.of(context).size.width * 0.95;
    } else if (isTablet(context)) {
      return 600;
    } else {
      return 700;
    }
  }

  // Animations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration scanAnimationDuration = Duration(milliseconds: 2000);
  static const Curve animationCurve = Curves.easeInOut;

  // Status Badge Decoration
  static BoxDecoration getStatusBadgeDecoration(bool isSuccess) {
    return BoxDecoration(
      gradient: isSuccess
          ? successGradient
          : LinearGradient(colors: [errorColor, errorColor.withOpacity(0.8)]),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: (isSuccess ? successColor : errorColor).withOpacity(0.4),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Success message style
  static BoxDecoration getSuccessDecoration() {
    return BoxDecoration(
      color: successColor.withOpacity(0.15),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: successColor, width: 2),
      boxShadow: [
        BoxShadow(
          color: successColor.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Error message style
  static BoxDecoration getErrorDecoration() {
    return BoxDecoration(
      color: errorColor.withOpacity(0.15),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: errorColor, width: 2),
      boxShadow: [
        BoxShadow(
          color: errorColor.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Scanning Animation Decoration
  static BoxDecoration getScanningDecoration() {
    return BoxDecoration(
      border: Border.all(color: primaryColor, width: 3),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(0.5),
          blurRadius: 30,
          spreadRadius: 5,
        ),
      ],
    );
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? errorColor : successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  // Info Card Widget Style
  static Widget buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: bodyMedium.copyWith(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
