import 'package:flutter/material.dart';

import '../models/dose_unit.dart';
import '../models/injection_site.dart';
import '../models/injection_site_suggestion.dart';
import '../models/protocol.dart';
import '../models/take_dose_result.dart';
import '../theme/app_theme.dart';
import 'injection_body_map.dart';
import '../theme/arctic_icons.dart';

class TakeDoseSheet extends StatefulWidget {
  const TakeDoseSheet({
    required this.protocol,
    required this.injectionSiteSuggestionFuture,
    required this.onSkip,
    super.key,
  });

  final Protocol protocol;
  final Future<InjectionSiteSuggestion> injectionSiteSuggestionFuture;
  final Future<void> Function() onSkip;

  static Future<TakeDoseResult?> show({
    required BuildContext context,
    required Protocol protocol,
    required Future<InjectionSiteSuggestion> injectionSiteSuggestionFuture,
    required Future<void> Function() onSkip,
  }) {
    return showModalBottomSheet<TakeDoseResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        return TakeDoseSheet(
          protocol: protocol,
          injectionSiteSuggestionFuture: injectionSiteSuggestionFuture,
          onSkip: onSkip,
        );
      },
    );
  }

  @override
  State<TakeDoseSheet> createState() => _TakeDoseSheetState();
}

class _TakeDoseSheetState extends State<TakeDoseSheet> {
  late final TextEditingController _doseController;
  late DoseUnit _selectedDoseUnit;
  late InjectionSite? _selectedInjectionSite;

  InjectionSite? _previousInjectionSite;

  bool _isEditingDose = false;
  bool _isLoadingInjectionSite = false;

  DoseChangeScope _changeScope = DoseChangeScope.thisDoseOnly;

  @override
  void initState() {
    super.initState();

    _doseController = TextEditingController(
      text: _formatAmount(widget.protocol.doseAmount),
    );

    _selectedDoseUnit = widget.protocol.doseUnit;
    _selectedInjectionSite = null;

    if (_shouldShowInjectionSite) {
      _loadSuggestedInjectionSite();
    }
  }

  @override
  void dispose() {
    _doseController.dispose();
    super.dispose();
  }

  bool get _shouldShowInjectionSite {
    return widget.protocol.isInjection && widget.protocol.rotationEnabled;
  }

  double? get _enteredDoseAmount {
    return double.tryParse(_doseController.text.trim());
  }

  bool get _doseWasChanged {
    final amount = _enteredDoseAmount;

    if (amount == null) {
      return false;
    }

    return amount != widget.protocol.doseAmount ||
        _selectedDoseUnit != widget.protocol.doseUnit;
  }

  bool get _canConfirm {
    final amount = _enteredDoseAmount;

    if (amount == null || amount <= 0) {
      return false;
    }

    if (_shouldShowInjectionSite &&
        (_isLoadingInjectionSite || _selectedInjectionSite == null)) {
      return false;
    }

    return true;
  }

  void _confirm() {
    final amount = _enteredDoseAmount;

    if (amount == null || amount <= 0) {
      return;
    }

    Navigator.pop(
      context,
      TakeDoseResult(
        actualDoseAmount: amount,
        actualDoseUnit: _selectedDoseUnit,
        doseWasChanged: _doseWasChanged,
        changeScope: _doseWasChanged ? _changeScope : null,
        injectionSite: _shouldShowInjectionSite ? _selectedInjectionSite : null,
      ),
    );
  }

