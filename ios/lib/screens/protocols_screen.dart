import 'package:flutter/material.dart';

import '../models/display_preferences.dart';
import '../models/protocol.dart';
import '../models/protocol_status.dart';
import '../theme/app_theme.dart';
import '../widgets/protocols/empty_protocols_state.dart';
import '../widgets/protocols/protocol_card.dart';
import '../widgets/protocols/protocol_filter_chips.dart';
import '../widgets/protocols/protocol_search_bar.dart';
import 'add_protocol_screen.dart';
import 'protocol_details_screen.dart';

enum ProtocolSortOption {
  nameAscending,
  nameDescending,
  recentlyAdded,
  oldestAdded,
  startDate,
}

class ProtocolsScreen extends StatefulWidget {
  const ProtocolsScreen({
    required this.protocols,
    required this.onProtocolsChanged,
    required this.onProtocolAdded,
    required this.onProtocolUpdated,
    required this.displayPreferences,
    super.key,
  });

  final List<Protocol> protocols;
  final VoidCallback onProtocolsChanged;
  final Future<void> Function(Protocol protocol) onProtocolAdded;
  final Future<void> Function(Protocol protocol) onProtocolUpdated;
  final DisplayPreferences displayPreferences;

  @override
  State<ProtocolsScreen> createState() => _ProtocolsScreenState();
}

