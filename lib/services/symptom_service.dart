import '../core/repository/symptom_entry_repository.dart';
import '../models/symptom_entry.dart';
import 'profile_service.dart';
import '../core/repository/symptom_protocol_link_repository.dart';

class SymptomService {
  SymptomService({
    SymptomEntryRepository? repository,
    SymptomProtocolLinkRepository? linkRepository,
    ProfileService? profileService,
  }) : _repository = repository ?? SymptomEntryRepository(),
       _linkRepository = linkRepository ?? SymptomProtocolLinkRepository(),
       _profileService = profileService ?? ProfileService();

  final SymptomEntryRepository _repository;
  final SymptomProtocolLinkRepository _linkRepository;
  final ProfileService _profileService;

  Future<SymptomEntry> createEntry({
    required String symptomName,
    required int severity,
    required DateTime recordedAt,
    String? notes,
    List<String> protocolIds = const [],
  }) async {
    final trimmedName = symptomName.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Symptom name is required.');
    }

    if (severity < 1 || severity > 5) {
      throw ArgumentError('Severity must be between 1 and 5.');
    }

    final profile = await _profileService.getActiveProfile();
    final now = DateTime.now();

    final entry = SymptomEntry(
      id: now.microsecondsSinceEpoch.toString(),
      profileId: profile.id,
      symptomName: trimmedName,
      severity: severity,
      notes: _optionalText(notes),
      recordedAt: recordedAt,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.insert(entry);

    await _linkRepository.replaceLinks(
      symptomEntryId: entry.id,
      protocolIds: protocolIds,
    );

    return entry;
  }

  Future<void> updateEntry(
    SymptomEntry entry, {
    List<String>? protocolIds,
  }) async {
    final trimmedName = entry.symptomName.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Symptom name is required.');
    }

    if (entry.severity < 1 || entry.severity > 5) {
      throw ArgumentError('Severity must be between 1 and 5.');
    }

    final updated = entry.copyWith(
      symptomName: trimmedName,
      notes: _optionalText(entry.notes),
      updatedAt: DateTime.now(),
    );

    await _repository.update(updated);

    if (protocolIds != null) {
      await _linkRepository.replaceLinks(
        symptomEntryId: entry.id,
        protocolIds: protocolIds,
      );
    }
  }

  Future<void> deleteEntry(String entryId) {
    return _repository.delete(entryId);
  }

  Future<SymptomEntry?> getById(String entryId) {
    return _repository.getById(entryId);
  }

  Future<List<SymptomEntry>> getAllEntries() async {
    final profile = await _profileService.getActiveProfile();

    return _repository.getAll(profile.id);
  }

  Future<List<SymptomEntry>> getEntriesForDate(DateTime date) async {
    final profile = await _profileService.getActiveProfile();

    return _repository.getByDate(profile.id, date);
  }

  Future<List<SymptomEntry>> getEntriesForSymptom(String symptomName) async {
    final profile = await _profileService.getActiveProfile();

    return _repository.getBySymptom(profile.id, symptomName);
  }

  Future<List<SymptomEntry>> getEntriesBetween(
    DateTime start,
    DateTime end,
  ) async {
    final profile = await _profileService.getActiveProfile();

    return _repository.getBetween(profile.id, start, end);
  }

  Future<List<String>> getSymptomNames() async {
    final profile = await _profileService.getActiveProfile();

    return _repository.getSymptomNames(profile.id);
  }

  String? _optionalText(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  Future<List<String>> getProtocolIdsForEntry(String entryId) {
    return _linkRepository.getProtocolIdsForEntry(entryId);
  }

  Future<Map<String, List<String>>> getProtocolIdsForEntries(
    List<String> entryIds,
  ) {
    return _linkRepository.getProtocolIdsForEntries(entryIds);
  }
}
