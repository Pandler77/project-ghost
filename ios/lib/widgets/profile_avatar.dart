import 'dart:io';

import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../theme/arctic_icons.dart';

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
    1 => ArcticIcons.person,
    2 => ArcticIcons.face,
    3 => ArcticIcons.emoji_people,
    4 => ArcticIcons.child_care,
    5 => ArcticIcons.elderly,
    6 => ArcticIcons.groups,
    7 => ArcticIcons.pets,
    8 => ArcticIcons.cruelty_free,
    9 => ArcticIcons.flutter_dash,
    10 => ArcticIcons.set_meal,
    11 => ArcticIcons.favorite,
    12 => ArcticIcons.vaccines,
    13 => ArcticIcons.medical_services,
    14 => ArcticIcons.monitor_heart,
    15 => ArcticIcons.fitness_center,
    16 => ArcticIcons.psychology,
    17 => ArcticIcons.eco,
    18 => ArcticIcons.dark_mode,
    19 => ArcticIcons.light_mode,
    20 => ArcticIcons.star,
    21 => ArcticIcons.local_fire_department,
    22 => ArcticIcons.bolt,
    23 => ArcticIcons.shield,
    24 => ArcticIcons.workspace_premium,
    25 => ArcticIcons.rocket_launch,
    26 => ArcticIcons.diamond,
    27 => ArcticIcons.track_changes,
    28 => ArcticIcons.settings,
    _ => _defaultIconForType(profile.type),
  };
}

IconData _defaultIconForType(ProfileType type) {
  return switch (type) {
    ProfileType.self => ArcticIcons.person,
    ProfileType.familyMember => ArcticIcons.groups,
    ProfileType.child => ArcticIcons.child_care,
    ProfileType.pet => ArcticIcons.pets,
    ProfileType.other => ArcticIcons.account_circle,
  };
}
