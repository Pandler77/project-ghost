import 'dart:io';

import 'package:flutter/material.dart';

import '../models/progress_photo.dart';
import '../models/progress_photo_session.dart';
import '../services/progress_photo_service.dart';
import '../services/usage_analytics_service.dart';
import '../theme/app_theme.dart';
import 'progress_photo_session_screen.dart';
import '../services/app_data_service.dart';
import 'premium_screen.dart';
import 'progress_photo_compare_screen.dart';
import '../models/measurement_system.dart';
import '../utils/weight_display.dart';
import '../theme/arctic_icons.dart';

class ProgressPhotosScreen extends StatefulWidget {
  const ProgressPhotosScreen({
    required this.dataService,
    required this.measurementSystem,
    this.startSessionOnOpen = false,
    super.key,
  });

  final AppDataService dataService;
  final MeasurementSystem measurementSystem;
  final bool startSessionOnOpen;

  @override
  State<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends State<ProgressPhotosScreen> {
  final ProgressPhotoService _photoService = ProgressPhotoService();

  List<ProgressPhotoSession> _sessions = [];
  Map<String, List<ProgressPhoto>> _sessionPhotos = {};

  bool _isLoading = true;
  String? _loadError;
  DateTime? _selectedDateFilter;

  Future<void> _openCompare() async {
    if (!widget.dataService.hasPremium) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => PremiumScreen(dataService: widget.dataService),
        ),
      );

      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ProgressPhotoCompareScreen(
          sessions: _sessions,
          measurementSystem: widget.measurementSystem,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _loadSessions();

    if (widget.startSessionOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startSession();
        }
      });
    }
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final sessions = await _photoService.getAllSessions();

      final photosBySession = <String, List<ProgressPhoto>>{};

      for (final session in sessions) {
        photosBySession[session.id] = await _photoService.getPhotosForSession(
          session.id,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _sessions = sessions;
        _sessionPhotos = photosBySession;
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

  Future<void> _startSession() async {
    final draft = await showModalBottomSheet<_SessionDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) =>
          _StartSessionSheet(measurementSystem: widget.measurementSystem),
    );

    if (draft == null || !mounted) {
      return;
    }

    try {
      final session = await _photoService.createSession(
        recordedAt: draft.recordedAt,
        weight: draft.weight,
        notes: draft.notes,
      );

      UsageAnalyticsService.instance.track(
        UsageAnalyticsEvent.photoSessionCreated,
      );

      if (!mounted) {
        return;
      }

      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ProgressPhotoSessionScreen(
            session: session,
            measurementSystem: widget.measurementSystem,
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadSessions();
    } catch (error) {
      _showError('Could not start progress session', error);
    }
  }

  Future<void> _openSession(ProgressPhotoSession session) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProgressPhotoSessionScreen(
          session: session,
          measurementSystem: widget.measurementSystem,
        ),
      ),
    );

    if (changed == true && mounted) {
      await _loadSessions();
    }
  }

  Future<void> _deleteSession(ProgressPhotoSession session) async {
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
      await _photoService.deleteSession(session);

      if (mounted) {
        await _loadSessions();
      }
    } catch (error) {
      _showError('Could not delete progress session', error);
    }
  }

  void _showError(String message, Object error) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$message: $error')));
  }

  List<ProgressPhotoSession> get _visibleSessions {
    final filter = _selectedDateFilter;

    if (filter == null) {
      return _sessions;
    }

    return _sessions
        .where((session) {
          final date = session.recordedAt;

          return date.year == filter.year &&
              date.month == filter.month &&
              date.day == filter.day;
        })
        .toList(growable: false);
  }

  Future<void> _chooseSessionDateFilter() async {
    final initialDate =
        _selectedDateFilter ??
        (_sessions.isNotEmpty ? _sessions.first.recordedAt : DateTime.now());

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDateFilter = DateTime(
        selected.year,
        selected.month,
        selected.day,
      );
    });
  }

  void _clearSessionDateFilter() {
    if (_selectedDateFilter == null) {
      return;
    }

    setState(() {
      _selectedDateFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Progress Photos',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton.icon(
              onPressed: _openCompare,
              icon: const Icon(ArcticIcons.compare_outlined),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Compare'),
                  const SizedBox(width: 6),
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      widget.dataService.hasPremium
                          ? const Color(0xFFE3AA22)
                          : colors.primary,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/branding/modose_premium_mark.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSessions,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.14),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        ArcticIcons.photo_library_outlined,
                        color: colors.primary,
                        size: AppIcon.md,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Visual Progress',
                            style: TextStyle(
                              fontSize: AppTypography.title,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Keep Front, Side, and Back photos grouped into consistent progress sessions.',
                            style: TextStyle(
                              fontSize: AppTypography.caption,
                              height: 1.35,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_loadError != null)
                _ErrorState(onRetry: _loadSessions)
              else if (_sessions.isEmpty)
                _EmptyState(onStartSession: _startSession)
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Text(
                        'Progress History',
                        style: TextStyle(
                          fontSize: AppTypography.title,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _startSession,
                      icon: const Icon(
                        ArcticIcons.add_a_photo_outlined,
                        size: 18,
                      ),
                      label: const Text(
                        'New Session',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_sessions.length} '
                        '${_sessions.length == 1 ? 'session' : 'sessions'}',
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _chooseSessionDateFilter,
                      icon: const Icon(
                        ArcticIcons.calendar_today_outlined,
                        size: 17,
                      ),
                      label: Text(
                        _selectedDateFilter == null
                            ? 'Filter by date'
                            : _formatDate(_selectedDateFilter!),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    if (_selectedDateFilter != null) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: 'Clear date filter',
                        onPressed: _clearSessionDateFilter,
                        icon: const Icon(Icons.close_rounded),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                if (_visibleSessions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: 34,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          ArcticIcons.calendar_today_outlined,
                          size: 30,
                          color: colors.primary,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'No sessions on this date',
                          style: TextStyle(
                            fontSize: AppTypography.body,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: _clearSessionDateFilter,
                          child: const Text('Show all sessions'),
                        ),
                      ],
                    ),
                  )
                else
                  for (
                    var index = 0;
                    index < _visibleSessions.length;
                    index++
                  ) ...[
                    _SessionCard(
                      session: _visibleSessions[index],
                      photos:
                          _sessionPhotos[_visibleSessions[index].id] ??
                          const [],
                      measurementSystem: widget.measurementSystem,
                      onTap: () {
                        _openSession(_visibleSessions[index]);
                      },
                      onEdit: () {
                        _openSession(_visibleSessions[index]);
                      },
                      onDelete: () {
                        _deleteSession(_visibleSessions[index]);
                      },
                    ),
                    if (index < _visibleSessions.length - 1)
                      const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.photos,
    required this.measurementSystem,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ProgressPhotoSession session;
  final List<ProgressPhoto> photos;
  final MeasurementSystem measurementSystem;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  ProgressPhoto? _photoForType(ProgressPhotoType type) {
    for (final photo in photos) {
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final completedCount = _standardPhotoCount;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.60),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(session.recordedAt),
                          style: const TextStyle(
                            fontSize: AppTypography.body,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (session.weight != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            WeightDisplay.format(
                              session.weight!,
                              measurementSystem,
                            ),
                            style: TextStyle(
                              fontSize: AppTypography.caption,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _SessionStatusBadge(completedCount: completedCount),
                  PopupMenuButton<String>(
                    tooltip: 'Session options',
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(ArcticIcons.edit_outlined),
                            SizedBox(width: 10),
                            Text('Edit Session'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(ArcticIcons.delete_outline),
                            SizedBox(width: 10),
                            Text('Delete Session'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (session.notes != null &&
                  session.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  session.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _PhotoPreview(
                      label: 'Front',
                      photo: _photoForType(ProgressPhotoType.front),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PhotoPreview(
                      label: 'Side',
                      photo: _photoForType(ProgressPhotoType.side),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PhotoPreview(
                      label: 'Back',
                      photo: _photoForType(ProgressPhotoType.back),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      completedCount == 3
                          ? 'Progress set complete'
                          : '$completedCount of 3 standard photos',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionStatusBadge extends StatelessWidget {
  const _SessionStatusBadge({required this.completedCount});

  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isComplete = completedCount == 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isComplete
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isComplete ? 'Complete' : '$completedCount/3',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isComplete
              ? colors.onPrimaryContainer
              : colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.label, required this.photo});

  final String label;
  final ProgressPhoto? photo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 0.82,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: photo == null
                ? Container(
                    color: colors.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(
                      ArcticIcons.add_photo_alternate_outlined,
                      color: colors.onSurfaceVariant,
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
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StartSessionSheet extends StatefulWidget {
  const _StartSessionSheet({required this.measurementSystem});

  final MeasurementSystem measurementSystem;

  @override
  State<_StartSessionSheet> createState() => _StartSessionSheetState();
}

class _StartSessionSheetState extends State<_StartSessionSheet> {
  DateTime _recordedAt = DateTime.now();

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

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

  bool get _canStart {
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

  void _start() {
    if (!_canStart) {
      return;
    }

    Navigator.pop(
      context,
      _SessionDraft(
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      ArcticIcons.add_a_photo_outlined,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Start Progress Session',
                          style: TextStyle(
                            fontSize: AppTypography.title,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Front, Side, and Back photos stay grouped together.',
                          style: TextStyle(
                            fontSize: AppTypography.caption,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    color: Theme.of(context).cardTheme.color ?? colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: 0.60),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        ArcticIcons.calendar_today_outlined,
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
                prefixIcon: const Icon(ArcticIcons.monitor_weight_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Notes',
                hintText: 'Optional',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canStart ? _start : null,
                icon: const Icon(ArcticIcons.add_a_photo_outlined),
                label: const Text(
                  'Start Session',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionDraft {
  const _SessionDraft({required this.recordedAt, this.weight, this.notes});

  final DateTime recordedAt;
  final double? weight;
  final String? notes;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onStartSession});

  final VoidCallback onStartSession;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 60,
        horizontal: AppSpacing.lg,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              ArcticIcons.photo_library_outlined,
              size: 34,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No progress sessions yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Create a session to keep Front, Side, and Back photos together.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onStartSession,
            icon: const Icon(ArcticIcons.add_a_photo_outlined),
            label: const Text('Start Session'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(ArcticIcons.error_outline, size: 48, color: colors.error),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Could not load progress sessions.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onRetry, child: const Text('Try Again')),
        ],
      ),
    );
  }
}

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
