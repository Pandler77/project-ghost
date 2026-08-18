import 'dart:io';

import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProfileAvatarService {
  ProfileAvatarService({ImagePicker? imagePicker, ImageCropper? imageCropper})
    : _imagePicker = imagePicker ?? ImagePicker(),
      _imageCropper = imageCropper ?? ImageCropper();

  final ImagePicker _imagePicker;
  final ImageCropper _imageCropper;

  /// Selects an image, crops it to a square, stores it permanently,
  /// and returns the saved local path.
  Future<String?> pickAndSaveAvatar({
    required String profileId,
    required ImageSource source,
    String? previousAvatarPath,
  }) async {
    final pickedImage = await _imagePicker.pickImage(
      source: source,
      imageQuality: 92,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    if (pickedImage == null) {
      return null;
    }

    final croppedImage = await _imageCropper.cropImage(
      sourcePath: pickedImage.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      maxWidth: 512,
      maxHeight: 512,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile Photo',
          lockAspectRatio: true,
          hideBottomControls: false,
          initAspectRatio: CropAspectRatioPreset.square,
        ),
        IOSUiSettings(
          title: 'Crop Profile Photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          rotateButtonsHidden: false,
          aspectRatioPickerButtonHidden: true,
        ),
      ],
    );

    if (croppedImage == null) {
      return null;
    }

    final savedPath = await _saveAvatarFile(
      profileId: profileId,
      croppedPath: croppedImage.path,
    );

    if (previousAvatarPath != null &&
        previousAvatarPath.trim().isNotEmpty &&
        previousAvatarPath != savedPath) {
      await deleteAvatar(previousAvatarPath);
    }

    return savedPath;
  }

  Future<String?> pickFromGallery({
    required String profileId,
    String? previousAvatarPath,
  }) {
    return pickAndSaveAvatar(
      profileId: profileId,
      source: ImageSource.gallery,
      previousAvatarPath: previousAvatarPath,
    );
  }

  Future<String?> takePhoto({
    required String profileId,
    String? previousAvatarPath,
  }) {
    return pickAndSaveAvatar(
      profileId: profileId,
      source: ImageSource.camera,
      previousAvatarPath: previousAvatarPath,
    );
  }

  Future<String> _saveAvatarFile({
    required String profileId,
    required String croppedPath,
  }) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();

    final avatarDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}profile_avatars',
    );

    if (!await avatarDirectory.exists()) {
      await avatarDirectory.create(recursive: true);
    }

    final safeProfileId = profileId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

    final fileName =
        'avatar_${safeProfileId}_${DateTime.now().microsecondsSinceEpoch}.jpg';

    final destinationPath =
        '${avatarDirectory.path}${Platform.pathSeparator}$fileName';

    final savedFile = await File(croppedPath).copy(destinationPath);

    return savedFile.path;
  }

  Future<void> deleteAvatar(String? avatarPath) async {
    if (avatarPath == null || avatarPath.trim().isEmpty) {
      return;
    }

    try {
      final file = File(avatarPath);

      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      // A missing or inaccessible avatar should not block profile updates.
    }
  }
}
