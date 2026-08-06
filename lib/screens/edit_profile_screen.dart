import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/profile_module.dart';
import '../services/profile_avatar_service.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_avatar.dart';
import 'profile_avatar_picker_screen.dart';

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
  final ProfileAvatarService _avatarService = ProfileAvatarService();

  late final TextEditingController _nameController;

  late ProfileType _selectedType;
  late int? _selectedColorValue;
  late int? _selectedAvatarId;
  late String? _selectedAvatarImagePath;
  late final Set<ProfileModule> _selectedModules;

  bool _isSavingPhoto = false;
  bool _didSave = false;

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
    _selectedAvatarId = widget.profile.iconCodePoint;
    _selectedAvatarImagePath = widget.profile.avatarImagePath;
    _selectedModules = {...widget.profile.enabledModules};
  }

  @override
  void dispose() {
    _nameController.dispose();

    final pendingPath = _selectedAvatarImagePath;
    final originalPath = widget.profile.avatarImagePath;

    if (!_didSave &&
        pendingPath != null &&
        pendingPath.isNotEmpty &&
        pendingPath != originalPath) {
      _avatarService.deleteAvatar(pendingPath);
    }

    super.dispose();
  }

  Future<void> _chooseBuiltInAvatar() async {
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
      _selectedAvatarImagePath = null;
    });
  }

  Future<void> _choosePhotoSource() async {
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text(
                    'Profile photo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Choose a photo source.'),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.pop(sheetContext, _PhotoAction.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take photo'),
                  onTap: () {
                    Navigator.pop(sheetContext, _PhotoAction.camera);
                  },
                ),
                if (_selectedAvatarImagePath != null)
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: Theme.of(sheetContext).colorScheme.error,
                    ),
                    title: Text(
                      'Remove photo',
                      style: TextStyle(
                        color: Theme.of(sheetContext).colorScheme.error,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext, _PhotoAction.remove);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null || !mounted) {
      return;
    }

    if (action == _PhotoAction.remove) {
      final currentPath = _selectedAvatarImagePath;
      final originalPath = widget.profile.avatarImagePath;

      if (currentPath != null &&
          currentPath.isNotEmpty &&
          currentPath != originalPath) {
        await _avatarService.deleteAvatar(currentPath);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedAvatarImagePath = null;
      });

      return;
    }

    setState(() {
      _isSavingPhoto = true;
    });

    try {
      final path = action == _PhotoAction.gallery
          ? await _avatarService.pickFromGallery(profileId: widget.profile.id)
          : await _avatarService.takePhoto(profileId: widget.profile.id);

      if (!mounted || path == null) {
        return;
      }

      final previousPendingPath = _selectedAvatarImagePath;
      final originalPath = widget.profile.avatarImagePath;

      if (previousPendingPath != null &&
          previousPendingPath.isNotEmpty &&
          previousPendingPath != originalPath &&
          previousPendingPath != path) {
        await _avatarService.deleteAvatar(previousPendingPath);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedAvatarImagePath = path;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile photo: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPhoto = false;
        });
      }
    }
  }

  void _resetBuiltInAvatar() {
    setState(() {
      _selectedAvatarId = null;
    });
  }

  Future<void> _save() async {
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

    final originalPhotoPath = widget.profile.avatarImagePath;
    final updatedPhotoPath = _selectedAvatarImagePath;

    if (originalPhotoPath != null &&
        originalPhotoPath.isNotEmpty &&
        originalPhotoPath != updatedPhotoPath) {
      await _avatarService.deleteAvatar(originalPhotoPath);
    }

    if (!mounted) {
      return;
    }

    final updatedProfile = widget.profile.copyWith(
      name: name,
      type: _selectedType,
      iconCodePoint: _selectedAvatarId,
      colorValue: _selectedColorValue,
      avatarImagePath: updatedPhotoPath,
      enabledModules: Set<ProfileModule>.from(_selectedModules),
      updatedAt: DateTime.now(),
    );

    _didSave = true;

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
            'its protocols, dose history, weight records, inventory, '
            'and profile photo.',
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

    await _avatarService.deleteAvatar(widget.profile.avatarImagePath);

    final pendingPath = _selectedAvatarImagePath;

    if (pendingPath != null &&
        pendingPath.isNotEmpty &&
        pendingPath != widget.profile.avatarImagePath) {
      await _avatarService.deleteAvatar(pendingPath);
    }

    if (!mounted) {
      return;
    }

    _didSave = true;

    Navigator.pop(
      context,
      const EditProfileResult(action: EditProfileAction.deleted),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final previewName = _nameController.text.trim().isEmpty
        ? widget.profile.name
        : _nameController.text.trim();

    final previewProfile = widget.profile.copyWith(
      name: previewName,
      type: _selectedType,
      iconCodePoint: _selectedAvatarId,
      colorValue: _selectedColorValue,
      avatarImagePath: _selectedAvatarImagePath,
      enabledModules: Set<ProfileModule>.from(_selectedModules),
      updatedAt: widget.profile.updatedAt,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
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

            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: _isSavingPhoto ? null : _choosePhotoSource,
                  icon: _isSavingPhoto
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_a_photo_outlined),
                  label: Text(
                    _selectedAvatarImagePath == null
                        ? 'Choose Photo'
                        : 'Change Photo',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _chooseBuiltInAvatar,
                  icon: const Icon(Icons.account_circle_outlined),
                  label: Text(
                    _selectedAvatarId == null ? 'Choose Icon' : 'Change Icon',
                  ),
                ),
                if (_selectedAvatarId != null &&
                    _selectedAvatarImagePath == null)
                  TextButton(
                    onPressed: _resetBuiltInAvatar,
                    child: const Text('Reset Icon'),
                  ),
              ],
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

            const Text(
              'Tracking Modules',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            Text(
              'Choose which features this profile uses.',
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
                onPressed: _isSavingPhoto ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Changes'),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSavingPhoto ? null : _delete,
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

enum _PhotoAction { gallery, camera, remove }

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
