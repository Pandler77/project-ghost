import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/inventory_photo.dart';
import 'app_data_service.dart';

class InventoryPhotoService {
  InventoryPhotoService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<InventoryPhoto?> pickAndSaveFromGallery({
    required String inventoryItemId,
    required AppDataService dataService,
    String? caption,
  }) {
    return _pickAndSave(
      inventoryItemId: inventoryItemId,
      dataService: dataService,
      source: ImageSource.gallery,
      caption: caption,
    );
  }

  Future<InventoryPhoto?> takeAndSavePhoto({
    required String inventoryItemId,
    required AppDataService dataService,
    String? caption,
  }) {
    return _pickAndSave(
      inventoryItemId: inventoryItemId,
      dataService: dataService,
      source: ImageSource.camera,
      caption: caption,
    );
  }

  Future<void> deletePhoto({
    required InventoryPhoto photo,
    required AppDataService dataService,
  }) async {
    final file = File(photo.imagePath);

    if (await file.exists()) {
      await file.delete();
    }

    await dataService.deleteInventoryPhoto(photo.id);
  }

  Future<InventoryPhoto?> _pickAndSave({
    required String inventoryItemId,
    required AppDataService dataService,
    required ImageSource source,
    String? caption,
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

    final documentsDirectory = await getApplicationDocumentsDirectory();

    final inventoryDirectory = Directory(
      path.join(documentsDirectory.path, 'inventory_photos', inventoryItemId),
    );

    if (!await inventoryDirectory.exists()) {
      await inventoryDirectory.create(recursive: true);
    }

    final extension = path.extension(pickedImage.path).isEmpty
        ? '.jpg'
        : path.extension(pickedImage.path);

    final fileName = '${DateTime.now().microsecondsSinceEpoch}$extension';

    final savedFile = await sourceFile.copy(
      path.join(inventoryDirectory.path, fileName),
    );

    final photo = InventoryPhoto(
      inventoryItemId: inventoryItemId,
      imagePath: savedFile.path,
      caption: _optionalText(caption),
    );

    await dataService.saveInventoryPhoto(photo);

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
