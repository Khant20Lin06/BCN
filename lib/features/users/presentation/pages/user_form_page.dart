import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/users_controller.dart';

class UserFormPage extends ConsumerStatefulWidget {
  const UserFormPage({super.key, this.userId});

  final String? userId;

  bool get isEdit => userId != null;

  @override
  ConsumerState<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends ConsumerState<UserFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _emailController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final ImagePicker _imagePicker;

  bool _enabled = true;
  bool _obscurePassword = true;
  bool _loading = false;
  bool _submitting = false;
  bool _uploadingImage = false;
  String? _errorMessage;
  String? _existingImage;
  String? _pickedImagePath;
  bool _removeImage = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _imagePicker = ImagePicker();

    if (widget.isEdit) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetail());
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    try {
      final user = await ref
          .read(usersControllerProvider.notifier)
          .getUserDetail(widget.userId!);

      if (!mounted) {
        return;
      }
      setState(() {
        _emailController.text = user.email;
        _firstNameController.text = user.firstName;
        _lastNameController.text = user.lastName;
        _usernameController.text = user.username;
        _existingImage = user.userImage;
        _enabled = user.enabled;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _pickedImagePath = picked.path;
      _removeImage = false;
    });
  }

  void _onRemoveImage() {
    setState(() {
      _pickedImagePath = null;
      _existingImage = null;
      _removeImage = true;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final controller = ref.read(usersControllerProvider.notifier);
    String? userImage;

    if (_pickedImagePath != null) {
      setState(() {
        _uploadingImage = true;
      });

      final upload = await controller.uploadUserImage(
        filePath: _pickedImagePath!,
        userId: widget.userId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _uploadingImage = false;
      });

      final uploadFailure = upload.leftOrNull;
      if (uploadFailure != null) {
        setState(() {
          _submitting = false;
          _errorMessage = uploadFailure.message;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(uploadFailure.message)));
        return;
      }
      userImage = upload.rightOrNull;
    } else if (_removeImage) {
      userImage = '';
    }

    final failure = widget.isEdit
        ? await controller.updateUser(
            id: widget.userId!,
            email: _emailController.text,
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            username: _usernameController.text,
            enabled: _enabled,
            password: _passwordController.text,
            userImage: userImage,
          )
        : await controller.createUser(
            email: _emailController.text,
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            username: _usernameController.text,
            enabled: _enabled,
            password: _passwordController.text,
            userImage: userImage,
          );

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
      _errorMessage = failure?.message;
    });

    if (failure != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }

    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = _loading || _submitting || _uploadingImage;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: <Widget>[
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.isEdit ? 'Edit User' : 'Create User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FilledButton(
                onPressed: isBusy ? null : _save,
                child: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        _ImageSection(
                          pickedImagePath: _pickedImagePath,
                          existingImageUrl: _removeImage
                              ? null
                              : ref
                                    .read(usersControllerProvider.notifier)
                                    .resolveImageUrl(_existingImage),
                          onPick: isBusy ? null : _pickImage,
                          onRemove: isBusy ? null : _onRemoveImage,
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel(label: 'Email *'),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'user@example.com',
                          ),
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel(label: 'First Name *'),
                        TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            hintText: 'First name',
                          ),
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'First name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel(label: 'Last Name'),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            hintText: 'Last name',
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel(label: 'Username'),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            hintText: 'Optional username',
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel(
                          label: widget.isEdit
                              ? 'New Password (optional)'
                              : 'Password (optional)',
                        ),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: widget.isEdit
                                ? 'Leave blank to keep current password'
                                : 'Set initial password',
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Enabled'),
                          value: _enabled,
                          onChanged: (bool value) {
                            setState(() {
                              _enabled = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({
    required this.pickedImagePath,
    required this.existingImageUrl,
    required this.onPick,
    required this.onRemove,
  });

  final String? pickedImagePath;
  final String? existingImageUrl;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    Widget preview = Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: const Icon(Icons.person_outline_rounded),
    );

    if (pickedImagePath != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(pickedImagePath!),
          width: 92,
          height: 92,
          fit: BoxFit.cover,
        ),
      );
    } else if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          existingImageUrl!,
          width: 92,
          height: 92,
          fit: BoxFit.cover,
          errorBuilder: (_, error, stackTrace) => Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Profile Image',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            preview,
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: onPick,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Upload'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Remove'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
