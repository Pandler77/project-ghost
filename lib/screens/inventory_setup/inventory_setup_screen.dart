import 'package:flutter/material.dart';

import '../../models/dose_unit.dart';
import '../../models/inventory_batch.dart';
import '../../models/inventory_item.dart';
import '../../models/inventory_preset.dart';
import '../../models/protocol.dart';
import '../../services/app_data_service.dart';
import '../../services/inventory_preset_service.dart';
import '../../theme/app_theme.dart';
import 'steps/advanced_step.dart';
import 'steps/alerts_step.dart';
import 'steps/container_step.dart';
import 'steps/current_supply_step.dart';
import 'steps/protocol_step.dart';
import 'steps/remaining_amount_step.dart';
import 'steps/unopened_step.dart';
import 'widgets/wizard_buttons.dart';

enum ActiveContainerSource { none, thisBatch, existingBatch, separate }

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
  static const int _totalSteps = 7;

  final InventoryPresetService _presetService = InventoryPresetService.instance;

  final TextEditingController _reconstitutionVolumeController =
      TextEditingController();

  final TextEditingController _storageInstructionsController =
      TextEditingController();

  final TextEditingController _costController = TextEditingController();

  final TextEditingController _vendorController = TextEditingController();

  final TextEditingController _displayNameController = TextEditingController();

  final TextEditingController _batchNameController = TextEditingController();

  final TextEditingController _batchController = TextEditingController();

  final TextEditingController _notesController = TextEditingController();

  int _currentStep = 0;

  Protocol? _selectedProtocol;
  InventoryPreset? _selectedPreset;

  String _containerType = 'Vial';
  double _containerSize = 1;
  String _unit = 'mg';
  double? _separateContainerSize;

  double _currentAmount = 0;
  bool _isRemainingAmountValid = true;

  /// Total physical containers being added.
  int _totalQuantity = 0;

  ActiveContainerSource _activeContainerSource = ActiveContainerSource.none;

  List<InventoryBatch> _existingBatches = [];
  String? _selectedExistingBatchId;

  int _lowStockThreshold = 1;
  int _shippingDays = 14;

  DateTime? _currentContainerOpenedAt;
  DateTime? _expirationDate;
  DateTime? _purchaseDate;

  bool _isSaving = false;

  bool get _isEditing {
    return widget.existingItem != null;
  }

  bool get _supportsReconstitution {
    return _containerType.trim().toLowerCase() == 'vial';
  }

  int get _derivedUnopenedQuantity {
    if (_totalQuantity <= 0) {
      return 0;
    }

    if (_activeContainerSource == ActiveContainerSource.thisBatch) {
      return (_totalQuantity - 1).clamp(0, _totalQuantity);
    }

    return _totalQuantity;
  }

  InventoryBatch? get _selectedExistingBatch {
    final selectedId = _selectedExistingBatchId;

    if (selectedId == null) {
      return null;
    }

    for (final batch in _existingBatches) {
      if (batch.id == selectedId) {
        return batch;
      }
    }

    return null;
  }

  double get _activeContainerSize {
    if (_activeContainerSource == ActiveContainerSource.existingBatch) {
      return _selectedExistingBatch?.containerSize ?? _containerSize;
    }

    if (_activeContainerSource == ActiveContainerSource.separate) {
      return _separateContainerSize ?? 0;
    }

    return _containerSize;
  }

  String get _activeContainerUnit {
    if (_activeContainerSource == ActiveContainerSource.existingBatch) {
      return _selectedExistingBatch?.unit ?? _unit;
    }

    return _unit;
  }

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
      _loadExistingBatches(existingItem.protocolId);
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

    _totalQuantity = item.unopenedQuantity + (item.currentAmount > 0 ? 1 : 0);

    _selectedExistingBatchId = item.currentContainerBatchId;

    if (item.currentAmount <= 0) {
      _activeContainerSource = ActiveContainerSource.none;
    } else if (item.currentContainerBatchId != null) {
      _activeContainerSource = ActiveContainerSource.existingBatch;
    } else {
      _activeContainerSource = ActiveContainerSource.separate;
      _separateContainerSize = item.vialSize;
    }

    _lowStockThreshold = item.lowStockThreshold;
    _shippingDays = item.shippingDays;

    _currentContainerOpenedAt = item.currentContainerOpenedAt;

    _expirationDate = item.expirationDate;
    _purchaseDate = item.purchaseDate;

    _reconstitutionVolumeController.text = item.reconstitutionVolumeMl == null
        ? ''
        : _formatNumber(item.reconstitutionVolumeMl!);

    _storageInstructionsController.text = item.storageInstructions ?? '';

    _costController.text = item.cost == null ? '' : _formatNumber(item.cost!);

    _vendorController.text = item.vendor ?? '';
    _displayNameController.text = item.displayName?.trim().isNotEmpty == true
        ? item.displayName!.trim()
        : _selectedProtocol?.name ?? '';
    _batchController.text = item.batch ?? '';
    _notesController.text = item.notes ?? '';
  }

  @override
  void dispose() {
    _reconstitutionVolumeController.dispose();
    _storageInstructionsController.dispose();
    _costController.dispose();
    _vendorController.dispose();
    _batchNameController.dispose();
    _batchController.dispose();
    _notesController.dispose();
    _displayNameController.dispose();

    super.dispose();
  }

  Future<void> _selectProtocol(Protocol protocol) async {
    final preset = _presetService.findByProtocol(protocol);

    setState(() {
      _selectedProtocol = protocol;
      _selectedPreset = preset;

      _existingBatches = [];
      _selectedExistingBatchId = null;

      if (!_isEditing) {
        _applyPreset(preset);
        _displayNameController.text = protocol.name;
      }
    });

    await _loadExistingBatches(protocol.id);
  }

  Future<void> _loadExistingBatches(String protocolId) async {
    final item = await widget.dataService.getInventoryItemForProtocol(
      protocolId,
    );

    if (item == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _existingBatches = [];
        _selectedExistingBatchId = null;
      });

      return;
    }

    final batches = await widget.dataService.getInventoryBatchesForItem(
      item.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _existingBatches = batches;

      final selectedId = _selectedExistingBatchId;

      if (selectedId != null &&
          !batches.any((batch) => batch.id == selectedId)) {
        _selectedExistingBatchId = null;
      }
    });
  }

  void _applyPreset(InventoryPreset? preset) {
    _currentContainerOpenedAt = null;
    _totalQuantity = 0;

    _activeContainerSource = ActiveContainerSource.none;

    _selectedExistingBatchId = null;
    _separateContainerSize = null;
    _isRemainingAmountValid = true;

    _expirationDate = null;
    _purchaseDate = null;

    _reconstitutionVolumeController.clear();
    _storageInstructionsController.clear();
    _costController.clear();
    _vendorController.clear();
    _batchNameController.clear();
    _batchController.clear();
    _notesController.clear();

    if (preset == null) {
      _containerType = 'Vial';
      _containerSize = 1;
      _unit = 'mg';

      _currentAmount = 0;

      _lowStockThreshold = 1;
      _shippingDays = 14;

      return;
    }

    _containerType = preset.containerType;
    _containerSize = preset.defaultSize;
    _unit = preset.defaultUnit;

    _currentAmount = 0;

    _lowStockThreshold = preset.defaultLowStockThreshold;

    _shippingDays = preset.defaultShippingDays;
  }

  void _changeContainerType(String value) {
    setState(() {
      _containerType = value;

      if (!_supportsReconstitution) {
        _reconstitutionVolumeController.clear();
      }
    });
  }

  void _changeContainerSize(double value) {
    setState(() {
      _containerSize = value;

      if (_activeContainerSource != ActiveContainerSource.existingBatch &&
          _currentAmount > value) {
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

        if (_activeContainerSource != ActiveContainerSource.existingBatch) {
          _currentAmount = _currentAmount.roundToDouble();

          if (_currentAmount > _containerSize) {
            _currentAmount = _containerSize;
          }
        }

        if (_containerSize < 1) {
          _containerSize = 1;
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

  bool get _requiresInitialBatchName {
    return !_isEditing && _derivedUnopenedQuantity > 0;
  }

  bool get _canContinue {
    return switch (_currentStep) {
      // Step 1 - Protocol
      0 => _selectedProtocol != null,

      // Step 2 - Container
      1 =>
        _containerType.trim().isNotEmpty &&
            _containerSize > 0 &&
            _unit.trim().isNotEmpty,

      // Step 3 - Active container source
      2 => switch (_activeContainerSource) {
        ActiveContainerSource.none => true,

        ActiveContainerSource.thisBatch =>
          _currentAmount > 0 && _currentAmount <= _containerSize,

        ActiveContainerSource.existingBatch =>
          _selectedExistingBatch != null &&
              _currentAmount > 0 &&
              _currentAmount <= _activeContainerSize,

        ActiveContainerSource.separate =>
          _separateContainerSize != null && _separateContainerSize! > 0,
      },

      // Step 4 - Remaining amount
      3 =>
        _activeContainerSource == ActiveContainerSource.none ||
            (_isRemainingAmountValid &&
                _currentAmount >= 0 &&
                _currentAmount <= _activeContainerSize),

      // Step 5 - Total quantity
      4 => _totalQuantity > 0,

      // Step 6 - Alerts
      5 => _lowStockThreshold >= 0 && _shippingDays >= 0,

      // Step 7 - Advanced
      6 =>
        _displayNameController.text.trim().isNotEmpty &&
            (!_requiresInitialBatchName ||
                _batchNameController.text.trim().isNotEmpty) &&
            (!_supportsReconstitution ||
                _optionalPositiveDoubleIsValid(
                  _reconstitutionVolumeController.text,
                )) &&
            _optionalNonNegativeDoubleIsValid(_costController.text),

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

      final hasActiveContainer =
          _activeContainerSource != ActiveContainerSource.none;

      final openedAt = hasActiveContainer ? _currentContainerOpenedAt : null;

      final activeSize = hasActiveContainer
          ? _activeContainerSize
          : _containerSize;

      final activeUnit = hasActiveContainer ? _activeContainerUnit : _unit;

      final activeBatchId =
          _activeContainerSource == ActiveContainerSource.existingBatch
          ? _selectedExistingBatchId
          : null;

      final item = existingItem == null
          ? InventoryItem(
              protocolId: protocol.id,
              displayName: _displayNameController.text.trim(),
              vialSize: activeSize,
              currentAmount: hasActiveContainer ? _currentAmount : 0,
              unit: activeUnit,
              containerType: _containerType,
              unopenedQuantity: _derivedUnopenedQuantity,
              lowStockThreshold: _lowStockThreshold,
              shippingDays: _shippingDays,
              currentContainerOpenedAt: openedAt,
              currentContainerBatchId: activeBatchId,
              reconstitutionVolumeMl: _supportsReconstitution
                  ? _optionalDouble(_reconstitutionVolumeController.text)
                  : null,
              expirationDate: _expirationDate,
              storageInstructions: _optionalText(
                _storageInstructionsController.text,
              ),
              purchaseDate: _purchaseDate,
              cost: _optionalDouble(_costController.text),
              vendor: _optionalText(_vendorController.text),
              batch: _optionalText(_batchController.text),
              notes: _optionalText(_notesController.text),
            )
          : existingItem.copyWith(
              displayName: _displayNameController.text.trim(),
              vialSize: activeSize,
              currentAmount: hasActiveContainer ? _currentAmount : 0,
              unit: activeUnit,
              containerType: _containerType,
              unopenedQuantity: _derivedUnopenedQuantity,
              lowStockThreshold: _lowStockThreshold,
              shippingDays: _shippingDays,
              currentContainerOpenedAt: openedAt,
              currentContainerBatchId: activeBatchId,
              reconstitutionVolumeMl: _supportsReconstitution
                  ? _optionalDouble(_reconstitutionVolumeController.text)
                  : null,
              expirationDate: _expirationDate,
              storageInstructions: _optionalText(
                _storageInstructionsController.text,
              ),
              purchaseDate: _purchaseDate,
              cost: _optionalDouble(_costController.text),
              vendor: _optionalText(_vendorController.text),
              batch: _optionalText(_batchController.text),
              notes: _optionalText(_notesController.text),
            );

      if (existingItem == null) {
        await widget.dataService.saveInventoryItem(
          item,
          initialBatchName: _requiresInitialBatchName
              ? _batchNameController.text.trim()
              : null,
          initialBatchContainerSize: _containerSize,
          initialBatchUnit: _unit,
        );
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

  double? _optionalDouble(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return double.tryParse(trimmed);
  }

  bool _optionalPositiveDoubleIsValid(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return true;
    }

    final parsed = double.tryParse(trimmed);

    return parsed != null && parsed > 0;
  }

  bool _optionalNonNegativeDoubleIsValid(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return true;
    }

    final parsed = double.tryParse(trimmed);

    return parsed != null && parsed >= 0;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
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
        source: _activeContainerSource,
        existingBatches: _existingBatches,
        selectedExistingBatchId: _selectedExistingBatchId,
        separateContainerSize: _separateContainerSize,
        onSeparateContainerSizeChanged: (value) {
          setState(() {
            _separateContainerSize = value;
            _currentAmount = value;
            _isRemainingAmountValid = true;
          });
        },
        onSourceChanged: (value) {
          setState(() {
            _activeContainerSource = value;

            if (value == ActiveContainerSource.none) {
              _selectedExistingBatchId = null;
              _separateContainerSize = null;
              _currentAmount = 0;
              _currentContainerOpenedAt = null;
              _isRemainingAmountValid = true;
            } else if (value == ActiveContainerSource.existingBatch) {
              _selectedExistingBatchId = null;
              _separateContainerSize = null;
              _currentAmount = 0;
              _isRemainingAmountValid = true;
            } else if (value == ActiveContainerSource.separate) {
              _selectedExistingBatchId = null;
              _separateContainerSize = null;
              _currentAmount = 0;
              _isRemainingAmountValid = true;
            } else {
              _selectedExistingBatchId = null;
              _separateContainerSize = null;
              _currentAmount = _containerSize;
              _isRemainingAmountValid = true;
            }
          });
        },
        onExistingBatchSelected: (batchId) {
          final batch = _existingBatches.firstWhere(
            (batch) => batch.id == batchId,
          );

          setState(() {
            _selectedExistingBatchId = batch.id;
            _separateContainerSize = null;
            _currentAmount = batch.containerSize;
            _isRemainingAmountValid = true;
          });
        },
      ),

      3 => RemainingAmountStep(
        containerType: _containerType,
        containerSize: _activeContainerSize,
        unit: _activeContainerUnit,
        source: _activeContainerSource,
        currentAmount: _currentAmount,
        protocolDoseAmount: _selectedProtocol?.doseAmount,
        protocolDoseUnit: _selectedProtocol?.doseUnit.label,
        onValidityChanged: (isValid) {
          setState(() {
            _isRemainingAmountValid = isValid;
          });
        },
        onCurrentAmountChanged: (value) {
          setState(() {
            _currentAmount = value;

            if (value <= 0) {
              _currentContainerOpenedAt = null;
            }
          });
        },
      ),

      4 => UnopenedStep(
        containerType: _containerType,
        unopenedQuantity: _totalQuantity,
        onUnopenedQuantityChanged: (value) {
          setState(() {
            _totalQuantity = value;
          });
        },
      ),

      5 => AlertsStep(
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

      6 => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_requiresInitialBatchName) ...[
            const Text(
              'Supply name *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'This is the name Ghost will show on your inventory card. '
              'Renaming it does not change the linked protocol.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _displayNameController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: _selectedProtocol?.name ?? 'Supply name',
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Batch name *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Give this inventory a name you will recognize later '
              'when choosing which batch to open.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _batchNameController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                hintText: 'Example: QSC 50mg Kit',
                prefixIcon: Icon(Icons.label_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          AdvancedStep(
            vendorController: _vendorController,
            batchController: _batchController,
            notesController: _notesController,
            reconstitutionVolumeController: _reconstitutionVolumeController,
            storageInstructionsController: _storageInstructionsController,
            costController: _costController,
            currentContainerOpenedAt: _currentContainerOpenedAt,
            expirationDate: _expirationDate,
            purchaseDate: _purchaseDate,
            hasOpenContainer:
                _activeContainerSource != ActiveContainerSource.none,
            containerType: _containerType,
            unit: _activeContainerUnit,
            onOpenedDateChanged: (value) {
              setState(() {
                _currentContainerOpenedAt = value;
              });
            },
            onExpirationDateChanged: (value) {
              setState(() {
                _expirationDate = value;
              });
            },
            onPurchaseDateChanged: (value) {
              setState(() {
                _purchaseDate = value;
              });
            },
            onAdvancedFieldChanged: () {
              setState(() {});
            },
          ),
        ],
      ),

      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final stepLabel = switch (_currentStep) {
      0 => 'Protocol',
      1 => 'Container',
      2 => 'Current Supply',
      3 => 'Remaining Amount',
      4 => 'Quantity',
      5 => 'Alerts',
      6 => 'Advanced',
      _ => '',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Ghost Supply™' : 'Set Up Ghost Supply™',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'STEP ${_currentStep + 1} OF $_totalSteps',
                        style: TextStyle(
                          fontSize: AppTypography.micro,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      stepLabel,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: SingleChildScrollView(
                  key: ValueKey(_currentStep),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.55),
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
