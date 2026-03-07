import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../widgets/auth_screen_shell.dart';

class ServerSetupPage extends ConsumerStatefulWidget {
  const ServerSetupPage({super.key});

  @override
  ConsumerState<ServerSetupPage> createState() => _ServerSetupPageState();
}

class _ServerSetupPageState extends ConsumerState<ServerSetupPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedUrl();
    });
  }

  Future<void> _loadSavedUrl() async {
    final SecureStorageService storage = ref.read(secureStorageServiceProvider);
    final String? saved = await storage.getPreferredBaseUrl();
    if (!mounted || saved == null || saved.isEmpty) {
      return;
    }
    _urlController.text = saved;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    final String normalized = _normalizeUrl(_urlController.text);

    try {
      await _verifyBaseUrl(normalized);
      await ref
          .read(secureStorageServiceProvider)
          .savePreferredBaseUrl(normalized);
      if (!mounted) {
        return;
      }
      context.showAppSuccess('Server URL saved on this device.');
      context.go('/login');
    } on FormatException catch (_) {
      context.showAppError('Invalid URL. Use a full https:// address.');
    } on DioException catch (error) {
      context.showAppError(_mapDioMessage(error));
    } on HttpException catch (_) {
      context.showAppError('Invalid URL. Use a secure https:// address.');
    } catch (_) {
      context.showAppError('Unable to verify the server URL.');
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _verifyBaseUrl(String baseUrl) async {
    final Uri uri = Uri.parse(baseUrl);
    if (!uri.hasScheme || !uri.hasAuthority) {
      throw const FormatException('Invalid URL');
    }
    if (uri.scheme.toLowerCase() != 'https') {
      throw const HttpException('HTTPS required');
    }

    final Dio dio = DioFactory(ref.read(appLoggerProvider)).create(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    );

    final Response<dynamic> response = await dio.get<dynamic>(
      '/',
      options: Options(
        responseType: ResponseType.plain,
        validateStatus: (int? status) => status != null && status < 500,
      ),
    );

    final int? statusCode = response.statusCode;
    if (statusCode == null || statusCode >= 500) {
      throw const HttpException('Server unavailable');
    }
  }

  String _normalizeUrl(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  String _mapDioMessage(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Could not verify the server URL in time.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Could not reach the server URL. Check the address and network.';
    }
    return 'Failed to verify the server URL.';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.bcnPalette;
    return AuthScreenShell(
      title: 'Connect to BCN',
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            AuthPillInput(
              controller: _urlController,
              hintText: 'https://your-server.example.com',
              prefixIcon: Icons.link_rounded,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              validator: (String? value) {
                final String normalized = _normalizeUrl(value ?? '');
                if (normalized.isEmpty) {
                  return 'URL is required';
                }
                final Uri? uri = Uri.tryParse(normalized);
                if (uri == null ||
                    !uri.hasScheme ||
                    !uri.hasAuthority ||
                    uri.scheme.toLowerCase() != 'https') {
                  return 'Enter a valid https:// URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'The URL will be checked and saved on this device.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.authTextMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _saveAndContinue,
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
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
