import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/feedback/app_feedback.dart';
import '../../domain/entities/item_price_entity.dart';
import '../controllers/item_prices_controller.dart';

class ItemPriceFormPage extends ConsumerStatefulWidget {
  const ItemPriceFormPage({super.key, this.itemPriceId});

  final String? itemPriceId;

  bool get isEdit => itemPriceId != null;

  @override
  ConsumerState<ItemPriceFormPage> createState() => _ItemPriceFormPageState();
}

class _ItemPriceFormPageState extends ConsumerState<ItemPriceFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _priceIdController;
  late final TextEditingController _itemCodeController;
  late final TextEditingController _nameController;
  late final TextEditingController _uomController;
  late final TextEditingController _priceListController;
  late final TextEditingController _validFromController;
  late final TextEditingController _rateController;

  List<ItemPriceItemOption> _itemOptions = const <ItemPriceItemOption>[];
  List<String> _uomOptions = const <String>[];
  List<String> _priceListOptions = const <String>[];
  String? _selectedItemCode;
  String? _selectedUom;
  String? _selectedPriceList;
  bool _loading = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _priceIdController = TextEditingController();
    _itemCodeController = TextEditingController();
    _nameController = TextEditingController();
    _uomController = TextEditingController();
    _priceListController = TextEditingController();
    _validFromController = TextEditingController();
    _rateController = TextEditingController();
    _loading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _priceIdController.dispose();
    _itemCodeController.dispose();
    _nameController.dispose();
    _uomController.dispose();
    _priceListController.dispose();
    _validFromController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final ItemPricesController controller = ref.read(
      itemPricesControllerProvider.notifier,
    );

    List<ItemPriceItemOption> itemOptions = const <ItemPriceItemOption>[];
    List<String> uomOptions = const <String>[];
    List<String> priceListOptions = const <String>[];
    String? errorMessage;

    try {
      itemOptions = await controller.fetchItemOptions();
    } catch (_) {
      itemOptions = const <ItemPriceItemOption>[];
    }
    try {
      uomOptions = await controller.fetchUomOptions();
    } catch (_) {
      uomOptions = const <String>[];
    }
    try {
      priceListOptions = await controller.fetchPriceListOptions();
    } catch (_) {
      priceListOptions = const <String>['Standard Selling'];
    }

    String id = '';
    String itemCode = '';
    String itemName = '';
    String uom = '';
    String priceList = '';
    String validFrom = '';
    String rate = '';

    if (widget.isEdit) {
      try {
        final ItemPriceEntity itemPrice = await controller.getItemPriceDetail(
          widget.itemPriceId!,
        );
        id = itemPrice.id;
        itemCode = itemPrice.itemCode;
        itemName = itemPrice.itemName;
        uom = itemPrice.uom;
        priceList = itemPrice.priceList;
        validFrom = _formatDate(itemPrice.validFrom);
        rate = itemPrice.priceListRate?.toString() ?? '';
      } catch (error) {
        errorMessage = error.toString();
      }
    }

    if (!mounted) {
      return;
    }

    final List<ItemPriceItemOption> mergedItemOptions = _mergeItemOptions(
      itemOptions,
      itemCode,
      itemName,
      uom,
    );
    final List<String> mergedUoms = _mergeStrings(uomOptions, uom);
    final List<String> mergedPriceLists = _mergeStrings(priceListOptions, priceList);

    setState(() {
      _itemOptions = mergedItemOptions;
      _uomOptions = mergedUoms;
      _priceListOptions = mergedPriceLists;

      if (widget.isEdit && errorMessage == null) {
        _priceIdController.text = id;
        _itemCodeController.text = itemCode;
        _nameController.text = itemName;
        _uomController.text = uom;
        _priceListController.text = priceList;
        _validFromController.text = validFrom;
        _rateController.text = rate;
      }

      if (_itemCodeController.text.trim().isEmpty && _itemOptions.isNotEmpty) {
        final ItemPriceItemOption first = _itemOptions.first;
        _itemCodeController.text = first.value;
        _nameController.text = first.itemName;
        if (_uomController.text.trim().isEmpty && first.stockUom.trim().isNotEmpty) {
          _uomController.text = first.stockUom.trim();
        }
      }
      if (_uomController.text.trim().isEmpty && _uomOptions.isNotEmpty) {
        _uomController.text = _uomOptions.first;
      }
      if (_priceListController.text.trim().isEmpty && _priceListOptions.isNotEmpty) {
        _priceListController.text = _priceListOptions.first;
      }
      if (_validFromController.text.trim().isEmpty) {
        _validFromController.text = _todayIsoDate();
      }

      _selectedItemCode = _itemCodeController.text.trim().isEmpty
          ? null
          : _itemCodeController.text.trim();
      _selectedUom = _uomController.text.trim().isEmpty
          ? null
          : _uomController.text.trim();
      _selectedPriceList = _priceListController.text.trim().isEmpty
          ? null
          : _priceListController.text.trim();
      _loading = false;
      _errorMessage = errorMessage;
    });
  }

  Future<void> _pickValidFromDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _parseDate(_validFromController.text) ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 30),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _validFromController.text = _formatDate(picked);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double? rate = double.tryParse(_rateController.text.trim());
    if (rate == null || rate < 0) {
      context.showAppError('Rate must be a valid positive number.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final ItemPricesController controller = ref.read(
      itemPricesControllerProvider.notifier,
    );
    final failure = widget.isEdit
        ? await controller.updateItemPrice(
            id: widget.itemPriceId!,
            itemName: _nameController.text,
            uom: _uomController.text,
            priceList: _priceListController.text,
            validFrom: _validFromController.text,
            rate: rate,
          )
        : await controller.createItemPrice(
            priceId: _priceIdController.text,
            itemCode: _itemCodeController.text,
            itemName: _nameController.text,
            uom: _uomController.text,
            priceList: _priceListController.text,
            validFrom: _validFromController.text,
            rate: rate,
          );

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
    });

    if (failure != null) {
      context.showAppFailure(failure);
      return;
    }

    context.showAppSuccess(
      widget.isEdit ? 'Item price updated.' : 'Item price created.',
    );
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = _loading || _submitting;

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
                  widget.isEdit ? 'Edit Item Price' : 'Create Item Price',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
                          AppLoadErrorReporter(
                            message: _errorMessage!,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        if (!widget.isEdit) ...<Widget>[
                          const _FieldLabel(label: 'Item Price ID (optional)'),
                          TextFormField(
                            controller: _priceIdController,
                            decoration: const InputDecoration(
                              hintText: 'Auto generated if blank',
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        const _FieldLabel(label: 'Item Code *'),
                        if (widget.isEdit)
                          TextFormField(
                            controller: _itemCodeController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              hintText: 'Item code',
                            ),
                          )
                        else if (_itemOptions.isNotEmpty)
                          DropdownButtonFormField<String>(
                            key: ValueKey<String>(
                              'item-${_selectedItemCode ?? ''}-${_itemOptions.length}',
                            ),
                            initialValue: _selectedItemCode,
                            isExpanded: true,
                            decoration: const InputDecoration(),
                            selectedItemBuilder: (BuildContext context) {
                              return _itemOptions
                                  .map(
                                    (ItemPriceItemOption option) => Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        option.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(growable: false);
                            },
                            items: _itemOptions
                                .map(
                                  (ItemPriceItemOption option) =>
                                      DropdownMenuItem<String>(
                                        value: option.value,
                                        child: Text(
                                          option.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                )
                                .toList(growable: false),
                            onChanged: isBusy
                                ? null
                                : (String? value) {
                                    setState(() {
                                      _selectedItemCode = value;
                                      _itemCodeController.text =
                                          (value ?? '').trim();
                                      final ItemPriceItemOption? selected = _itemOptions
                                          .cast<ItemPriceItemOption?>()
                                          .firstWhere(
                                            (ItemPriceItemOption? option) =>
                                                option?.value == value,
                                            orElse: () => null,
                                          );
                                      _nameController.text =
                                          selected?.itemName ?? '';
                                      if ((selected?.stockUom ?? '')
                                          .trim()
                                          .isNotEmpty) {
                                        _uomController.text =
                                            selected!.stockUom.trim();
                                        _selectedUom =
                                            selected.stockUom.trim();
                                      }
                                    });
                                  },
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Item code is required';
                              }
                              return null;
                            },
                          )
                        else
                          TextFormField(
                            controller: _itemCodeController,
                            decoration: const InputDecoration(
                              hintText: 'Item code',
                            ),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Item code is required';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 14),
                        const _FieldLabel(label: 'Name *'),
                        TextFormField(
                          controller: _nameController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            hintText: 'Read from item',
                          ),
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel(label: 'UOM *'),
                        if (_uomOptions.isNotEmpty)
                          DropdownButtonFormField<String>(
                            key: ValueKey<String>(
                              'uom-${_selectedUom ?? ''}-${_uomOptions.length}',
                            ),
                            initialValue: _selectedUom,
                            isExpanded: true,
                            decoration: const InputDecoration(),
                            items: _uomOptions
                                .map(
                                  (String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: isBusy
                                ? null
                                : (String? value) {
                                    setState(() {
                                      _selectedUom = value;
                                      _uomController.text = (value ?? '').trim();
                                    });
                                  },
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'UOM is required';
                              }
                              return null;
                            },
                          )
                        else
                          TextFormField(
                            controller: _uomController,
                            decoration: const InputDecoration(hintText: 'UOM'),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'UOM is required';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 14),
                        const _FieldLabel(label: 'Price List *'),
                        if (_priceListOptions.isNotEmpty)
                          DropdownButtonFormField<String>(
                            key: ValueKey<String>(
                              'price-list-${_selectedPriceList ?? ''}-${_priceListOptions.length}',
                            ),
                            initialValue: _selectedPriceList,
                            isExpanded: true,
                            decoration: const InputDecoration(),
                            selectedItemBuilder: (BuildContext context) {
                              return _priceListOptions
                                  .map(
                                    (String value) => Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        value,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(growable: false);
                            },
                            items: _priceListOptions
                                .map(
                                  (String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: isBusy
                                ? null
                                : (String? value) {
                                    setState(() {
                                      _selectedPriceList = value;
                                      _priceListController.text =
                                          (value ?? '').trim();
                                    });
                                  },
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Price list is required';
                              }
                              return null;
                            },
                          )
                        else
                          TextFormField(
                            controller: _priceListController,
                            decoration: const InputDecoration(
                              hintText: 'Price List',
                            ),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Price list is required';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 14),
                        const _FieldLabel(label: 'Valid From *'),
                        TextFormField(
                          controller: _validFromController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: 'YYYY-MM-DD',
                            suffixIcon: IconButton(
                              onPressed: isBusy ? null : _pickValidFromDate,
                              icon: const Icon(Icons.calendar_today_outlined),
                            ),
                          ),
                          validator: (String? value) {
                            final String text = (value ?? '').trim();
                            if (text.isEmpty) {
                              return 'Valid From is required';
                            }
                            if (_parseDate(text) == null) {
                              return 'Valid From must be a valid date';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel(label: 'Rate *'),
                        TextFormField(
                          controller: _rateController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (String? value) {
                            final String text = (value ?? '').trim();
                            if (text.isEmpty) {
                              return 'Rate is required';
                            }
                            final double? parsed = double.tryParse(text);
                            if (parsed == null || parsed < 0) {
                              return 'Rate must be a valid number';
                            }
                            return null;
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

  List<ItemPriceItemOption> _mergeItemOptions(
    List<ItemPriceItemOption> options,
    String currentCode,
    String currentName,
    String currentUom,
  ) {
    final String code = currentCode.trim();
    final String name = currentName.trim();
    final String uom = currentUom.trim();

    final Map<String, ItemPriceItemOption> byCode = <String, ItemPriceItemOption>{
      for (final ItemPriceItemOption option in options) option.value: option,
    };
    if (code.isNotEmpty && !byCode.containsKey(code)) {
      byCode[code] = ItemPriceItemOption(
        value: code,
        label: name.isNotEmpty ? '$code - $name' : code,
        itemName: name,
        stockUom: uom,
      );
    }

    final List<ItemPriceItemOption> merged = byCode.values.toList(growable: false);
    merged.sort(
      (ItemPriceItemOption a, ItemPriceItemOption b) =>
          a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return merged;
  }

  List<String> _mergeStrings(List<String> values, String currentValue) {
    final Set<String> merged = <String>{...values};
    final String current = currentValue.trim();
    if (current.isNotEmpty) {
      merged.add(current);
    }
    final List<String> result = merged.toList(growable: false);
    result.sort(
      (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );
    return result;
  }

  DateTime? _parseDate(String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return DateTime.tryParse(normalized) ??
        DateTime.tryParse(normalized.replaceFirst(' ', 'T'));
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '';
    }
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _todayIsoDate() => _formatDate(DateTime.now());
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
