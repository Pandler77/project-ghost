import 'dart:io';

import 'package:flutter/material.dart';

import '../models/measurement_system.dart';
import '../models/progress_photo.dart';
import '../models/progress_photo_session.dart';
import '../services/progress_photo_service.dart';
import '../theme/app_theme.dart';
import '../utils/weight_display.dart';
import '../theme/arctic_icons.dart';
import '../widgets/app_select_field.dart';

enum _ComparisonMode { sideBySide, slider }

class ProgressPhotoCompareScreen extends StatefulWidget {
  const ProgressPhotoCompareScreen({
    required this.sessions,
    required this.measurementSystem,
    super.key,
  });

  final List<ProgressPhotoSession> sessions;
  final MeasurementSystem measurementSystem;

  @override
  State<ProgressPhotoCompareScreen> createState() =>
      _ProgressPhotoCompareScreenState();
}

class _ProgressPhotoCompareScreenState
    extends State<ProgressPhotoCompareScreen> {
  final ProgressPhotoService _photoService = ProgressPhotoService();

  ProgressPhotoSession? _leftSession;
  ProgressPhotoSession? _rightSession;

  ProgressPhotoType _selectedType = ProgressPhotoType.front;

  _ComparisonMode _comparisonMode = _ComparisonMode.sideBySide;

  double _sliderPosition = 0.5;

  List<ProgressPhoto> _leftPhotos = [];
  List<ProgressPhoto> _rightPhotos = [];

  bool _isLoading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    final sorted = List<ProgressPhotoSession>.from(widget.sessions)
      ..sort((first, second) => second.recordedAt.compareTo(first.recordedAt));

    if (sorted.isNotEmpty) {
      _rightSession = sorted.first;
    }

    if (sorted.length > 1) {
      _leftSession = sorted.last;
    } else if (sorted.isNotEmpty) {
      _leftSession = sorted.first;
    }

    _loadComparison();
  }

  Future<void> _loadComparison() async {
    final left = _leftSession;
    final right = _rightSession;

    if (left == null || right == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait<List<ProgressPhoto>>([
        _photoService.getPhotosForSession(left.id),
        _photoService.getPhotosForSession(right.id),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _leftPhotos = results[0];
        _rightPhotos = results[1];
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

  ProgressPhoto? _photoForType(
    List<ProgressPhoto> photos,
    ProgressPhotoType type,
  ) {
    for (final photo in photos) {
      if (photo.type == type) {
        return photo;
      }
    }

    return null;
  }

  int? get _daysApart {
    final left = _leftSession;
    final right = _rightSession;

    if (left == null || right == null) {
      return null;
    }

    return right.recordedAt.difference(left.recordedAt).inDays.abs();
  }

  double? get _weightDifference {
    final left = _leftSession?.weight;
    final right = _rightSession?.weight;

    if (left == null || right == null) {
      return null;
    }

    return right - left;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Compare Progress')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          children: [
            if (widget.sessions.length < 2)
              _NotEnoughSessionsCard(sessionCount: widget.sessions.length)
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _SessionSelector(
                      label: 'Earlier',
                      value: _leftSession,
                      sessions: widget.sessions,
                      onChanged: (session) {
                        setState(() {
                          _leftSession = session;
                        });

                        _loadComparison();
                      },
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  Expanded(
                    child: _SessionSelector(
                      label: 'Later',
                      value: _rightSession,
                      sessions: widget.sessions,
                      onChanged: (session) {
                        setState(() {
                          _rightSession = session;
                        });

                        _loadComparison();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              SegmentedButton<_ComparisonMode>(
                segments: const [
                  ButtonSegment(
                    value: _ComparisonMode.sideBySide,
                    icon: Icon(ArcticIcons.view_column_outlined),
                    label: Text('Side by Side'),
                  ),
                  ButtonSegment(
                    value: _ComparisonMode.slider,
                    icon: Icon(ArcticIcons.compare_outlined),
                    label: Text('Slider'),
                  ),
                ],
                selected: {_comparisonMode},
                onSelectionChanged: (selection) {
                  setState(() {
                    _comparisonMode = selection.first;
                  });
                },
              ),

              const SizedBox(height: AppSpacing.md),

              SegmentedButton<ProgressPhotoType>(
                segments: const [
                  ButtonSegment(
                    value: ProgressPhotoType.front,
                    label: Text('Front'),
                  ),
                  ButtonSegment(
                    value: ProgressPhotoType.side,
                    label: Text('Side'),
                  ),
                  ButtonSegment(
                    value: ProgressPhotoType.back,
                    label: Text('Back'),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedType = selection.first;
                  });
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_loadError != null)
                _CompareErrorCard(onRetry: _loadComparison)
              else ...[
                if (_comparisonMode == _ComparisonMode.sideBySide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ComparisonPhotoCard(
                          session: _leftSession!,
                          photo: _photoForType(_leftPhotos, _selectedType),
                          type: _selectedType,
                          measurementSystem: widget.measurementSystem,
                        ),
                      ),

                      const SizedBox(width: AppSpacing.sm),

                      Expanded(
                        child: _ComparisonPhotoCard(
                          session: _rightSession!,
                          photo: _photoForType(_rightPhotos, _selectedType),
                          type: _selectedType,
                          measurementSystem: widget.measurementSystem,
                        ),
                      ),
                    ],
                  )
                else
                  _BeforeAfterSlider(
                    earlierSession: _leftSession!,
                    laterSession: _rightSession!,
                    earlierPhoto: _photoForType(_leftPhotos, _selectedType),
                    laterPhoto: _photoForType(_rightPhotos, _selectedType),
                    type: _selectedType,
                    position: _sliderPosition,
                    measurementSystem: widget.measurementSystem,
                    onPositionChanged: (value) {
                      setState(() {
                        _sliderPosition = value;
                      });
                    },
                  ),

                const SizedBox(height: AppSpacing.lg),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comparison',
                        style: TextStyle(
                          fontSize: AppTypography.title,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      _ComparisonMetricRow(
                        label: 'Time between',
                        value: _daysApart == null
                            ? '—'
                            : '$_daysApart '
                                  '${_daysApart == 1 ? 'day' : 'days'}',
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      _ComparisonMetricRow(
                        label: 'Weight change',
                        value: _formatWeightDifference(
                          _weightDifference,
                          widget.measurementSystem,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      _ComparisonMetricRow(
                        label: 'Earlier weight',
                        value: _leftSession?.weight == null
                            ? '—'
                            : WeightDisplay.format(
                                _leftSession!.weight!,
                                widget.measurementSystem,
                              ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      _ComparisonMetricRow(
                        label: 'Later weight',
                        value: _rightSession?.weight == null
                            ? '—'
                            : WeightDisplay.format(
                                _rightSession!.weight!,
                                widget.measurementSystem,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionSelector extends StatelessWidget {
  const _SessionSelector({
    required this.label,
    required this.value,
    required this.sessions,
    required this.onChanged,
  });

  final String label;
  final ProgressPhotoSession? value;
  final List<ProgressPhotoSession> sessions;
  final ValueChanged<ProgressPhotoSession?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSelectField<ProgressPhotoSession>(
      value: value,
      values: sessions,
      label: label,
      placeholder: 'Choose a session',
      labelBuilder: (session) => _formatDate(session.recordedAt),
      onChanged: (session) => onChanged(session),
    );
  }
}

class _ComparisonPhotoCard extends StatelessWidget {
  const _ComparisonPhotoCard({
    required this.session,
    required this.photo,
    required this.type,
    required this.measurementSystem,
  });

  final ProgressPhotoSession session;
  final ProgressPhoto? photo;
  final ProgressPhotoType type;
  final MeasurementSystem measurementSystem;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 0.72,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: photo == null
                ? Container(
                    color: colors.surfaceContainerHighest,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ArcticIcons.image_not_supported_outlined,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'No ${type.label.toLowerCase()} photo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppTypography.caption,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : Image.file(
                    File(photo!.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: colors.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Icon(
                          ArcticIcons.broken_image_outlined,
                          color: colors.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        Text(
          _formatDate(session.recordedAt),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),

        if (session.weight != null) ...[
          const SizedBox(height: 2),
          Text(
            WeightDisplay.format(session.weight!, measurementSystem),
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _BeforeAfterSlider extends StatelessWidget {
  const _BeforeAfterSlider({
    required this.earlierSession,
    required this.laterSession,
    required this.earlierPhoto,
    required this.laterPhoto,
    required this.type,
    required this.position,
    required this.measurementSystem,
    required this.onPositionChanged,
  });

  final ProgressPhotoSession earlierSession;
  final ProgressPhotoSession laterSession;
  final ProgressPhoto? earlierPhoto;
  final ProgressPhoto? laterPhoto;
  final ProgressPhotoType type;
  final double position;
  final MeasurementSystem measurementSystem;
  final ValueChanged<double> onPositionChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (earlierPhoto == null || laterPhoto == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(
              ArcticIcons.image_not_supported_outlined,
              size: 42,
              color: colors.onSurfaceVariant,
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'Both sessions need a '
              '${type.label.toLowerCase()} photo '
              'for slider comparison.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 0.72,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              final dividerX = width * position;

              void updatePosition(Offset localPosition) {
                onPositionChanged((localPosition.dx / width).clamp(0.0, 1.0));
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  updatePosition(details.localPosition);
                },
                onHorizontalDragUpdate: (details) {
                  updatePosition(details.localPosition);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(laterPhoto!.imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: colors.surfaceContainerHighest,
                            alignment: Alignment.center,
                            child: const Icon(ArcticIcons.broken_image_outlined),
                          );
                        },
                      ),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: ClipRect(
                          child: SizedBox(
                            width: dividerX,
                            height: double.infinity,
                            child: OverflowBox(
                              alignment: Alignment.centerLeft,
                              minWidth: width,
                              maxWidth: width,
                              child: Image.file(
                                File(earlierPhoto!.imagePath),
                                width: width,
                                height: constraints.maxHeight,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: colors.surfaceContainerHighest,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      ArcticIcons.broken_image_outlined,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        left: dividerX - 1,
                        top: 0,
                        bottom: 0,
                        child: Container(width: 2, color: colors.onSurface),
                      ),

                      Positioned(
                        left: (dividerX - 18).clamp(0.0, width - 36),
                        top: constraints.maxHeight / 2 - 18,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.outlineVariant),
                          ),
                          child: const Icon(Icons.drag_indicator, size: 20),
                        ),
                      ),

                      Positioned(
                        left: AppSpacing.sm,
                        top: AppSpacing.sm,
                        child: _SliderLabel(
                          text: 'Earlier',
                          colorScheme: colors,
                        ),
                      ),

                      Positioned(
                        right: AppSpacing.sm,
                        top: AppSpacing.sm,
                        child: _SliderLabel(text: 'Later', colorScheme: colors),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            Expanded(
              child: _SliderSessionDetails(
                session: earlierSession,
                alignment: CrossAxisAlignment.start,
                measurementSystem: measurementSystem,
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: _SliderSessionDetails(
                session: laterSession,
                alignment: CrossAxisAlignment.end,
                measurementSystem: measurementSystem,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SliderLabel extends StatelessWidget {
  const _SliderLabel({required this.text, required this.colorScheme});

  final String text;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SliderSessionDetails extends StatelessWidget {
  const _SliderSessionDetails({
    required this.session,
    required this.alignment,
    required this.measurementSystem,
  });

  final ProgressPhotoSession session;
  final CrossAxisAlignment alignment;
  final MeasurementSystem measurementSystem;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          _formatDate(session.recordedAt),
          textAlign: alignment == CrossAxisAlignment.end
              ? TextAlign.right
              : TextAlign.left,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),

        if (session.weight != null)
          Text(
            WeightDisplay.format(session.weight!, measurementSystem),
            textAlign: alignment == CrossAxisAlignment.end
                ? TextAlign.right
                : TextAlign.left,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _ComparisonMetricRow extends StatelessWidget {
  const _ComparisonMetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _NotEnoughSessionsCard extends StatelessWidget {
  const _NotEnoughSessionsCard({required this.sessionCount});

  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            ArcticIcons.compare_outlined,
            size: 48,
            color: colors.onSurfaceVariant,
          ),

          const SizedBox(height: AppSpacing.md),

          const Text(
            'Two sessions required',
            style: TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            sessionCount == 0
                ? 'Create at least two progress sessions before comparing.'
                : 'Create one more progress session to unlock comparison.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _CompareErrorCard extends StatelessWidget {
  const _CompareErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const Icon(ArcticIcons.error_outline, size: 46),

          const SizedBox(height: AppSpacing.md),

          const Text(
            'Could not load comparison photos.',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.md),

          OutlinedButton(onPressed: onRetry, child: const Text('Try Again')),
        ],
      ),
    );
  }
}

String _formatWeightDifference(
  double? value,
  MeasurementSystem measurementSystem,
) {
  if (value == null) {
    return '—';
  }

  final displayedValue = WeightDisplay.displayValue(
    value.abs(),
    measurementSystem,
  );

  final unit = WeightDisplay.unit(measurementSystem);

  if (value == 0) {
    return '0.0 $unit';
  }

  final prefix = value > 0 ? '+' : '-';

  return '$prefix'
      '${displayedValue.toStringAsFixed(1)} $unit';
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
