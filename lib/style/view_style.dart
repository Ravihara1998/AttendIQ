import 'package:flutter/material.dart';

class ViewStyle {
  // Colors - Modern purple and gradient theme
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color secondaryColor = Color(0xFF8B5CF6); // Purple
  static const Color accentColor = Color(0xFFEC4899); // Pink
  static const Color backgroundColor = Color(0xFF0F1419);
  static const Color surfaceColor = Color(0xFF1A1F2E);
  static const Color borderColor = Color(0xFF2D3748);
  static const Color textPrimary = Color.fromARGB(255, 248, 249, 250);
  static const Color textSecondary = Color.fromARGB(255, 221, 224, 230);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [secondaryColor, accentColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 20.0;
  static const double radiusXL = 24.0;

  // Text Styles
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.5,
  );
  static const TextStyle bodyLarge1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Color.fromARGB(255, 255, 255, 255),
    backgroundColor: Color(0xFF0F1419),
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  // Card Decoration
  static BoxDecoration getCardDecoration() {
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(radiusL),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Dialog Decoration
  static BoxDecoration getDialogDecoration() {
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(radiusXL),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 40,
          offset: const Offset(0, 20),
        ),
      ],
    );
  }

  // Search Decoration
  static InputDecoration getSearchDecoration() {
    return InputDecoration(
      hintText: 'Search by name, ID, or department...',
      hintStyle: bodyMedium,
      prefixIcon: const Icon(Icons.search, color: primaryColor),
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingM,
      ),
    );
  }

  // Input Decoration
  static InputDecoration getInputDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: bodyMedium.copyWith(color: textSecondary),
      hintStyle: bodyMedium,
      prefixIcon: Icon(prefixIcon, color: primaryColor, size: 22),
      filled: true,
      fillColor: backgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingM,
      ),
    );
  }

  // Button Styles
  static ButtonStyle getPrimaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: primaryColor.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(
        horizontal: spacingL,
        vertical: spacingM,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusM),
      ),
      textStyle: buttonText,
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.pressed)) {
          return secondaryColor;
        } else if (states.contains(WidgetState.hovered)) {
          return primaryColor.withOpacity(0.9);
        }
        return primaryColor;
      }),
      elevation: WidgetStateProperty.resolveWith<double>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.pressed)) {
          return 0;
        } else if (states.contains(WidgetState.hovered)) {
          return 8;
        }
        return 0;
      }),
    );
  }

  static ButtonStyle getSecondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: primaryColor,
      side: const BorderSide(color: primaryColor, width: 2),
      padding: const EdgeInsets.symmetric(
        horizontal: spacingL,
        vertical: spacingM,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusM),
      ),
      textStyle: buttonText.copyWith(color: primaryColor),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.pressed)) {
          return primaryColor.withOpacity(0.1);
        } else if (states.contains(WidgetState.hovered)) {
          return primaryColor.withOpacity(0.05);
        }
        return Colors.transparent;
      }),
    );
  }

  static ButtonStyle getDeleteButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: errorColor,
      side: const BorderSide(color: errorColor, width: 2),
      padding: const EdgeInsets.symmetric(
        horizontal: spacingL,
        vertical: spacingM,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusM),
      ),
      textStyle: buttonText.copyWith(color: errorColor),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.pressed)) {
          return errorColor.withOpacity(0.1);
        } else if (states.contains(WidgetState.hovered)) {
          return errorColor.withOpacity(0.05);
        }
        return Colors.transparent;
      }),
    );
  }

  // Snackbar
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
              size: 24,
            ),
            const SizedBox(width: spacingM),
            Expanded(
              child: Text(
                message,
                style: bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? errorColor : successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        margin: const EdgeInsets.all(spacingM),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  // Responsive
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }
}
