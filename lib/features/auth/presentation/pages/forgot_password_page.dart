import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../widgets/bcn_logo_mark.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  bool _submitting = false;
  String? _inlineMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _inlineMessage = null;
    });

    final result = await ref
        .read(authControllerProvider.notifier)
        .requestPasswordReset(_emailController.text);

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
      _inlineMessage = result.fold(
        (failure) => failure.message,
        (right) => right,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color background = const Color(0xFFF2F2F4);
    final Color cardBackground = const Color(0xFFF6F6F7);
    final Color cardBorder = const Color(0xFFC9CDD3);
    final Color inputBorder = const Color(0xFFBFC9D8);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
              child: Column(
                children: <Widget>[
                  const BcnLogoMark(size: 66),
                  const SizedBox(height: 16),
                  Text(
                    'Forgot Password',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF142539),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: cardBorder),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.mail_outline_rounded,
                                ),
                                hintText: 'Enter email',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF6C7684),
                                  fontWeight: FontWeight.w500,
                                ),
                                fillColor: const Color(0xFFF4F4F6),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(999),
                                  borderSide: BorderSide(color: inputBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(999),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF8EA5C7),
                                  ),
                                ),
                              ),
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(54),
                                  backgroundColor: const Color(0xFF11131A),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: _submitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Instructions Emailed'),
                              ),
                            ),
                            if (_inlineMessage != null) ...<Widget>[
                              const SizedBox(height: 10),
                              Text(
                                _inlineMessage!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: const Color(0xFF5D6774)),
                              ),
                            ],
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF15263A),
                              ),
                              child: const Text(
                                'Back to Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
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
