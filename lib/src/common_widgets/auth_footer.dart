import 'package:flutter/material.dart';
import 'package:customer_app/src/common_widgets/app_text_button.dart';

class AuthFooter extends StatelessWidget {
  const AuthFooter({
    super.key,
    required this.mainText,
    required this.linkText,
    required this.onLinkPressed,
  });

  final String mainText;
  final String linkText;
  final VoidCallback onLinkPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          mainText,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        AppTextButton(text: linkText, onPressed: onLinkPressed, isBold: true),
      ],
    );
  }
}
