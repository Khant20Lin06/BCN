import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/stock_balance_entity.dart';
import '../controllers/stock_balances_controller.dart';

class StockBalanceFormPage extends ConsumerStatefulWidget {
  const StockBalanceFormPage({super.key, this.stockBalanceId});

  final String? stockBalanceId;

  bool get isEdit => stockBalanceId != null;

  @override
  ConsumerState<StockBalanceFormPage> createState() =>
      _StockBalanceFormPageState();
}

class _StockBalanceFormPageState extends ConsumerState<StockBalanceFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _stockBalanceIdController;
  late final TextEditingController _itemCodeController;
  late final TextEditingController _itemNameController;
  late final TextEditingController _warehouseController;
  late final TextEditingController _actualQtyController;
  late final TextEditingController _uomController;
  late final TextEditingController _valuationRateController;

  List<StockItemOption> _itemOptions = const <StockItemOption>[];
  List<String> _warehouseOptions = const <String>[];
  List<String> _uomOptions = const <String>[];
  String? _selectedItemCode;
  String? _selectedWarehouse;
  String? _selectedUom;
  bool _loading = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _stockBalanceIdController = TextEditingController();
    _itemCodeController = TextEditingController();
    _itemNameController = TextEditingController();
    _warehouseController = TextEditingController();
    _actualQtyController = TextEditingController();
    _uomController = TextEditingController();
    _valuationRateController = TextEditingController();
    _loading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _stockBalanceIdController.dispose();
    _itemCodeController.dispose();
    _itemNameController.dispose();
    _warehouseController.dispose();
    _actualQtyController.dispose();
    _uomController.dispose();
    _valuationRateController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final StockBalancesController controller = ref.read(
      stockBalancesControllerProvider.notifier,
    );

    List<StockItemOption> itemOptions = const <StockItemOption>[];
    List<String> warehouseOptions = const <String>[];
    List<String> uomOptions = const <String>[];
    String? errorMessage;

    try {
      itemOptions = await controller.fetchItemOptions();
    } catch (_) {
      itemOptions = const <StockItemOption>[];
    }
    try {
      warehouseOptions = await controller.fetchWarehouseOptions();
    } catch (error) {
      warehouseOptions = const <String>[];
      final String warehouseError = _extractErrorMessage(error);
      if (warehouseError.isNotEmpty) {
        errorMessage = warehouseError;
      }
    }
    try {
      uomOptions = await controller.fetchUomOptions();
    } catch (_) {
      uomOptions = const <String>[];
    }

    String id = '';
    String itemCode = '';
    String itemName = '';
    String warehouse = '';
    String actualQty = '';
    String uom = '';
    String valuationRate = '';

    if (widget.isEdit) {
      try {
        final StockBalanceEntity stock = await controller.getStockBalanceDetail(
          widget.stockBalanceId!,
        );
        id = stock.id;
        itemCode = stock.itemCode;
        itemName = stock.itemName;
        warehouse = stock.warehouse;
        actualQty = stock.actualQty?.toString() ?? '';
        uom = stock.uom;
        valuationRate = stock.valuationRate?.toString() ?? '';
      } catch (error) {
        errorMessage = error.toString();
      }
    }

    if (!mounted) {
      return;
    }

    final List<StockItemOption> mergedItemOptions = _mergeItemOptions(
      itemOptions,
      itemCode,
      itemName,
    );
    final List<String> mergedWarehouses = _mergeStrings(
      warehouseOptions,
      warehouse,
    );
    final List<String> mergedUoms = _mergeStrings(uomOptions, uom);

    setState(() {
      _itemOptions = mergedItemOptions;
      _warehouseOptions = mergedWarehouses;
      _uomOptions = mergedUoms;

      if (widget.isEdit && errorMessage == null) {
        _stockBalanceIdController.text = id;
        _itemCodeController.text = itemCode;
        _itemNameController.text = itemName;
        _warehouseController.text = warehouse;
        _actualQtyController.text = actualQty;
        _uomController.text = uom;
        _valuationRateController.text = valuationRate;
      }

      if (_itemCodeController.text.trim().isEmpty && _itemOptions.isNotEmpty) {
        _itemCodeController.text = _itemOptions.first.value;
      }
      if (_warehouseController.text.trim().isEmpty &&
          _warehouseOptions.isNotEmpty) {
        _warehouseController.text = _warehouseOptions.first;
      }
      if (_uomController.text.trim().isEmpty && _uomOptions.isNotEmpty) {
        _uomController.text = _uomOptions.first;
      }

      _selectedItemCode = _itemCodeController.text.trim().isEmpty
          ? null
          : _itemCodeController.text.trim();
      _selectedWarehouse = _warehouseController.text.trim().isEmpty
          ? null
          : _warehouseController.text.trim();
      _selectedUom = _uomController.text.trim().isEmpty
          ? null
          : _uomController.text.trim();
      if (_valuationRateController.text.trim().isEmpty) {
        final double? selectedRate = _resolveSelectedItemValuationRate(
          _selectedItemCode,
        );
        if (selectedRate != null) {
          _valuationRateController.text = selectedRate.toString();
        }
      }
      _itemNameController.text = _resolveItemName(_selectedItemCode);
      _loading = false;
      _errorMessage = errorMessage;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double? actualQty = double.tryParse(_actualQtyController.text.trim());
    if (actualQty == null) {
      setState(() {
        _errorMessage = 'Actual Qty must be a valid number.';
      });
      return;
    }

    final double? valuationRate = double.tryParse(
      _valuationRateController.text.trim(),
    );
    if (valuationRate == null || valuationRate <= 0) {
      setState(() {
        _errorMessage = 'Valuation Rate must be greater than 0.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final StockBalancesController controller = ref.read(
      stockBalancesControllerProvider.notifier,
    );
    final failure = widget.isEdit
        ? await controller.updateStockBalance(
            id: widget.stockBalanceId!,
            itemCode: _itemCodeController.text,
            warehouse: _warehouseController.text,
            actualQty: actualQty,
            uom: _uomController.text,
            valuationRate: valuationRate,
          )
        : await controller.createStockBalance(
            stockBalanceId: _stockBalanceIdController.text,
            itemCode: _itemCodeController.text,
            warehouse: _warehouseController.text,
            actualQty: actualQty,
            uom: _uomController.text,
            valuationRate: valuationRate,
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
                  widget.isEdit ? 'Edit Stock Balance' : 'Create Stock Balance',
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
                        if (!widget.isEdit) ...<Widget>[
                          const _FieldLabel(
                            label: 'Stock Balance ID (optional)',
                          ),
                          TextFormField(
                            controller: _stockBalanceIdController,
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
                                    (StockItemOption option) => Align(
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
                                  (StockItemOption option) =>
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
                                      _itemCodeController.text = (value ?? '')
                                          .trim();
                                      _itemNameController.text =
                                          _resolveItemName(value);
                                      final StockItemOption? selected =
                                          _itemOptions
                                              .cast<StockItemOption?>()
                                              .firstWhere(
                                                (StockItemOption? option) =>
                                                    option?.value == value,
                                                orElse: () => null,
                                              );
                                      if (selected != null &&
                                          selected.uom.trim().isNotEmpty) {
                                        _uomController.text = selected.uom
                                            .trim();
                                        _selectedUom = selected.uom.trim();
                                      }
                                      if (selected != null &&
                                          selected.valuationRate != null) {
                                        _valuationRateController.text = selected
                                            .valuationRate!
                                            .toString();
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
                        const _FieldLabel(label: 'Item Name'),
                        TextFormField(
                          controller: _itemNameController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            hintText: 'Read from Item',
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel(label: 'Warehouse *'),
                        if (widget.isEdit)
                          TextFormField(
                            controller: _warehouseController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              hintText: 'Warehouse',
                            ),
                          )
                        else if (_warehouseOptions.isNotEmpty)
                          DropdownButtonFormField<String>(
                            key: ValueKey<String>(
                              'warehouse-${_selectedWarehouse ?? ''}-${_warehouseOptions.length}',
                            ),
                            initialValue: _selectedWarehouse,
                            isExpanded: true,
                            decoration: const InputDecoration(),
                            items: _warehouseOptions
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
                                      _selectedWarehouse = value;
                                      _warehouseController.text = (value ?? '')
                                          .trim();
                                    });
                                  },
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Warehouse is required';
                              }
                              return null;
                            },
                          )
                        else
                          TextFormField(
                            controller: _warehouseController,
                            decoration: const InputDecoration(
                              hintText: 'Warehouse',
                            ),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Warehouse is required';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 14),
                        const _FieldLabel(label: 'Valuation Rate *'),
                        TextFormField(
                          controller: _valuationRateController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (String? value) {
                            final String text = (value ?? '').trim();
                            if (text.isEmpty) {
                              return 'Valuation Rate is required';
                            }
                            final double? parsed = double.tryParse(text);
                            if (parsed == null || parsed <= 0) {
                              return 'Valuation Rate must be greater than 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel(label: 'Actual Qty *'),
                        TextFormField(
                          controller: _actualQtyController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          validator: (String? value) {
                            final String text = (value ?? '').trim();
                            if (text.isEmpty) {
                              return 'Actual Qty is required';
                            }
                            if (double.tryParse(text) == null) {
                              return 'Actual Qty must be a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel(label: 'UOM'),
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
                                      _uomController.text = (value ?? '')
                                          .trim();
                                    });
                                  },
                          )
                        else
                          TextFormField(
                            controller: _uomController,
                            decoration: const InputDecoration(hintText: 'UOM'),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  String _resolveItemName(String? itemCode) {
    final String code = (itemCode ?? '').trim();
    if (code.isEmpty) {
      return '';
    }
    final StockItemOption? selected = _itemOptions
        .cast<StockItemOption?>()
        .firstWhere(
          (StockItemOption? option) => option?.value == code,
          orElse: () => null,
        );
    if (selected == null) {
      return '';
    }
    final int sepIndex = selected.label.indexOf(' - ');
    if (sepIndex <= 0 || sepIndex + 3 >= selected.label.length) {
      return selected.label.trim();
    }
    return selected.label.substring(sepIndex + 3).trim();
  }

  double? _resolveSelectedItemValuationRate(String? itemCode) {
    final String code = (itemCode ?? '').trim();
    if (code.isEmpty) {
      return null;
    }
    final StockItemOption? selected = _itemOptions
        .cast<StockItemOption?>()
        .firstWhere(
          (StockItemOption? option) => option?.value == code,
          orElse: () => null,
        );
    return selected?.valuationRate;
  }

  List<StockItemOption> _mergeItemOptions(
    List<StockItemOption> options,
    String currentCode,
    String currentName,
  ) {
    final String code = currentCode.trim();
    final String name = currentName.trim();
    final Map<String, StockItemOption> byCode = <String, StockItemOption>{
      for (final StockItemOption option in options) option.value: option,
    };
    if (code.isNotEmpty && !byCode.containsKey(code)) {
      byCode[code] = StockItemOption(
        value: code,
        label: name.isNotEmpty ? '$code - $name' : code,
        uom: '',
      );
    }
    final List<StockItemOption> merged = byCode.values.toList(growable: false);
    merged.sort(
      (StockItemOption a, StockItemOption b) =>
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

  String _extractErrorMessage(Object error) {
    final String raw = error.toString().trim();
    if (raw.isEmpty) {
      return '';
    }
    final List<String> prefixes = <String>[
      'Exception:',
      'ValidationFailure(',
      'ForbiddenFailure(',
      'UnauthorizedFailure(',
      'Failure(',
      'message:',
      ')',
    ];
    String cleaned = raw;
    for (final String prefix in prefixes) {
      cleaned = cleaned.replaceAll(prefix, '');
    }
    cleaned = cleaned.replaceAll("'", '').trim();
    return cleaned;
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
