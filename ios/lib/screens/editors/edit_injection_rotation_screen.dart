import 'package:flutter/material.dart';

import '../../models/injection_site.dart';
import '../../models/protocol.dart';
import '../../models/rotation_mode.dart';
import '../../theme/app_theme.dart';
import '../../widgets/protocol_editor/injection_rotation_editor.dart';

class EditInjectionRotationScreen extends StatefulWidget {
  const EditInjectionRotationScreen({
    required this.protocol,
    super.key,
  });

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
  }

  void _save() {
    if (_rotationEnabled && _enabledSites.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least two injection sites.'),
        ),
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
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Use injection site rotation',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      'Changes apply to future suggestions only. Historical '
                      'injection logs are not changed.',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    value: _rotationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _rotationEnabled = value;
                      });
                    },
                  ),
                  if (_rotationEnabled) ...[
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
                border: Border(
                  top: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
              ),
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save Rotation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
