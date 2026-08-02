import 'package:flutter/material.dart';

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
    super.key,
  });

  final List<Protocol> protocols;
  final VoidCallback onProtocolsChanged;
  final Future<void> Function(Protocol protocol) onProtocolAdded;
  final Future<void> Function(Protocol protocol) onProtocolUpdated;

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

  @override
Widget build(BuildContext context) {
  final filteredProtocols = _filteredProtocols();

  return SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Manage what you are currently tracking.',
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openAddProtocol,
            icon: const Icon(Icons.add),
            label: const Text('Add Protocol'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 48,
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
          const NoMatchingProtocolsState(
            onClearFilters: null,
          )
        else
          for (
            var index = 0;
            index < filteredProtocols.length;
            index++
          ) ...[
            ProtocolCard(
              protocol: filteredProtocols[index],
              onPressed: () {
                _openProtocolDetails(
                  filteredProtocols[index],
                );
              },
            ),
            if (index < filteredProtocols.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
