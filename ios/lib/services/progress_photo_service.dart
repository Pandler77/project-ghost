import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../core/repository/progress_photo_repository.dart';
import '../core/repository/progress_photo_session_repository.dart';
import '../models/progress_photo.dart';
import '../models/progress_photo_session.dart';
import 'profile_service.dart';

class ProgressPhotoService {
  ProgressPhotoService({
    ImagePicker? imagePicker,
    ProgressPhotoRepository? repository,
    ProgressPhotoSessionRepository? sessionRepository,
    ProfileService? profileService,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       _repository = repository ?? ProgressPhotoRepository(),
       _sessionRepository =
           sessionRepository ?? ProgressPhotoSessionRepository(),
       _profileService = profileService ?? ProfileService();

  final ImagePicker _imagePicker;
  final ProgressPhotoRepository _repository;
  final ProgressPhotoSessionRepository _sessionRepository;
  final ProfileService _profileService;

  Future<ProgressPhoto?> pickAndSaveFromGallery({
    required ProgressPhotoType type,
    required DateTime recordedAt,
    double? weight,
    String? notes,
  }) {
    return _pickAndSave(
      source: ImageSource.gallery,
      type: type,
      recordedAt: recordedAt,
      weight: weight,
      notes: notes,
    );
  }

  Future<ProgressPhoto?> takeAndSavePhoto({
    required ProgressPhotoType type,
    required DateTime recordedAt,
    double? weight,
    String? notes,
  }) {
    return _pickAndSave(
      source: ImageSource.camera,
      type: type,
      recordedAt: recordedAt,
      weight: weight,
      notes: notes,
    );
  }

  Future<void> updatePhoto(ProgressPhoto photo) async {
    await _repository.update(photo.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> updateSessionDetails(ProgressPhotoSession session) async {
    final updatedSession = session.copyWith(updatedAt: DateTime.now());

    await _sessionRepository.update(updatedSession);

    final photos = await _repository.getBySession(session.id);

    for (final photo in photos) {
      await _repository.update(
        photo.copyWith(
          recordedAt: updatedSession.recordedAt,
          weight: updatedSession.weight,
          notes: updatedSession.notes,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> deletePhoto(ProgressPhoto photo) async {
    final file = File(photo.imagePath);

    if (await file.exists()) {
      await file.delete();
    }

    await _repository.delete(photo.id);
  }

  Future<List<ProgressPhoto>> getAllPhotos() async {
    final profile = await _profileService.getActiveProfile();

    return _repository.getAll(profile.id);
  }

  Future<List<ProgressPhoto>> getPhotosByType(ProgressPhotoType type) async {
    final profile = await _profileService.getActiveProfile();

    return _repository.getByType(profile.id, type);
  }

  Future<List<ProgressPhotoSession>> getAllSessions() async {
    final profile = await _profileService.getActiveProfile();

    return _sessionRepository.getAll(profile.id);
  }

  Future<List<ProgressPhotoSession>> getSessionsForDate(DateTime date) async {
    final sessions = await getAllSessions();

    return sessions
        .where((session) {
          final recordedAt = session.recordedAt;

          return recordedAt.year == date.year &&
              recordedAt.month == date.month &&
              recordedAt.day == date.day;
        })
        .toList(growable: false);
  }

  Future<List<ProgressPhoto>> getPhotosForSession(String sessionId) {
    return _repository.getBySession(sessionId);
  }

  Future<void> deleteSession(ProgressPhotoSession session) async {
    final photos = await _repository.getBySession(session.id);

    for (final photo in photos) {
      final file = File(photo.imagePath);

      if (await file.exists()) {
        await file.delete();
      }
    }

    await _sessionRepository.delete(session.id);
  }

  Future<ProgressPhotoSession> createSession({
    required DateTime recordedAt,
    double? weight,
    String? notes,
  }) async {
    final profile = await _profileService.getActiveProfile();

    final session = ProgressPhotoSession(
      profileId: profile.id,
      recordedAt: recordedAt,
      weight: weight,
      notes: _optionalText(notes),
    );

    await _sessionRepository.insert(session);

    return session;
  }

  Future<List<ProgressPhotoSession>> getSessionsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final sessions = await getAllSessions();

    return sessions
        .where((session) {
          return !session.recordedAt.isBefore(start) &&
              session.recordedAt.isBefore(end);
        })
        .toList(growable: false);
  }

  Future<ProgressPhoto?> pickAndSaveFromGalleryForSession({
    required String sessionId,
    required ProgressPhotoType type,
    required DateTime recordedAt,
    double? weight,
    String? notes,
  }) {
    return _pickAndSave(
      source: ImageSource.gallery,
      type: type,
      recordedAt: recordedAt,
      weight: weight,
      notes: notes,
      sessionId: sessionId,
    );
  }

  Future<ProgressPhoto?> takeAndSavePhotoForSession({
    required String sessionId,
    required ProgressPhotoType type,
    required DateTime recordedAt,
    double? weight,
    String? notes,
  }) {
    return _pickAndSave(
      source: ImageSource.camera,
      type: type,
      recordedAt: recordedAt,
      weight: weight,
      notes: notes,
      sessionId: sessionId,
    );
  }

  Future<ProgressPhoto?> _pickAndSave({
    required ImageSource source,
    required ProgressPhotoType type,
    required DateTime recordedAt,
    double? weight,
    String? notes,
    String? sessionId,
  }) async {
    final pickedImage = await _imagePicker.pickImage(
      source: source,
      imageQuality: 90,
    );

    if (pickedImage == null) {
      return null;
    }

    final sourceFile = File(pickedImage.path);

    if (!await sourceFile.exists()) {
      throw StateError('The selected image file could not be found.');
    }

    final profile = await _profileService.getActiveProfile();

    var resolvedSessionId = sessionId;

    if (resolvedSessionId == null) {
      final session = ProgressPhotoSession(
        profileId: profile.id,
        recordedAt: recordedAt,
        weight: weight,
        notes: _optionalText(notes),
      );

      await _sessionRepository.insert(session);

      resolvedSessionId = session.id;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();

    final progressDirectory = Directory(
      path.join(
        documentsDirectory.path,
        'progress_photos',
        profile.id,
        resolvedSessionId,
      ),
    );

    if (!await progressDirectory.exists()) {
      await progressDirectory.create(recursive: true);
    }

    final extension = path.extension(pickedImage.path).isEmpty
        ? '.jpg'
        : path.extension(pickedImage.path);

    final fileName = '${DateTime.now().microsecondsSinceEpoch}$extension';

    final savedFile = await sourceFile.copy(
      path.join(progressDirectory.path, fileName),
    );

    final photo = ProgressPhoto(
      profileId: profile.id,
      sessionId: resolvedSessionId,
      imagePath: savedFile.path,
      type: type,
      recordedAt: recordedAt,
      weight: weight,
      notes: _optionalText(notes),
    );

    await _repository.insert(photo);

    return photo;
  }

  String? _optionalText(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
