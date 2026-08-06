import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ProfileAvatarPickerScreen extends StatelessWidget {
  const ProfileAvatarPickerScreen({required this.selectedAvatarId, super.key});

  final int? selectedAvatarId;

  static const List<_AvatarOption> _avatarOptions = [
    _AvatarOption(
      id: 1,
      label: 'Person',
      icon: Icons.person,
      category: 'People',
    ),
    _AvatarOption(id: 2, label: 'Face', icon: Icons.face, category: 'People'),
    _AvatarOption(
      id: 3,
      label: 'Active',
      icon: Icons.emoji_people,
      category: 'People',
    ),
    _AvatarOption(
      id: 4,
      label: 'Child',
      icon: Icons.child_care,
      category: 'People',
    ),
    _AvatarOption(
      id: 5,
      label: 'Senior',
      icon: Icons.elderly,
      category: 'People',
    ),
    _AvatarOption(
      id: 6,
      label: 'Family',
      icon: Icons.groups,
      category: 'People',
    ),
    _AvatarOption(id: 7, label: 'Pet', icon: Icons.pets, category: 'Animals'),
    _AvatarOption(
      id: 8,
      label: 'Rabbit',
      icon: Icons.cruelty_free,
      category: 'Animals',
    ),
    _AvatarOption(
      id: 9,
      label: 'Bird',
      icon: Icons.flutter_dash,
      category: 'Animals',
    ),
    _AvatarOption(
      id: 10,
      label: 'Fish',
      icon: Icons.set_meal,
      category: 'Animals',
    ),
    _AvatarOption(
      id: 11,
      label: 'Heart',
      icon: Icons.favorite,
      category: 'Health',
    ),
    _AvatarOption(
      id: 12,
      label: 'Vaccine',
      icon: Icons.vaccines,
      category: 'Health',
    ),
    _AvatarOption(
      id: 13,
      label: 'Medical',
      icon: Icons.medical_services,
      category: 'Health',
    ),
    _AvatarOption(
      id: 14,
      label: 'ECG',
      icon: Icons.monitor_heart,
      category: 'Health',
    ),
    _AvatarOption(
      id: 15,
      label: 'Fitness',
      icon: Icons.fitness_center,
      category: 'Health',
    ),
    _AvatarOption(
      id: 16,
      label: 'Mind',
      icon: Icons.psychology,
      category: 'Health',
    ),
    _AvatarOption(id: 17, label: 'Leaf', icon: Icons.eco, category: 'Symbols'),
    _AvatarOption(
      id: 18,
      label: 'Moon',
      icon: Icons.dark_mode,
      category: 'Symbols',
    ),
    _AvatarOption(
      id: 19,
      label: 'Sun',
      icon: Icons.light_mode,
      category: 'Symbols',
    ),
    _AvatarOption(id: 20, label: 'Star', icon: Icons.star, category: 'Symbols'),
    _AvatarOption(
      id: 21,
      label: 'Flame',
      icon: Icons.local_fire_department,
      category: 'Symbols',
    ),
    _AvatarOption(id: 22, label: 'Bolt', icon: Icons.bolt, category: 'Symbols'),
    _AvatarOption(
      id: 23,
      label: 'Shield',
      icon: Icons.shield,
      category: 'Symbols',
    ),
    _AvatarOption(
      id: 24,
      label: 'Crown',
      icon: Icons.workspace_premium,
      category: 'Symbols',
    ),
    _AvatarOption(
      id: 25,
      label: 'Rocket',
      icon: Icons.rocket_launch,
      category: 'Symbols',
    ),
    _AvatarOption(
      id: 26,
      label: 'Diamond',
      icon: Icons.diamond,
      category: 'Symbols',
    ),
    _AvatarOption(
      id: 27,
      label: 'Target',
      icon: Icons.track_changes,
      category: 'Symbols',
    ),
    _AvatarOption(
      id: 28,
      label: 'Gear',
      icon: Icons.settings,
      category: 'Symbols',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final groupedOptions = <String, List<_AvatarOption>>{};

    for (final option in _avatarOptions) {
      groupedOptions.putIfAbsent(option.category, () => <_AvatarOption>[]);

      groupedOptions[option.category]!.add(option);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Avatar'),
        actions: [
          if (selectedAvatarId != null)
            TextButton(
              onPressed: () {
                Navigator.pop<int?>(context, null);
              },
              child: const Text('Reset'),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Choose a built-in avatar for this profile. You can add a photo later.',
              style: TextStyle(
                fontSize: AppTypography.body,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final entry in groupedOptions.entries) ...[
              Text(
                entry.key,
                style: const TextStyle(
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entry.value.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.92,
                ),
                itemBuilder: (context, index) {
                  final option = entry.value[index];
                  final isSelected = selectedAvatarId == option.id;

                  return _AvatarTile(
                    option: option,
                    selected: isSelected,
                    onTap: () {
                      Navigator.pop<int>(context, option.id);
                    },
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _AvatarOption option;
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
          decoration: BoxDecoration(
            color: selected
                ? colors.primaryContainer
                : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  option.icon,
                  size: 32,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? colors.primary : colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarOption {
  const _AvatarOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.category,
  });

  final int id;
  final String label;
  final IconData icon;
  final String category;
}
