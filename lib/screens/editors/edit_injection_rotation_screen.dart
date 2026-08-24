import 'package:flutter/material.dart';

import '../../models/injection_site.dart';
import '../../models/protocol.dart';
import '../../models/rotation_mode.dart';
import '../../theme/app_theme.dart';
import '../../widgets/protocol_editor/injection_rotation_editor.dart';

class EditInjectionRotationScreen extends StatefulWidget {
  const EditInjectionRotationScreen({required this.protocol, super.key});

  final Protocol protocol;

  @override
  State<EditInjectionRotationScreen> createState() =>
      _EditInjectionRotationScreenState();
}

class _EditInjectionRotationScreenState
    extends State<EditInjectionRotationScreen> {
  late bool _rotationEnabled;
  late RotationMode _rotationMode;
  late Set<InjectionSite> _enabledSites;

  @override
  void initState() {
    super.initState();

    _rotationEnabled = widget.protocol.rotationEnabled;
    _rotationMode = widget.protocol.rotationMode;
    _enabledSites = Set<InjectionSite>.from(
      widget.protocol.enabledInjectionSites,
    );

    if (_rotationEnabled && _enabledSites.length < 2) {
      _seedDefaultSites();
    }
  }

  void _seedDefaultSites() {
    if (_enabledSites.length >= 2) {
      return;
    }

    final defaults = InjectionSite.values.take(2);

    for (final site in defaults) {
      _enabledSites.add(site);
    }
  }

  void _toggleRotation(bool value) {
    setState(() {
      _rotationEnabled = value;

      if (value && _enabledSites.length < 2) {
        _seedDefaultSites();
      }
    });
  }

  void _save() {
    if (_rotationEnabled && _enabledSites.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least two injection sites.')),
      );
      return;
    }

    Navigator.pop(
      context,
      widget.protocol.copyWith(
        rotationEnabled: _rotationEnabled,
        rotationMode: _rotationMode,
        enabledInjectionSites: Set<InjectionSite>.from(_enabledSites),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Injection Rotation',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Use injection site rotation',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        'MODOSE will use these settings for future site '
                        'suggestions. Existing injection history stays intact.',
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          color: colors.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      value: _rotationEnabled,
                      onChanged: _toggleRotation,
                    ),
                  ),

                  if (_rotationEnabled) ...[
                    const SizedBox(height: AppSpacing.md),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      child: Text(
                        'Select at least two sites. Changes affect the next '
                        'recommended site without rewriting previous logs.',
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          color: colors.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    InjectionRotationEditor(
                      rotationMode: _rotationMode,
                      enabledSites: _enabledSites,
                      onRotationModeChanged: (mode) {
                        setState(() {
                          _rotationMode = mode;
                        });
                      },
                      onSiteChanged: (site, enabled) {
                        setState(() {
                          if (enabled) {
                            _enabledSites.add(site);
                          } else {
                            _enabledSites.remove(site);
                          }
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
              ),
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(_rotationEnabled ? 'Save Rotation' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

