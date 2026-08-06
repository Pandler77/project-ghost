import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/profile_module.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_avatar.dart';
import 'profile_avatar_picker_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  late final TextEditingController _nameController;

  ProfileType _selectedType = ProfileType.self;
  int? _selectedColorValue;
  int? _selectedAvatarId;

  final Set<ProfileModule> _selectedModules = {
    ...ProfileModuleDetails.defaultModules,
  };

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
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _chooseAvatar() async {
    final selectedAvatarId = await Navigator.push<int?>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProfileAvatarPickerScreen(selectedAvatarId: _selectedAvatarId),
      ),
    );

    if (!mounted || selectedAvatarId == null) {
      return;
    }

    setState(() {
      _selectedAvatarId = selectedAvatarId;
    });
  }

  void _resetAvatar() {
    setState(() {
      _selectedAvatarId = null;
    });
  }

  void _save() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile name is required.')),
      );
      return;
    }

    if (_selectedModules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one tracking module.')),
      );
      return;
    }

    Navigator.pop(
      context,
      CreateProfileResult(
        name: name,
        type: _selectedType,
        colorValue: _selectedColorValue,
        iconCodePoint: _selectedAvatarId,
        enabledModules: Set<ProfileModule>.from(_selectedModules),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final previewName = _nameController.text.trim().isEmpty
        ? 'New Profile'
        : _nameController.text.trim();

    final previewProfile = Profile(
      name: previewName,
      type: _selectedType,
      iconCodePoint: _selectedAvatarId,
      colorValue: _selectedColorValue,
      enabledModules: _selectedModules,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Create Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const Text(
              'Who is this profile for?',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Each profile keeps protocols, doses, weight, inventory, and history separate.',
              style: TextStyle(
                fontSize: AppTypography.body,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Column(
                children: [
                  ProfileAvatar(
                    profile: previewProfile,
                    radius: 42,
                    showBorder: true,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    previewName,
                    style: const TextStyle(
                      fontSize: AppTypography.title,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedType.label,
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _chooseAvatar,
                  icon: const Icon(Icons.account_circle_outlined),
                  label: Text(
                    _selectedAvatarId == null
                        ? 'Choose Avatar'
                        : 'Change Avatar',
                  ),
                ),
                if (_selectedAvatarId != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: _resetAvatar,
                    child: const Text('Reset'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                labelText: 'Profile name',
                hintText: 'Frank',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'This profile is for',
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
            const Text(
              'What would you like to track?',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'These can be changed later in Profile Settings.',
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final module in ProfileModule.values)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _selectedModules.contains(module),
                title: Text(module.label),
                subtitle: Text(module.description),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedModules.add(module);
                    } else {
                      _selectedModules.remove(module);
                    }
                  });
                },
              ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Create Profile'),
              ),
            ),
          ],
        ),
      ),
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

class CreateProfileResult {
  const CreateProfileResult({
    required this.name,
    required this.type,
    required this.enabledModules,
    this.colorValue,
    this.iconCodePoint,
  });

  final String name;
  final ProfileType type;
  final int? colorValue;
  final int? iconCodePoint;
  final Set<ProfileModule> enabledModules;
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
