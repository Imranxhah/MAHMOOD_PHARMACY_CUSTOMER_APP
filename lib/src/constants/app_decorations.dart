import 'package:flutter/material.dart';
import 'package:customer_app/src/constants/app_sizes.dart';

abstract final class AppDecorations {
  static const BorderRadius screenBorderRadius = BorderRadius.vertical(
    top: Radius.circular(AppSizes.p32),
  );

  static InputDecoration authInputDecoration({
    required BuildContext context, // Add BuildContext
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest, // Theme-aware light background
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant), // Theme-aware subtle border
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0), // Highlight on focus
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5), // Theme error color
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 2.0), // Theme error color
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 20.0,
      ),
      labelStyle: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      hintStyle: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant.withAlpha((255 * 0.6).round())),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }

  static ButtonStyle primaryButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(vertical: 18.0),
      elevation: 0,
      minimumSize: const Size(double.infinity, 56.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      textStyle: const TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  static TextStyle modernHeaderStyle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.headlineMedium!.copyWith(
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.onSurface,
      letterSpacing: -0.5,
    );
  }
  
  static TextStyle modernSubtitleStyle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyLarge!.copyWith(
      color: theme.colorScheme.onSurfaceVariant, // Theme-aware subtitle color
      height: 1.5,
    );
  }
}
