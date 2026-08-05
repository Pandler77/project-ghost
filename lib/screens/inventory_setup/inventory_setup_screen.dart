import 'package:flutter/material.dart';

import '../../models/inventory_item.dart';
import '../../models/inventory_preset.dart';
import '../../models/protocol.dart';
import '../../services/app_data_service.dart';
import '../../services/inventory_preset_service.dart';
import 'steps/advanced_step.dart';
import 'steps/alerts_step.dart';
import 'steps/container_step.dart';
import 'steps/current_supply_step.dart';
import 'steps/protocol_step.dart';
import 'steps/unopened_step.dart';
import 'widgets/wizard_buttons.dart';

class InventorySetupScreen extends StatefulWidget {
  const InventorySetupScreen({
    required this.dataService,
    required this.protocols,
    this.existingItem,
    super.key,
  });

  final AppDataService dataService;
  final List<Protocol> protocols;
  final InventoryItem? existingItem;

  @override
  State<InventorySetupScreen> createState() => _InventorySetupScreenState();
}

class _InventorySetupScreenState extends State<InventorySetupScreen> {
  static const int _totalSteps = 6;

  final InventoryPresetService _presetService = InventoryPresetService.instance;

  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  int _currentStep = 0;

  Protocol? _selectedProtocol;
  InventoryPreset? _selectedPreset;

  String _containerType = 'Vial';
  double _containerSize = 1;
  String _unit = 'mg';

  double _currentAmount = 1;
  int _unopenedQuantity = 0;

  int _lowStockThreshold = 1;
  int _shippingDays = 14;

  DateTime? _currentContainerOpenedAt;

  bool _isSaving = false;

  bool get _isEditing => widget.existingItem != null;

