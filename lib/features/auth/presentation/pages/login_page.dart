import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../controllers/auth_controller.dart';
import '../state/auth_state.dart';
import '../widgets/auth_screen_shell.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _identifierController;
  late final TextEditingController _passwordController;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _identifierController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref.read(authControllerProvider.notifier).submitLogin(
      email: _identifierController.text,
      password: _passwordController.text,
    );
  }

  Future<void> _changeServerUrl() async {
    await ref.read(secureStorageServiceProvider).clearServerConfiguration();
    ref.read(authControllerProvider.notifier).setUnauthenticated();
    if (!mounted) {
      return;
    }
    context.showAppInfo('Server URL cleared. Enter a new URL.');
    context.go('/setup');
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authControllerProvider);
    final bool isLoading = authState.status == AuthStatus.loading;
    final palette = context.bcnPalette;

    return AuthScreenShell(
      title: 'Login to BCN',
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            AuthPillInput(
              controller: _identifierController,
              hintText: 'Username, email or phone',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'User ID is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            AuthPillInput(
              controller: _passwordController,
              hintText: 'Enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              suffix: TextButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: palette.authTextMuted,
                  minimumSize: const Size(0, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                onPressed: () => context.push('/forgot-password'),
                style: TextButton.styleFrom(
                  foregroundColor: palette.authTextMuted,
                ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                  backgroundColor: palette.button,
                  foregroundColor: palette.onButton,
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
                    : const Text('Login'),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'or',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: palette.authTextMuted),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.authMutedAction,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: _LoginWithEmailLinkLabel(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _changeServerUrl,
              style: TextButton.styleFrom(
                foregroundColor: palette.authTextMuted,
              ),
              child: const Text(
                'Change Server URL',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginWithEmailLinkLabel extends StatelessWidget {
  const _LoginWithEmailLinkLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Login with Email Link',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: context.bcnPalette.authHeadingColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
