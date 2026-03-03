import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failure.dart';
import '../controllers/item_form_controller.dart';
import '../controllers/items_controller.dart';
import '../state/item_form_state.dart';
import '../widgets/item_form_fields.dart';

class ItemFormPage extends ConsumerStatefulWidget {
  const ItemFormPage({super.key, this.itemId});

  final String? itemId;

  bool get isEdit => itemId != null;

  @override
  ConsumerState<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends ConsumerState<ItemFormPage> {
  late final TextEditingController _itemNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _valuationController;
  late final ImagePicker _imagePicker;

  String? _selectedItemGroup;
  String? _selectedUom;
  bool _disabled = false;
  bool _hasVariants = false;
  bool _hydratedFromItem = false;
  bool _uploadingImage = false;
  String? _existingImage;
  String? _pickedImagePath;
  bool _removeImage = false;

  @override
  void initState() {
    super.initState();
    _itemNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _valuationController = TextEditingController();
    _imagePicker = ImagePicker();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(itemFormControllerProvider.notifier)
          .initialize(itemId: widget.itemId);
    });
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _valuationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ItemFormState state = ref.watch(itemFormControllerProvider);

    if (!_hydratedFromItem && state.item != null) {
      _hydratedFromItem = true;
      _itemNameController.text = state.item!.itemName;
      _descriptionController.text = state.item!.description ?? '';
      _valuationController.text = state.item!.valuationRate?.toString() ?? '';
      _selectedItemGroup = state.item!.itemGroup;
      _selectedUom = state.item!.stockUom;
      _disabled = state.item!.disabled;
      _hasVariants = state.item!.hasVariants;
      _existingImage = state.item!.image;
    }

    if (_selectedItemGroup == null && state.itemGroups.isNotEmpty) {
      _selectedItemGroup = state.itemGroups.first;
    }

    if (_selectedUom == null && state.uoms.isNotEmpty) {
      _selectedUom = state.uoms.first;
    }

    final bool isBusy =
        state.status == ItemFormStatus.loading ||
        state.status == ItemFormStatus.submitting ||
        _uploadingImage;

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
                  widget.isEdit ? 'Edit Item' : 'Create Item',
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
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.status == ItemFormStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (state.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            state.errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      _ImageSection(
                        pickedImagePath: _pickedImagePath,
                        existingImageUrl: _removeImage
                            ? null
                            : _resolveImageUrl(_existingImage),
                        onPick: isBusy ? null : _pickImage,
                        onRemove: isBusy ? null : _removeSelectedImage,
                      ),
                      const SizedBox(height: 14),
                      ItemFormFields(
                        itemNameController: _itemNameController,
                        descriptionController: _descriptionController,
                        valuationRateController: _valuationController,
                        itemGroupOptions: state.itemGroups,
                        uomOptions: state.uoms,
                        selectedItemGroup: _selectedItemGroup,
                        selectedUom: _selectedUom,
                        disabled: _disabled,
                        hasVariants: _hasVariants,
                        onItemGroupChanged: (String? value) =>
                            setState(() => _selectedItemGroup = value),
                        onUomChanged: (String? value) =>
                            setState(() => _selectedUom = value),
                        onDisabledChanged: (bool value) =>
                            setState(() => _disabled = value),
                        onHasVariantsChanged: (bool value) =>
                            setState(() => _hasVariants = value),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
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

  void _removeSelectedImage() {
    setState(() {
      _pickedImagePath = null;
      _removeImage = true;
      _existingImage = null;
    });
  }

  Future<void> _save() async {
    if (_itemNameController.text.trim().isEmpty ||
        (_selectedItemGroup == null || _selectedItemGroup!.isEmpty) ||
        (_selectedUom == null || _selectedUom!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item Name, Item Group and UOM are required.'),
        ),
      );
      return;
    }

    final double? valuation = _valuationController.text.trim().isEmpty
        ? null
        : double.tryParse(_valuationController.text.trim());

    if (_valuationController.text.trim().isNotEmpty && valuation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valuation Rate must be a valid number.')),
      );
      return;
    }

    final ItemFormController controller = ref.read(
      itemFormControllerProvider.notifier,
    );
    String? imageValue;

    if (_pickedImagePath != null) {
      setState(() {
        _uploadingImage = true;
      });

      final upload = await controller.uploadItemImage(
        filePath: _pickedImagePath!,
        itemId: widget.itemId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _uploadingImage = false;
      });

      final Failure? uploadFailure = upload.leftOrNull;
      if (uploadFailure != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(uploadFailure.message)));
        return;
      }
      imageValue = upload.rightOrNull;
    } else if (_removeImage) {
      imageValue = '';
    }

    final Failure? failure = widget.isEdit
        ? await controller.submitUpdate(
            id: widget.itemId!,
            itemName: _itemNameController.text,
            itemGroup: _selectedItemGroup!,
            stockUom: _selectedUom!,
            image: imageValue,
            description: _descriptionController.text,
            disabled: _disabled,
            hasVariants: _hasVariants,
            valuationRate: valuation,
          )
        : await controller.submitCreate(
            itemName: _itemNameController.text,
            itemGroup: _selectedItemGroup!,
            stockUom: _selectedUom!,
            image: imageValue,
            description: _descriptionController.text,
            disabled: _disabled,
            hasVariants: _hasVariants,
            valuationRate: valuation,
          );

    if (!mounted) {
      return;
    }

    if (failure != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }

    await ref.read(itemsControllerProvider.notifier).refresh();
    if (mounted) {
      context.pop(true);
    }
  }

  String? _resolveImageUrl(String? path) {
    final String normalized = (path ?? '').trim();
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
    return '${ApiConstants.baseUrl}$normalized';
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
      child: const Icon(Icons.image_outlined),
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
          'Item Image',
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