  List<Protocol> get _availableProtocols {
    final existingItem = widget.existingItem;

    if (existingItem == null) {
      return widget.protocols;
    }

    return widget.protocols.where((protocol) {
      return protocol.id == existingItem.protocolId;
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    final existingItem = widget.existingItem;

    if (existingItem != null) {
      _loadExistingItem(existingItem);
      return;
    }

    if (widget.protocols.length == 1) {
      _selectProtocol(widget.protocols.first);
    }
  }

  void _loadExistingItem(InventoryItem item) {
    for (final protocol in widget.protocols) {
      if (protocol.id == item.protocolId) {
        _selectedProtocol = protocol;
        break;
      }
    }

    if (_selectedProtocol != null) {
      _selectedPreset = _presetService.findByProtocol(_selectedProtocol!);
    }

    _containerType = item.containerType;
    _containerSize = item.vialSize;
    _unit = item.unit;

    _currentAmount = item.currentAmount;
    _unopenedQuantity = item.unopenedQuantity;

    _lowStockThreshold = item.lowStockThreshold;
    _shippingDays = item.shippingDays;

    _currentContainerOpenedAt = item.currentContainerOpenedAt;

    _vendorController.text = item.vendor ?? '';
    _batchController.text = item.batch ?? '';
    _notesController.text = item.notes ?? '';
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _batchController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  void _selectProtocol(Protocol protocol) {
    final preset = _presetService.findByProtocol(protocol);

    setState(() {
      _selectedProtocol = protocol;
      _selectedPreset = preset;

      if (!_isEditing) {
        _applyPreset(preset);
      }
    });
  }

  void _applyPreset(InventoryPreset? preset) {
    _currentContainerOpenedAt = null;

    if (preset == null) {
      _containerType = 'Vial';
      _containerSize = 1;
      _unit = 'mg';
      _currentAmount = 1;
      _lowStockThreshold = 1;
      _shippingDays = 14;
      return;
    }

    _containerType = preset.containerType;
    _containerSize = preset.defaultSize;
    _unit = preset.defaultUnit;
    _currentAmount = preset.defaultSize;
    _lowStockThreshold = preset.defaultLowStockThreshold;
    _shippingDays = preset.defaultShippingDays;
  }

  void _changeContainerType(String value) {
    setState(() {
      _containerType = value;
    });
  }

  void _changeContainerSize(double value) {
    setState(() {
      _containerSize = value;

      if (_currentAmount > value) {
        _currentAmount = value;
      }

      if (_currentAmount <= 0) {
        _currentContainerOpenedAt = null;
      }
    });
  }

  void _changeUnit(String value) {
    setState(() {
      _unit = value;

      if (_usesWholeNumbers(value)) {
        _containerSize = _containerSize.roundToDouble();
        _currentAmount = _currentAmount.roundToDouble();

        if (_containerSize < 1) {
          _containerSize = 1;
        }

        if (_currentAmount > _containerSize) {
          _currentAmount = _containerSize;
        }
      }

      if (_currentAmount <= 0) {
        _currentContainerOpenedAt = null;
      }
    });
  }

  bool _usesWholeNumbers(String unit) {
    final normalized = unit.trim().toLowerCase();

    return switch (normalized) {
      'mcg' => true,
      'iu' => true,
      'unit' || 'units' => true,
      'tablet' || 'tablets' => true,
      'capsule' || 'capsules' => true,
      'drop' || 'drops' => true,
      'patch' || 'patches' => true,
      'serving' || 'servings' => true,
      _ => false,
    };
  }

  bool get _canContinue {
    return switch (_currentStep) {
      0 => _selectedProtocol != null,
      1 =>
        _containerType.trim().isNotEmpty &&
            _containerSize > 0 &&
            _unit.trim().isNotEmpty,
      2 => _currentAmount >= 0 && _currentAmount <= _containerSize,
      3 => _unopenedQuantity >= 0,
      4 => _lowStockThreshold >= 0 && _shippingDays >= 0,
      5 => true,
      _ => false,
    };
  }

  void _next() {
    if (!_canContinue) {
      return;
    }

    if (_currentStep == _totalSteps - 1) {
      _save();
      return;
    }

    setState(() {
      _currentStep++;
    });
  }

  void _back() {
    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _currentStep--;
    });
  }

  Future<void> _save() async {
    final protocol = _selectedProtocol;

    if (protocol == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final existingItem = widget.existingItem;

      final openedAt = _currentAmount > 0 ? _currentContainerOpenedAt : null;

      final item = existingItem == null
          ? InventoryItem(
              protocolId: protocol.id,
              vialSize: _containerSize,
              currentAmount: _currentAmount,
              unit: _unit,
              containerType: _containerType,
              unopenedQuantity: _unopenedQuantity,
              lowStockThreshold: _lowStockThreshold,
              shippingDays: _shippingDays,
              currentContainerOpenedAt: openedAt,
              vendor: _optionalText(_vendorController.text),
              batch: _optionalText(_batchController.text),
              notes: _optionalText(_notesController.text),
            )
          : existingItem.copyWith(
              vialSize: _containerSize,
              currentAmount: _currentAmount,
              unit: _unit,
              containerType: _containerType,
              unopenedQuantity: _unopenedQuantity,
              lowStockThreshold: _lowStockThreshold,
              shippingDays: _shippingDays,
              currentContainerOpenedAt: openedAt,
              vendor: _optionalText(_vendorController.text),
              batch: _optionalText(_batchController.text),
              notes: _optionalText(_notesController.text),
            );

      if (existingItem == null) {
        await widget.dataService.saveInventoryItem(item);
      } else {
        await widget.dataService.updateInventoryItem(item);
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save Ghost Supply: $error')),
      );
    }
  }

  String? _optionalText(String value) {
    final trimmed = value.trim();

    return trimmed.isEmpty ? null : trimmed;
  }

  Widget _buildCurrentStep() {
    return switch (_currentStep) {
      0 => ProtocolStep(
        protocols: _availableProtocols,
        selectedProtocolId: _selectedProtocol?.id,
        onProtocolSelected: _selectProtocol,
      ),
      1 => ContainerStep(
        protocolName: _selectedProtocol?.name ?? 'Protocol',
        preset: _selectedPreset,
        containerType: _containerType,
        containerSize: _containerSize,
        unit: _unit,
        onContainerTypeChanged: _changeContainerType,
        onContainerSizeChanged: _changeContainerSize,
        onUnitChanged: _changeUnit,
      ),
      2 => CurrentSupplyStep(
        containerType: _containerType,
        containerSize: _containerSize,
        currentAmount: _currentAmount,
        unit: _unit,
        onCurrentAmountChanged: (value) {
          setState(() {
            _currentAmount = value;

            if (value <= 0) {
              _currentContainerOpenedAt = null;
            }
          });
        },
      ),
      3 => UnopenedStep(
        containerType: _containerType,
        unopenedQuantity: _unopenedQuantity,
        onUnopenedQuantityChanged: (value) {
          setState(() {
            _unopenedQuantity = value;
          });
        },
      ),
      4 => AlertsStep(
        containerType: _containerType,
        lowStockThreshold: _lowStockThreshold,
        shippingDays: _shippingDays,
        onLowStockThresholdChanged: (value) {
          setState(() {
            _lowStockThreshold = value;
          });
        },
        onShippingDaysChanged: (value) {
          setState(() {
            _shippingDays = value;
          });
        },
      ),
      5 => AdvancedStep(
        vendorController: _vendorController,
        batchController: _batchController,
        notesController: _notesController,
        currentContainerOpenedAt: _currentContainerOpenedAt,
        hasOpenContainer: _currentAmount > 0,
        onOpenedDateChanged: (value) {
          setState(() {
            _currentContainerOpenedAt = value;
          });
        },
      ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Ghost Supply™' : 'Set Up Ghost Supply™'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: SingleChildScrollView(
                  key: ValueKey(_currentStep),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: WizardButtons(
                onBack: _back,
                onNext: _next,
                nextLabel: _currentStep == _totalSteps - 1
                    ? _isEditing
                          ? 'Save Changes'
                          : 'Create Supply'
                    : 'Next',
                isNextEnabled: _canContinue,
                isLoading: _isSaving,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
