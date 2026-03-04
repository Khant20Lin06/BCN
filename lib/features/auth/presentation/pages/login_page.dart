import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../state/auth_state.dart';
import '../widgets/bcn_logo_mark.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .submitLogin(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authControllerProvider);
    final bool isLoading = authState.status == AuthStatus.loading;
    final bool compact = MediaQuery.sizeOf(context).width < 390;

    const Color pageBackground = Color(0xFFF2F2F4);
    const Color cardBackground = Color(0xFFF6F6F7);
    const Color cardBorder = Color(0xFFC9CDD3);
    const Color inputBorder = Color(0xFFBFC9D8);
    const Color primaryAction = Color(0xFF11131A);
    const Color mutedAction = Color(0xFFECECEE);

    final String primaryLabel = authState.errorMessage ?? 'Login';

    return Scaffold(
      backgroundColor: pageBackground,
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
                    'Login to BCN',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF142539),
                      fontSize: compact ? 34 : 38,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: cardBorder),
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            _PillInput(
                              controller: _emailController,
                              hintText: 'user@bcncl.com',
                              prefixIcon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              borderColor: inputBorder,
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _PillInput(
                              controller: _passwordController,
                              hintText: 'Enter your password',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              borderColor: inputBorder,
                              suffix: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF6D7785),
                                  minimumSize: const Size(0, 0),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(_obscurePassword ? 'Show' : 'Hide'),
                              ),
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Password is required';
                                }
                                return null;
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () =>
                                    context.push('/forgot-password'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF748294),
                                ),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(54),
                                  backgroundColor: primaryAction,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(primaryLabel),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'or',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: const Color(0xFF7D8793)),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: mutedAction,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Text(
                                    'Login with Email Link',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF4D5968),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillInput extends StatelessWidget {
  const _PillInput({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    required this.borderColor,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final Color borderColor;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF2C3A4D),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF4B5564)),
        suffixIcon: suffix,
        fillColor: const Color(0xFFF4F4F6),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Color(0xFF8EA5C7)),
        ),
      ),
    );
  }
}
