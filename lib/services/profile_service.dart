import '../core/database/app_database.dart';
import '../core/repository/profile_repository.dart';
import '../models/profile.dart';
import '../models/profile_module.dart';
import 'entitlement_service.dart';
import 'settings_service.dart';

class ProfileService {
  ProfileService({
    ProfileRepository? repository,
    SettingsService? settingsService,
    EntitlementService? entitlementService,
  }) : _repository = repository ?? ProfileRepository(),
       _settingsService = settingsService ?? SettingsService(),
       _entitlementService = entitlementService ?? EntitlementService.instance;

  final ProfileRepository _repository;
  final SettingsService _settingsService;
  final EntitlementService _entitlementService;

  bool get hasPremium => _entitlementService.hasPremium;

  Future<List<Profile>> getProfiles() {
    return _repository.getProfiles();
  }

  Future<Profile> getActiveProfile() async {
    final profiles = await _repository.getProfiles();

    if (profiles.isEmpty) {
      final defaultProfile = Profile(
        id: AppDatabase.defaultProfileId,
        name: 'Frank',
        type: ProfileType.self,
      );

      await _repository.saveProfile(defaultProfile);
      await _settingsService.saveActiveProfileId(defaultProfile.id);

      return defaultProfile;
    }

    final freeProfile = _resolveFreeProfile(profiles);

    final savedProfileId = await _settingsService.getActiveProfileId();

    if (savedProfileId != null) {
      for (final profile in profiles) {
        if (profile.id != savedProfileId) {
          continue;
        }

        if (hasPremium || profile.id == freeProfile.id) {
          return profile;
        }

        break;
      }
    }

    await _settingsService.saveActiveProfileId(freeProfile.id);

    return freeProfile;
  }

  Future<void> setActiveProfile(String profileId) async {
    final profiles = await _repository.getProfiles();

    Profile? requestedProfile;

    for (final profile in profiles) {
      if (profile.id == profileId) {
        requestedProfile = profile;
        break;
      }
    }

    if (requestedProfile == null) {
      throw StateError('Cannot activate a profile that does not exist.');
    }

    if (!hasPremium) {
      final freeProfile = _resolveFreeProfile(profiles);

      if (requestedProfile.id != freeProfile.id) {
        throw const ProfileAccessRequiresPremiumException();
      }
    }

    await _settingsService.saveActiveProfileId(requestedProfile.id);
  }

  Future<bool> canAccessProfile(String profileId) async {
    if (hasPremium) {
      return true;
    }

    final profiles = await _repository.getProfiles();

    if (profiles.isEmpty) {
      return false;
    }

    final freeProfile = _resolveFreeProfile(profiles);

    return profileId == freeProfile.id;
  }

  Future<String?> getFreeProfileId() async {
    final profiles = await _repository.getProfiles();

    if (profiles.isEmpty) {
      return null;
    }

    return _resolveFreeProfile(profiles).id;
  }

  Profile _resolveFreeProfile(List<Profile> profiles) {
    for (final profile in profiles) {
      if (profile.id == AppDatabase.defaultProfileId) {
        return profile;
      }
    }

    final orderedProfiles = [...profiles]
      ..sort((first, second) => first.createdAt.compareTo(second.createdAt));

    return orderedProfiles.first;
  }

  Future<Profile> createProfile({
    required String name,
    required ProfileType type,
    int? iconCodePoint,
    int? colorValue,
    String? avatarImagePath,
    double? startingWeight,
    double? goalWeight,
    double? heightCm,
    Set<ProfileModule>? enabledModules,
  }) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Profile name cannot be empty.');
    }

    final profileCount = await _repository.getProfileCount();

    if (!hasPremium && profileCount >= 1) {
      throw const ProfileLimitReachedException();
    }

    final profile = Profile(
      name: trimmedName,
      type: type,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      avatarImagePath: avatarImagePath,
      startingWeight: startingWeight,
      goalWeight: goalWeight,
      heightCm: heightCm,
      enabledModules: enabledModules ?? ProfileModuleDetails.defaultModules,
    );

    await _repository.saveProfile(profile);

    return profile;
  }

  Future<void> updateProfile(Profile profile) async {
    final trimmedName = profile.name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Profile name cannot be empty.');
    }

    await _repository.saveProfile(
      profile.copyWith(name: trimmedName, updatedAt: DateTime.now()),
    );
  }

  Future<void> deleteProfile(String profileId) async {
    final profiles = await _repository.getProfiles();

    if (profiles.length <= 1) {
      throw const CannotDeleteLastProfileException();
    }

    final activeProfileId = await _settingsService.getActiveProfileId();

    await _repository.deleteProfile(profileId);

    if (activeProfileId != profileId) {
      return;
    }

    final remainingProfiles = await _repository.getProfiles();

    if (remainingProfiles.isEmpty) {
      await _settingsService.clearActiveProfileId();
      return;
    }

    final fallbackProfile = hasPremium
        ? remainingProfiles.first
        : _resolveFreeProfile(remainingProfiles);

    await _settingsService.saveActiveProfileId(fallbackProfile.id);
  }
}

class ProfileLimitReachedException implements Exception {
  const ProfileLimitReachedException();

  @override
  String toString() {
    return 'Ghost Premium is required to add another profile.';
  }
}

class ProfileAccessRequiresPremiumException implements Exception {
  const ProfileAccessRequiresPremiumException();

  @override
  String toString() {
    return 'Ghost Premium is required to access this profile.';
  }
}

class CannotDeleteLastProfileException implements Exception {
  const CannotDeleteLastProfileException();

  @override
  String toString() {
    return 'The final remaining profile cannot be deleted.';
  }
}
