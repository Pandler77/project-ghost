import '../core/database/app_database.dart';
import '../core/repository/profile_repository.dart';
import '../models/profile.dart';
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

    final savedProfileId = await _settingsService.getActiveProfileId();

    if (savedProfileId != null) {
      for (final profile in profiles) {
        if (profile.id == savedProfileId) {
          return profile;
        }
      }
    }

    final fallbackProfile = profiles.first;

    await _settingsService.saveActiveProfileId(fallbackProfile.id);

    return fallbackProfile;
  }

  Future<void> setActiveProfile(String profileId) async {
    final exists = await _repository.profileExists(profileId);

    if (!exists) {
      throw StateError('Cannot activate a profile that does not exist.');
    }

    await _settingsService.saveActiveProfileId(profileId);
  }

  Future<Profile> createProfile({
    required String name,
    required ProfileType type,
    int? iconCodePoint,
    int? colorValue,
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

    await _settingsService.saveActiveProfileId(remainingProfiles.first.id);
  }
}

class ProfileLimitReachedException implements Exception {
  const ProfileLimitReachedException();

  @override
  String toString() {
    return 'Ghost Premium is required to add another profile.';
  }
}

class CannotDeleteLastProfileException implements Exception {
  const CannotDeleteLastProfileException();

  @override
  String toString() {
    return 'The final remaining profile cannot be deleted.';
  }
}
