import 'dart:io';

import 'package:flutter/material.dart';

import '../models/progress_photo.dart';
import '../models/progress_photo_session.dart';
import '../services/progress_photo_service.dart';
import '../theme/app_theme.dart';
import '../models/measurement_system.dart';
import '../utils/weight_display.dart';

class ProgressPhotoSessionScreen extends StatefulWidget {
  const ProgressPhotoSessionScreen({
    required this.session,
    required this.measurementSystem,
    super.key,
  });

  final ProgressPhotoSession session;
  final MeasurementSystem measurementSystem;

  @override
  State<ProgressPhotoSessionScreen> createState() =>
      _ProgressPhotoSessionScreenState();
}

class _ProgressPhotoSessionScreenState
    extends State<ProgressPhotoSessionScreen> {
  final ProgressPhotoService _photoService = ProgressPhotoService();
  late ProgressPhotoSession _session;

  Future<void> _editSessionDetails() async {
    final updatedSession = await showModalBottomSheet<ProgressPhotoSession>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _EditSessionDetailsSheet(
        session: _session,
        measurementSystem: widget.measurementSystem,
      ),
    );

    if (updatedSession == null || !mounted) {
      return;
    }

    try {
      await _photoService.updateSessionDetails(updatedSession);

      if (!mounted) {
        return;
      }

      setState(() {
        _session = updatedSession;
      });

      await _loadPhotos();
    } catch (error) {
      _showError('Could not update progress session', error);
    }
  }

  List<ProgressPhoto> _photos = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    _session = widget.session;

    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final photos = await _photoService.getPhotosForSession(_session.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  ProgressPhoto? _photoForType(ProgressPhotoType type) {
    for (final photo in _photos) {
      if (photo.type == type) {
        return photo;
      }
    }

    return null;
  }

  int get _standardPhotoCount {
    return [
      ProgressPhotoType.front,
      ProgressPhotoType.side,
      ProgressPhotoType.back,
    ].where((type) => _photoForType(type) != null).length;
  }

  int get _remainingStandardPhotos {
    return 3 - _standardPhotoCount;
  }

  Future<void> _captureForType(ProgressPhotoType type) async {
    final source = await showModalBottomSheet<_ProgressPhotoSource>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(sheetContext, _ProgressPhotoSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.collections_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(sheetContext, _ProgressPhotoSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );

    if (source == null || !mounted) {
      return;
    }

    try {
      final ProgressPhoto? photo;

      switch (source) {
        case _ProgressPhotoSource.camera:
          photo = await _photoService.takeAndSavePhotoForSession(
            sessionId: _session.id,
            type: type,
            recordedAt: _session.recordedAt,
            weight: _session.weight,
            notes: _session.notes,
          );
          break;

        case _ProgressPhotoSource.gallery:
          photo = await _photoService.pickAndSaveFromGalleryForSession(
            sessionId: _session.id,
            type: type,
            recordedAt: _session.recordedAt,
            weight: _session.weight,
            notes: _session.notes,
          );
          break;
      }

      if (photo == null || !mounted) {
        return;
      }

      final existing = _photoForType(type);

      if (existing != null) {
        await _photoService.deletePhoto(existing);
      }

      await _loadPhotos();
    } catch (error) {
      _showError('Could not add ${type.label.toLowerCase()} photo', error);
    }
  }

  Future<void> _addCustomPhoto() async {
    await _captureForType(ProgressPhotoType.custom);
  }

  Future<void> _deletePhoto(ProgressPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete ${photo.type.label.toLowerCase()} photo?'),
          content: const Text(
            'This permanently removes the photo from this progress session.',
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
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await _photoService.deletePhoto(photo);

      if (mounted) {
        await _loadPhotos();
      }
    } catch (error) {
      _showError('Could not delete photo', error);
    }
  }

  Future<void> _deleteSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete progress session?'),
          content: const Text(
            'This permanently removes the session and every photo in it.',
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
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await _photoService.deleteSession(_session);

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (error) {
      _showError('Could not delete progress session', error);
    }
  }

  Future<void> _openPhoto(ProgressPhoto photo) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _SessionPhotoViewer(
          photo: photo,
          onDelete: () async {
            await _deletePhoto(photo);
          },
        ),
      ),
    );
  }

  void _finishSession() {
    Navigator.pop(context, true);
  }

  void _showError(String message, Object error) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$message: $error')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Session'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Session options',
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editSessionDetails();
                  break;
                case 'delete':
                  _deleteSession();
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 10),
                    Text('Edit Session Details'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: 10),
                    Text('Delete Session'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: FilledButton(
            onPressed: _finishSession,
            child: Text(
              _remainingStandardPhotos == 0 ? 'Finish Session' : 'Finish Later',
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPhotos,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            children: [
              _SessionHeaderCard(
                session: _session,
                measurementSystem: widget.measurementSystem,
                completedCount: _standardPhotoCount,
                remainingCount: _remainingStandardPhotos,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Progress Set',
                style: TextStyle(
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_loadError != null)
                _SessionErrorState(onRetry: _loadPhotos)
              else ...[
                _SessionPhotoSlot(
                  type: ProgressPhotoType.front,
                  photo: _photoForType(ProgressPhotoType.front),
                  onAdd: () {
                    _captureForType(ProgressPhotoType.front);
                  },
                  onOpen: _openPhoto,
                  onDelete: _deletePhoto,
                ),
                const SizedBox(height: AppSpacing.sm),
                _SessionPhotoSlot(
                  type: ProgressPhotoType.side,
                  photo: _photoForType(ProgressPhotoType.side),
                  onAdd: () {
                    _captureForType(ProgressPhotoType.side);
                  },
                  onOpen: _openPhoto,
                  onDelete: _deletePhoto,
                ),
                const SizedBox(height: AppSpacing.sm),
                _SessionPhotoSlot(
                  type: ProgressPhotoType.back,
                  photo: _photoForType(ProgressPhotoType.back),
                  onAdd: () {
                    _captureForType(ProgressPhotoType.back);
                  },
                  onOpen: _openPhoto,
                  onDelete: _deletePhoto,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Optional',
                  style: TextStyle(
                    fontSize: AppTypography.title,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _addCustomPhoto,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Add Custom Photo'),
                ),
                if (_photos
                    .where((photo) => photo.type == ProgressPhotoType.custom)
                    .isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _CustomPhotoGrid(
                    photos: _photos
                        .where(
                          (photo) => photo.type == ProgressPhotoType.custom,
                        )
                        .toList(growable: false),
                    onOpen: _openPhoto,
                    onDelete: _deletePhoto,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EditSessionDetailsSheet extends StatefulWidget {
  const _EditSessionDetailsSheet({
    required this.session,
    required this.measurementSystem,
  });

  final ProgressPhotoSession session;
  final MeasurementSystem measurementSystem;

  @override
  State<_EditSessionDetailsSheet> createState() =>
      _EditSessionDetailsSheetState();
}

class _EditSessionDetailsSheetState extends State<_EditSessionDetailsSheet> {
  late DateTime _recordedAt;
  late final TextEditingController _weightController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();

    _recordedAt = widget.session.recordedAt;

    final storedWeight = widget.session.weight;

    _weightController = TextEditingController(
      text: storedWeight == null
          ? ''
          : WeightDisplay.displayValue(
              storedWeight,
              widget.measurementSystem,
            ).toStringAsFixed(1),
    );

    _notesController = TextEditingController(text: widget.session.notes ?? '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? get _displayWeight {
    final value = _weightController.text.trim();

    if (value.isEmpty) {
      return null;
    }

    return double.tryParse(value);
  }

  double? get _storedWeight {
    final weight = _displayWeight;

    if (weight == null) {
      return null;
    }

    if (widget.measurementSystem == MeasurementSystem.metric) {
      return weight / 0.45359237;
    }

    return weight;
  }

  bool get _canSave {
    final value = _weightController.text.trim();

    if (value.isEmpty) {
      return true;
    }

    final weight = _displayWeight;

    return weight != null && weight > 0;
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _recordedAt = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _recordedAt.hour,
        _recordedAt.minute,
      );
    });
  }

  void _save() {
    if (!_canSave) {
      return;
    }

    Navigator.pop(
      context,
      widget.session.copyWith(
        recordedAt: _recordedAt,
        weight: _storedWeight,
        notes: _optionalText(_notesController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    final weightUnit = WeightDisplay.unit(widget.measurementSystem);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md + keyboardInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Session Details',
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _chooseDate,
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: Ink(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatDate(_recordedAt),
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'Weight',
                hintText: 'Optional',
                suffixText: weightUnit,
                prefixIcon: const Icon(Icons.monitor_weight_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Optional',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSave ? _save : null,
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionHeaderCard extends StatelessWidget {
  const _SessionHeaderCard({
    required this.session,
    required this.measurementSystem,
    required this.completedCount,
    required this.remainingCount,
  });

  final ProgressPhotoSession session;
  final MeasurementSystem measurementSystem;
  final int completedCount;
  final int remainingCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = completedCount / 3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(session.recordedAt),
            style: TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w800,
              color: colors.onPrimaryContainer,
            ),
          ),
          if (session.weight != null) ...[
            const SizedBox(height: 4),
            Text(
              WeightDisplay.format(session.weight!, measurementSystem),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.onPrimaryContainer,
              ),
            ),
          ],
          if (session.notes != null && session.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              session.notes!,
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: colors.onPrimaryContainer,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colors.onPrimaryContainer.withValues(
                alpha: 0.15,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(
                colors.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            remainingCount == 0
                ? 'Progress set complete'
                : '$remainingCount '
                      '${remainingCount == 1 ? 'photo' : 'photos'} remaining',
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.w700,
              color: colors.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionPhotoSlot extends StatelessWidget {
  const _SessionPhotoSlot({
    required this.type,
    required this.photo,
    required this.onAdd,
    required this.onOpen,
    required this.onDelete,
  });

  final ProgressPhotoType type;
  final ProgressPhoto? photo;
  final VoidCallback onAdd;
  final ValueChanged<ProgressPhoto> onOpen;
  final ValueChanged<ProgressPhoto> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isComplete = photo != null;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: isComplete
          ? InkWell(
              onTap: () {
                onOpen(photo!);
              },
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(photo!.imagePath),
                        width: 72,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 72,
                            height: 88,
                            alignment: Alignment.center,
                            color: colors.surfaceContainerHighest,
                            child: const Icon(Icons.broken_image_outlined),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.label,
                            style: const TextStyle(
                              fontSize: AppTypography.body,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Added',
                                style: TextStyle(
                                  fontSize: AppTypography.caption,
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'replace':
                            onAdd();
                            break;
                          case 'delete':
                            onDelete(photo!);
                            break;
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'replace',
                          child: Text('Replace Photo'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Photo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.add_a_photo_outlined,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.label,
                            style: const TextStyle(
                              fontSize: AppTypography.body,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Add ${type.label.toLowerCase()} photo',
                            style: TextStyle(
                              fontSize: AppTypography.caption,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CustomPhotoGrid extends StatelessWidget {
  const _CustomPhotoGrid({
    required this.photos,
    required this.onOpen,
    required this.onDelete,
  });

  final List<ProgressPhoto> photos;
  final ValueChanged<ProgressPhoto> onOpen;
  final ValueChanged<ProgressPhoto> onDelete;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final photo = photos[index];

        return InkWell(
          onTap: () {
            onOpen(photo);
          },
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(File(photo.imagePath), fit: BoxFit.cover),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: IconButton(
                  tooltip: 'Delete photo',
                  onPressed: () {
                    onDelete(photo);
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SessionPhotoViewer extends StatelessWidget {
  const _SessionPhotoViewer({required this.photo, required this.onDelete});

  final ProgressPhoto photo;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(photo.type.label),
        actions: [
          IconButton(
            tooltip: 'Delete photo',
            onPressed: () async {
              await onDelete();

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 5,
            child: Image.file(
              File(photo.imagePath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.broken_image_outlined,
                  size: 72,
                  color: Colors.white70,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionErrorState extends StatelessWidget {
  const _SessionErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 46),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Could not load this progress session.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onRetry, child: const Text('Try Again')),
        ],
      ),
    );
  }
}

enum _ProgressPhotoSource { camera, gallery }

String? _optionalText(String value) {
  final trimmed = value.trim();

  if (trimmed.isEmpty) {
    return null;
  }

  return trimmed;
}

String _formatDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[value.month - 1]} '
      '${value.day}, ${value.year}';
}