  Future<void> _skipDose() async {
    final shouldSkip = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Skip this dose?'),
          content: Text(
            '${widget.protocol.name} will be marked as skipped. '
            'No inventory will be used.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Skip Dose'),
            ),
          ],
        );
      },
    );

    if (shouldSkip != true || !mounted) {
      return;
    }

    await widget.onSkip();

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  Future<void> _loadSuggestedInjectionSite() async {
    setState(() {
      _isLoadingInjectionSite = true;
    });

    try {
      final suggestion = await widget.injectionSiteSuggestionFuture;

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedInjectionSite = suggestion.recommendedSite;
        _previousInjectionSite = suggestion.previousSite;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInjectionSite = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + keyboardInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            Text(
              'Take Dose',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: AppSpacing.lg),

            _SectionCard(
              child: _isEditingDose
                  ? _buildDoseEditor(context)
                  : _buildScheduledDose(context),
            ),

            if (_doseWasChanged) ...[
              const SizedBox(height: AppSpacing.md),
              _buildDoseChangeScope(context),
            ],

            if (_shouldShowInjectionSite) ...[
              const SizedBox(height: AppSpacing.md),
              _buildInjectionSiteCard(context),
            ],

            const SizedBox(height: AppSpacing.lg),

            Center(
              child: SizedBox(
                width: 240,
                child: FilledButton.icon(
                  onPressed: _canConfirm ? _confirm : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text(
                    'Confirm Dose',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            Center(
              child: SizedBox(
                width: 240,
                child: OutlinedButton.icon(
                  onPressed: _skipDose,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                    backgroundColor: Colors.orange.shade50,
                    side: BorderSide(color: Colors.orange.shade600, width: 1.5),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  label: const Text(
                    'Skip Dose',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledDose(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scheduled dose',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.protocol.dose,
                style: const TextStyle(
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          tooltip: 'Edit dose',
          onPressed: () {
            setState(() {
              _isEditingDose = true;
            });
          },
          icon: const Icon(ArcticIcons.edit_outlined),
        ),
      ],
    );
  }

  Widget _buildDoseEditor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Actual dose',
                style: TextStyle(
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                setState(() {
                  _isEditingDose = false;
                });
              },
              child: const Text('Done'),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _doseController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) {
                  setState(() {});
                },
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: DropdownButtonFormField<DoseUnit>(
                initialValue: _selectedDoseUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final unit in DoseUnit.values)
                    DropdownMenuItem(value: unit, child: Text(unit.label)),
                ],
                onChanged: (unit) {
                  if (unit == null) {
                    return;
                  }

                  setState(() {
                    _selectedDoseUnit = unit;
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        Text(
          'Scheduled: ${widget.protocol.dose}',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDoseChangeScope(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Apply dose change to',
            style: TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            'Choose whether this change affects only today or future scheduled doses.',
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          RadioGroup<DoseChangeScope>(
            groupValue: _changeScope,
            onChanged: (scope) {
              if (scope == null) {
                return;
              }

              setState(() {
                _changeScope = scope;
              });
            },
            child: const Column(
              children: [
                RadioListTile<DoseChangeScope>(
                  contentPadding: EdgeInsets.zero,
                  title: Text('This dose only'),
                  value: DoseChangeScope.thisDoseOnly,
                ),
                RadioListTile<DoseChangeScope>(
                  contentPadding: EdgeInsets.zero,
                  title: Text('This and future doses'),
                  subtitle: Text('Updates the saved protocol dose.'),
                  value: DoseChangeScope.thisAndFutureDoses,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInjectionSiteCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final site = _selectedInjectionSite;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Injection site',
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _isLoadingInjectionSite
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          ArcticIcons.location_on_outlined,
                          color: colorScheme.primary,
                        ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoadingInjectionSite
                          ? 'Finding recommended site...'
                          : 'Recommended site',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isLoadingInjectionSite
                          ? 'Please wait'
                          : site?.label ?? 'Choose an injection site',
                      style: const TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!_isLoadingInjectionSite) ...[
            const SizedBox(height: AppSpacing.md),

            InjectionBodyMap(
              enabledSites: widget.protocol.enabledInjectionSites,
              selectedSite: _selectedInjectionSite,
              previousSite: _previousInjectionSite,
              showDisabledSites: false,
              onSiteSelected: (site) {
                setState(() {
                  _selectedInjectionSite = site;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  static String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}
