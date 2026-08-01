import 'package:flutter/material.dart';

import '../models/home_layout.dart';
import '../models/home_section.dart';
import '../models/tracking_preferences.dart';
import '../theme/app_theme.dart';

class EditHomeScreen extends StatefulWidget {
  const EditHomeScreen({
    required this.initialLayout,
    required this.trackingPreferences,
    super.key,
  });

  final HomeLayout initialLayout;
  final TrackingPreferences trackingPreferences;

  @override
  State<EditHomeScreen> createState() => _EditHomeScreenState();
}

class _EditHomeScreenState extends State<EditHomeScreen> {
  late final List<HomeSection> _orderedSections;
  late final Set<HomeSection> _visibleSections;

  @override
  void initState() {
    super.initState();

    _visibleSections = widget.initialLayout.visibleSections
        .where(_isSectionAvailable)
        .toSet();

    final availableSections = HomeSection.values.where(_isSectionAvailable);

    final hiddenSections = availableSections.where(
      (section) => !_visibleSections.contains(section),
    );

    _orderedSections = [
      ...widget.initialLayout.visibleSections.where(_isSectionAvailable),
      ...hiddenSections,
    ];
  }

  bool _isSectionAvailable(HomeSection section) {
    return switch (section) {
      HomeSection.weight => widget.trackingPreferences.trackWeight,
      _ => true,
    };
  }

  void _toggleSection(HomeSection section, bool isVisible) {
    setState(() {
      if (isVisible) {
        _visibleSections.add(section);
      } else {
        _visibleSections.remove(section);
      }
    });
  }

  void _save() {
    final visibleSections = _orderedSections
        .where(_visibleSections.contains)
        .toList();

    Navigator.pop(context, HomeLayout(visibleSections: visibleSections));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Home'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: SafeArea(
        child: ReorderableListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: _orderedSections.length,
          onReorderItem: (oldIndex, newIndex) {
            setState(() {
              final section = _orderedSections.removeAt(oldIndex);

              _orderedSections.insert(newIndex, section);
            });
          },
          itemBuilder: (context, index) {
            final section = _orderedSections[index];
            final isVisible = _visibleSections.contains(section);

            return Card(
              key: ValueKey(section),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                leading: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
                title: Text(section.title),
                subtitle: Text(section.description),
                trailing: Switch(
                  value: isVisible,
                  onChanged: (value) {
                    _toggleSection(section, value);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