class _ProtocolsScreenState extends State<ProtocolsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  ProtocolStatus? _statusFilter;

  ProtocolSortOption _sortOption = ProtocolSortOption.nameAscending;

  Future<void> _showSortMenu(BuildContext context) async {
    final selected = await showMenu<ProtocolSortOption>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 300, 16, 0),
      items: [
        CheckedPopupMenuItem(
          value: ProtocolSortOption.nameAscending,
          checked: _sortOption == ProtocolSortOption.nameAscending,
          child: const Text('Alphabetical A–Z'),
        ),
        CheckedPopupMenuItem(
          value: ProtocolSortOption.nameDescending,
          checked: _sortOption == ProtocolSortOption.nameDescending,
          child: const Text('Alphabetical Z–A'),
        ),
        CheckedPopupMenuItem(
          value: ProtocolSortOption.recentlyAdded,
          checked: _sortOption == ProtocolSortOption.recentlyAdded,
          child: const Text('Recently added'),
        ),
        CheckedPopupMenuItem(
          value: ProtocolSortOption.oldestAdded,
          checked: _sortOption == ProtocolSortOption.oldestAdded,
          child: const Text('Oldest added'),
        ),
        CheckedPopupMenuItem(
          value: ProtocolSortOption.startDate,
          checked: _sortOption == ProtocolSortOption.startDate,
          child: const Text('Start date'),
        ),
      ],
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _sortOption = selected;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddProtocol() async {
    final protocol = await Navigator.push<Protocol>(
      context,
      MaterialPageRoute(builder: (_) => const AddProtocolScreen()),
    );

    if (protocol == null || !mounted) {
      return;
    }

    await widget.onProtocolAdded(protocol);

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _openProtocolDetails(Protocol protocol) async {
    final updatedProtocol = await Navigator.push<Protocol>(
      context,
      MaterialPageRoute(
        builder: (_) => ProtocolDetailsScreen(protocol: protocol),
      ),
    );

    if (updatedProtocol == null || !mounted) {
      return;
    }

    final index = widget.protocols.indexWhere(
      (item) => item.id == updatedProtocol.id,
    );

    if (index == -1) {
      return;
    }

    widget.protocols[index] = updatedProtocol;

    await widget.onProtocolUpdated(updatedProtocol);

    if (!mounted) {
      return;
    }

    setState(() {});

    widget.onProtocolsChanged();
  }

  List<Protocol> _filteredProtocols() {
    final search = _searchQuery.trim().toLowerCase();

    final filtered = widget.protocols.where((protocol) {
      final matchesStatus =
          _statusFilter == null || protocol.status == _statusFilter;

      if (!matchesStatus) {
        return false;
      }

      if (search.isEmpty) {
        return true;
      }

      return protocol.name.toLowerCase().contains(search) ||
          protocol.dose.toLowerCase().contains(search);
    }).toList();

    switch (_sortOption) {
      case ProtocolSortOption.nameAscending:
        filtered.sort(
          (first, second) =>
              first.name.toLowerCase().compareTo(second.name.toLowerCase()),
        );

      case ProtocolSortOption.nameDescending:
        filtered.sort(
          (first, second) =>
              second.name.toLowerCase().compareTo(first.name.toLowerCase()),
        );

      case ProtocolSortOption.recentlyAdded:
        filtered.sort(
          (first, second) => _numericId(second).compareTo(_numericId(first)),
        );

      case ProtocolSortOption.oldestAdded:
        filtered.sort(
          (first, second) => _numericId(first).compareTo(_numericId(second)),
        );

      case ProtocolSortOption.startDate:
        filtered.sort(
          (first, second) =>
              first.schedule.startDate.compareTo(second.schedule.startDate),
        );
    }

    return filtered;
  }

  int _numericId(Protocol protocol) {
    return int.tryParse(protocol.id) ?? 0;
  }

  int get _activeProtocolCount {
    return widget.protocols.where((protocol) {
      return protocol.status == ProtocolStatus.active;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final filteredProtocols = _filteredProtocols();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          110,
        ),
        children: [
          _ProtocolsHeader(
            activeCount: _activeProtocolCount,
            totalCount: widget.protocols.length,
            onAddProtocol: _openAddProtocol,
          ),

          const SizedBox(height: AppSpacing.lg),

          SizedBox(
            height: 46,
            child: ProtocolSearchBar(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onClear: () {
                _searchController.clear();

                setState(() {
                  _searchQuery = '';
                });
              },
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          ProtocolFilterChips(
            selectedStatus: _statusFilter,
            onStatusChanged: (status) {
              setState(() {
                _statusFilter = status;
              });
            },
            onSortPressed: () {
              _showSortMenu(context);
            },
          ),

          const SizedBox(height: AppSpacing.md),

          if (widget.protocols.isEmpty)
            const EmptyProtocolsState()
          else if (filteredProtocols.isEmpty)
            Column(
              children: [
                const NoMatchingProtocolsState(onClearFilters: null),

                const SizedBox(height: AppSpacing.sm),

                TextButton(
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchQuery = '';
                      _statusFilter = null;
                    });
                  },
                  child: const Text('Clear filters'),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${filteredProtocols.length} '
                    '${filteredProtocols.length == 1 ? 'protocol' : 'protocols'}',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            for (var index = 0; index < filteredProtocols.length; index++) ...[
              ProtocolCard(
                protocol: filteredProtocols[index],
                displayPreferences: widget.displayPreferences,
                onPressed: () {
                  _openProtocolDetails(filteredProtocols[index]);
                },
              ),

              if (index < filteredProtocols.length - 1)
                SizedBox(
                  height: widget.displayPreferences.compactMode
                      ? AppSpacing.xs
                      : AppSpacing.sm,
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ProtocolsHeader extends StatelessWidget {
  const _ProtocolsHeader({
    required this.activeCount,
    required this.totalCount,
    required this.onAddProtocol,
  });

  final int activeCount;
  final int totalCount;
  final VoidCallback onAddProtocol;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final brightness = Theme.of(context).brightness;

    final subtitle = totalCount == 0
        ? 'Nothing being tracked yet'
        : activeCount == 1
        ? '1 active protocol'
        : '$activeCount active protocols';

    final gradientColors = ArcticPalette.headerGradient(context).colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: brightness == Brightness.dark
              ? ArcticPalette.lavender.withValues(alpha: 0.22)
              : ArcticPalette.purple.withValues(alpha: 0.14),
          width: 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.24)
                : ArcticPalette.purple.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Protocols',
                  style: TextStyle(
                    fontSize: AppTypography.pageTitle,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurfaceVariant,
                  ),
                ),

                if (totalCount > 0) ...[
                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    '$totalCount total',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.button),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(
                    alpha: brightness == Brightness.dark ? 0.06 : 0.28,
                  ),
                  blurRadius: brightness == Brightness.dark ? 12 : 16,
                  spreadRadius: brightness == Brightness.dark ? 0 : 1,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAddProtocol,
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: brightness == Brightness.dark
                        ? colors.primary.withValues(alpha: 0.08)
                        : null,
                    gradient: brightness == Brightness.dark
                        ? null
                        : LinearGradient(
                            colors: [
                              colors.primary,
                              colors.primary.withValues(alpha: 0.82),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(
                      color: brightness == Brightness.dark
                          ? colors.primary.withValues(alpha: 0.42)
                          : Colors.white.withValues(alpha: 0.28),
                      width: brightness == Brightness.dark ? 1.2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 19,
                        color: brightness == Brightness.dark
                            ? colors.primary
                            : Colors.white,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Add Protocol',
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          fontWeight: FontWeight.w800,
                          color: brightness == Brightness.dark
                              ? colors.primary
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
