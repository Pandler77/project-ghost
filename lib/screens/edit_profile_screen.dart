import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../theme/app_theme.dart';

enum EditProfileAction { saved, deleted }

class EditProfileResult {
  const EditProfileResult({required this.action, this.profile});

  final EditProfileAction action;
  final Profile? profile;
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    required this.profile,
    required this.canDelete,
    super.key,
  });

  final Profile profile;
  final bool canDelete;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;

  late ProfileType _selectedType;
  late int? _selectedColorValue;

  static const List<int?> _profileColors = [
    null,
    0xFF6750A4,
    0xFF3F51B5,
    0xFF1976D2,
    0xFF00897B,
    0xFF2E7D32,
    0xFFF57C00,
    0xFFC62828,
    0xFFAD1457,
    0xFF6D4C41,
  ];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.profile.name);

    _selectedType = widget.profile.type;
    _selectedColorValue = widget.profile.colorValue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile name is required.')),
      );

      return;
    }

    final updatedProfile = widget.profile.copyWith(
      name: name,
      type: _selectedType,
      colorValue: _selectedColorValue,
      updatedAt: DateTime.now(),
    );

    Navigator.pop(
      context,
      EditProfileResult(
        action: EditProfileAction.saved,
        profile: updatedProfile,
      ),
    );
  }

  Future<void> _delete() async {
    if (!widget.canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot delete the only remaining profile.'),
        ),
      );

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete profile?'),
          content: Text(
            'Deleting ${widget.profile.name} will permanently remove '
            'its protocols, dose history, weight records, and inventory.',
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
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    Navigator.pop(
      context,
      const EditProfileResult(action: EditProfileAction.deleted),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Center(
              child: _ProfilePreview(
                name: _nameController.text.trim().isEmpty
                    ? widget.profile.name
                    : _nameController.text.trim(),
                type: _selectedType,
                colorValue: _selectedColorValue,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                labelText: 'Profile name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            const Text(
              'Profile type',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            for (final type in ProfileType.values) ...[
              _ProfileTypeTile(
                type: type,
                selected: _selectedType == type,
                onTap: () {
                  setState(() {
                    _selectedType = type;
                  });
                },
              ),
              if (type != ProfileType.values.last)
                const SizedBox(height: AppSpacing.sm),
            ],

            const SizedBox(height: AppSpacing.lg),

            const Text(
              'Profile color',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            Text(
              'This color identifies the profile throughout Ghost.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colors.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final colorValue in _profileColors)
                  _ColorOption(
                    colorValue: colorValue,
                    selected: _selectedColorValue == colorValue,
                    onTap: () {
                      setState(() {
                        _selectedColorValue = colorValue;
                      });
                    },
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Changes'),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: Text(
                  widget.canDelete
                      ? 'Delete Profile'
                      : 'Cannot Delete Only Profile',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  side: BorderSide(
                    color: widget.canDelete
                        ? colors.error
                        : colors.outlineVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePreview extends StatelessWidget {
  const _ProfilePreview({
    required this.name,
    required this.type,
    required this.colorValue,
  });

  final String name;
  final ProfileType type;
  final int? colorValue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final backgroundColor = colorValue == null
        ? colors.primaryContainer
        : Color(colorValue!);

    final foregroundColor = colorValue == null
        ? colors.onPrimaryContainer
        : Colors.white;

    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(_profileTypeIcon(type), size: 42, color: foregroundColor),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          name,
          style: const TextStyle(
            fontSize: AppTypography.title,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          type.label,
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ProfileTypeTile extends StatelessWidget {
  const _ProfileTypeTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final ProfileType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? colors.primaryContainer
                : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected
                      ? colors.primary.withValues(alpha: 0.12)
                      : colors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _profileTypeIcon(type),
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  type.label,
                  style: const TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.colorValue,
    required this.selected,
    required this.onTap,
  });

  final int? colorValue;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final color = colorValue == null
        ? colors.primaryContainer
        : Color(colorValue!);

    return Semantics(
      button: true,
      selected: selected,
      label: colorValue == null
          ? 'Default profile color'
          : 'Profile color option',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 46,
          height: 46,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 3 : 1,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: selected
                ? Icon(
                    Icons.check,
                    size: 20,
                    color: colorValue == null
                        ? colors.onPrimaryContainer
                        : Colors.white,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

IconData _profileTypeIcon(ProfileType type) {
  return switch (type) {
    ProfileType.self => Icons.person,
    ProfileType.familyMember => Icons.people,
    ProfileType.child => Icons.child_care,
    ProfileType.pet => Icons.pets,
    ProfileType.other => Icons.account_circle,
  };
}
