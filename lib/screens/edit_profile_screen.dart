import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/profile_module.dart';
import '../services/profile_avatar_service.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_avatar.dart';
import 'profile_avatar_picker_screen.dart';
import '../services/profile_service.dart';
import '../widgets/app_color_picker.dart';

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
  final ProfileService _profileService = ProfileService();

  late Profile _persistedProfile;

  late final TextEditingController _nameController;

  late ProfileType _selectedType;
  late int? _selectedColorValue;
  late int? _selectedAvatarId;
  late String? _selectedAvatarImagePath;
  late final Set<ProfileModule> _selectedModules;

  bool _isSavingPhoto = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.profile.name);

    _selectedType = widget.profile.type;
    _selectedColorValue = widget.profile.colorValue;
    _selectedAvatarId = widget.profile.iconCodePoint;
    _selectedAvatarImagePath = widget.profile.avatarImagePath;
    _selectedModules = {...widget.profile.enabledModules};
    _persistedProfile = widget.profile;
  }

  @override
  void dispose() {
    _nameController.dispose();
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

    final previousPhotoPath = _persistedProfile.avatarImagePath;

    final updatedProfile = _persistedProfile.copyWith(
      iconCodePoint: selectedAvatarId,
      avatarImagePath: null,
      updatedAt: DateTime.now(),
    );

    try {
      await _profileService.updateProfile(updatedProfile);

      if (previousPhotoPath != null && previousPhotoPath.isNotEmpty) {
        await _avatarService.deleteAvatar(previousPhotoPath);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _persistedProfile = updatedProfile;
        _selectedAvatarId = selectedAvatarId;
        _selectedAvatarImagePath = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile icon: $error')),
      );
    }
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
      final previousPhotoPath = _persistedProfile.avatarImagePath;

      final updatedProfile = _persistedProfile.copyWith(
        avatarImagePath: null,
        updatedAt: DateTime.now(),
      );

      try {
        await _profileService.updateProfile(updatedProfile);

        if (previousPhotoPath != null && previousPhotoPath.isNotEmpty) {
          await _avatarService.deleteAvatar(previousPhotoPath);
        }

        if (!mounted) {
          return;
        }

        setState(() {
          _persistedProfile = updatedProfile;
          _selectedAvatarImagePath = null;
        });
      } catch (error) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove profile photo: $error')),
        );
      }

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

      final previousPhotoPath = _persistedProfile.avatarImagePath;

      final updatedProfile = _persistedProfile.copyWith(
        avatarImagePath: path,
        iconCodePoint: null,
        updatedAt: DateTime.now(),
      );

      await _profileService.updateProfile(updatedProfile);

      if (previousPhotoPath != null &&
          previousPhotoPath.isNotEmpty &&
          previousPhotoPath != path) {
        await _avatarService.deleteAvatar(previousPhotoPath);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _persistedProfile = updatedProfile;
        _selectedAvatarImagePath = path;
        _selectedAvatarId = null;
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

  Future<void> _resetBuiltInAvatar() async {
    final updatedProfile = _persistedProfile.copyWith(
      iconCodePoint: null,
      updatedAt: DateTime.now(),
    );

    try {
      await _profileService.updateProfile(updatedProfile);

      if (!mounted) {
        return;
      }

      setState(() {
        _persistedProfile = updatedProfile;
        _selectedAvatarId = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not reset profile icon: $error')),
      );
    }
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

    final updatedProfile = _persistedProfile.copyWith(
      name: name,
      type: _selectedType,
      iconCodePoint: _selectedAvatarId,
      colorValue: _selectedColorValue,
      avatarImagePath: _selectedAvatarImagePath,
      enabledModules: Set<ProfileModule>.from(_selectedModules),
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

    await _avatarService.deleteAvatar(_persistedProfile.avatarImagePath);

    if (!mounted) {
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

    final previewName = _nameController.text.trim().isEmpty
        ? widget.profile.name
        : _nameController.text.trim();

    final previewProfile = _persistedProfile.copyWith(
      name: previewName,
      type: _selectedType,
      iconCodePoint: _selectedAvatarId,
      colorValue: _selectedColorValue,
      avatarImagePath: _selectedAvatarImagePath,
      enabledModules: Set<ProfileModule>.from(_selectedModules),
      updatedAt: _persistedProfile.updatedAt,
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

            AppColorPicker(
              selectedColorValue: _selectedColorValue,
              allowDefault: true,
              onColorChanged: (value) {
                setState(() {
                  _selectedColorValue = value;
                });
              },
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

IconData _profileTypeIcon(ProfileType type) {
  return switch (type) {
    ProfileType.self => Icons.person,
    ProfileType.familyMember => Icons.people,
    ProfileType.child => Icons.child_care,
    ProfileType.pet => Icons.pets,
    ProfileType.other => Icons.account_circle,
  };
}
