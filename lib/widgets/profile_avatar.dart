import 'dart:io';

import 'package:flutter/material.dart';

import '../models/profile.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.profile,
    this.radius = 22,
    this.showBorder = false,
    super.key,
  });

  final Profile profile;
  final double radius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final diameter = radius * 2;

    final backgroundColor = profile.colorValue == null
        ? colors.primaryContainer
        : Color(profile.colorValue!);

    final foregroundColor = profile.colorValue == null
        ? colors.onPrimaryContainer
        : Colors.white;

    final avatarPath = profile.avatarImagePath;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder ? Border.all(color: colors.outlineVariant) : null,
      ),
      child: ClipOval(
        child: avatarPath != null && avatarPath.trim().isNotEmpty
            ? Image.file(
                File(avatarPath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _IconAvatar(
                    profile: profile,
                    backgroundColor: backgroundColor,
                    foregroundColor: foregroundColor,
                    radius: radius,
                  );
                },
              )
            : _IconAvatar(
                profile: profile,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                radius: radius,
              ),
      ),
    );
  }
}

class _IconAvatar extends StatelessWidget {
  const _IconAvatar({
    required this.profile,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.radius,
  });

  final Profile profile;
  final Color backgroundColor;
  final Color foregroundColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Center(
        child: Icon(
          profileAvatarIcon(profile),
          size: radius,
          color: foregroundColor,
        ),
      ),
    );
  }
}

IconData profileAvatarIcon(Profile profile) {
  final iconId = profile.iconCodePoint;

  return switch (iconId) {
    1 => Icons.person,
    2 => Icons.face,
    3 => Icons.emoji_people,
    4 => Icons.child_care,
    5 => Icons.elderly,
    6 => Icons.groups,
    7 => Icons.pets,
    8 => Icons.cruelty_free,
    9 => Icons.flutter_dash,
    10 => Icons.set_meal,
    11 => Icons.favorite,
    12 => Icons.vaccines,
    13 => Icons.medical_services,
    14 => Icons.monitor_heart,
    15 => Icons.fitness_center,
    16 => Icons.psychology,
    17 => Icons.eco,
    18 => Icons.dark_mode,
    19 => Icons.light_mode,
    20 => Icons.star,
    21 => Icons.local_fire_department,
    22 => Icons.bolt,
    23 => Icons.shield,
    24 => Icons.workspace_premium,
    25 => Icons.rocket_launch,
    26 => Icons.diamond,
    27 => Icons.track_changes,
    28 => Icons.settings,
    _ => _defaultIconForType(profile.type),
  };
}

IconData _defaultIconForType(ProfileType type) {
  return switch (type) {
    ProfileType.self => Icons.person,
    ProfileType.familyMember => Icons.groups,
    ProfileType.child => Icons.child_care,
    ProfileType.pet => Icons.pets,
    ProfileType.other => Icons.account_circle,
  };
}
