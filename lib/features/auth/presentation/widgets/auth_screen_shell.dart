import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import 'bcn_logo_mark.dart';

class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 390;
    final BcnThemePalette palette = context.bcnPalette;

    return Scaffold(
      backgroundColor: palette.authPageBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 8),
                  const BcnLogoMark(size: 66),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.authHeadingColor,
                      fontSize: compact ? 34 : 38,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AuthCardSurface(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthCardSurface extends StatelessWidget {
  const AuthCardSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final BcnThemePalette palette = context.bcnPalette;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.authCardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.authCardBorder),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
        child: child,
      ),
    );
  }
}

class AuthPillInput extends StatelessWidget {
  const AuthPillInput({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final BcnThemePalette palette = context.bcnPalette;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: palette.authHeadingColor,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(prefixIcon, color: palette.authTextMuted),
        suffixIcon: suffix,
        fillColor: palette.authCardBackground,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: palette.authInputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: palette.button),
        ),
      ),
    );
  }
}

class AuthMessagePill extends StatelessWidget {
  const AuthMessagePill({
    super.key,
    required this.message,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String message;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final BcnThemePalette palette = context.bcnPalette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.button,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: foregroundColor ?? palette.onButton,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
