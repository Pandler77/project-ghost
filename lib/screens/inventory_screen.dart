import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../models/protocol.dart';
import '../services/app_data_service.dart';
import '../services/settings_service.dart';
import 'inventory_setup/inventory_setup_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({
    required this.dataService,
    required this.protocols,
    super.key,
  });

  final AppDataService dataService;
  final List<Protocol> protocols;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SettingsService _settingsService = SettingsService();

  List<InventoryItem> _items = [];

  bool _isLoading = true;
  String? _loadError;
  String _searchQuery = '';
  bool _showBetaInformation = false;

  @override
  void initState() {
    super.initState();
    _loadInventory();
    _loadBetaInformationPreference();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InventoryItem> get _filteredItems {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return _items;
    }

    return _items.where((item) {
      final protocolName = _protocolName(item.protocolId).toLowerCase();

      final vendor = item.vendor?.toLowerCase() ?? '';

      final batch = item.batch?.toLowerCase() ?? '';

      final containerType = item.containerType.toLowerCase();

      return protocolName.contains(query) ||
          vendor.contains(query) ||
          batch.contains(query) ||
          containerType.contains(query);
    }).toList();
  }

  Future<void> _loadInventory() async {
    try {
      final items = await widget.dataService.getInventoryItems();

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _isLoading = false;
        _loadError = null;
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

  Future<void> _loadBetaInformationPreference() async {
    final dismissed = await _settingsService.getGhostSupplyBetaDismissed();

    if (!mounted) {
      return;
    }

    setState(() {
      _showBetaInformation = !dismissed;
    });
  }

  Future<void> _dismissBetaInformation() async {
    await _settingsService.saveGhostSupplyBetaDismissed(true);

    if (!mounted) {
      return;
    }

    setState(() {
      _showBetaInformation = false;
    });
  }

  Future<void> _openSetup({InventoryItem? item}) async {
    final availableProtocols = item == null
        ? widget.protocols.where((protocol) {
            return !_items.any(
              (inventory) => inventory.protocolId == protocol.id,
            );
          }).toList()
        : widget.protocols;

    if (item == null && availableProtocols.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Every protocol already has Ghost Supply configured.'),
        ),
      );

      return;
    }

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InventorySetupScreen(
          dataService: widget.dataService,
          protocols: availableProtocols,
          existingItem: item,
        ),
      ),
    );

    if (changed == true && mounted) {
      await _loadInventory();
    }
  }

  Future<void> _deleteItem(InventoryItem item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Ghost Supply?'),
          content: const Text(
            'This removes the Ghost Supply record. '
            'The protocol and dose history will remain.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await widget.dataService.deleteInventoryItem(item.id);

    if (!mounted) {
      return;
    }

    await _loadInventory();
  }

  String _protocolName(String protocolId) {
    for (final protocol in widget.protocols) {
      if (protocol.id == protocolId) {
        return protocol.name;
      }
    }

    return 'Unknown Protocol';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.dataService.hasPremium) {
      return const _PremiumInventoryPreview();
    }

    return Scaffold(
      appBar: AppBar(title: const _GhostSupplyTitle()),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 44),
              const SizedBox(height: 12),
              const Text(
                'Could not load Ghost Supply.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _loadError = null;
                  });

                  _loadInventory();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          if (_showBetaInformation) ...[
            _GhostSupplyBetaInformation(onDismiss: _dismissBetaInformation),
            const SizedBox(height: 16),
          ],
          _EmptyInventoryState(
            onAddPressed: () {
              _openSetup();
            },
          ),
        ],
      );
    }

    final filteredItems = _filteredItems;

    return RefreshIndicator(
      onRefresh: _loadInventory,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          if (_showBetaInformation) ...[
            _GhostSupplyBetaInformation(onDismiss: _dismissBetaInformation),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search supplies',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 52,
                height: 52,
                child: FilledButton.tonal(
                  onPressed: () {
                    _openSetup();
                  },
                  style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (filteredItems.isEmpty)
            const _NoMatchingInventory()
          else
            for (var index = 0; index < filteredItems.length; index++) ...[
              _InventoryCard(
                item: filteredItems[index],
                protocolName: _protocolName(filteredItems[index].protocolId),
                formatNumber: _formatNumber,
                onEdit: () {
                  _openSetup(item: filteredItems[index]);
                },
                onDelete: () {
                  _deleteItem(filteredItems[index]);
                },
              ),
              if (index < filteredItems.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _GhostSupplyTitle extends StatelessWidget {
  const _GhostSupplyTitle();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Ghost Supply™'),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'BETA',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.item,
    required this.protocolName,
    required this.formatNumber,
    required this.onEdit,
    required this.onDelete,
  });

  final InventoryItem item;
  final String protocolName;
  final String Function(double value) formatNumber;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final containerName = item.containerType.toLowerCase();

    final unopenedLabel = item.unopenedQuantity == 1
        ? containerName
        : _pluralize(containerName);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      protocolName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (item.isLowStock) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Low supply',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  PopupMenuButton<String>(
                    tooltip: 'Supply options',
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                        case 'remove':
                          onDelete();
                      }
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 12),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline),
                              SizedBox(width: 12),
                              Text('Remove'),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
              Text(
                'Current ${item.containerType}',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              if (item.currentAmount <= 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No $containerName currently open',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'The next completed dose will open one automatically.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                LinearProgressIndicator(
                  value: item.currentVialProgress,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(999),
                ),
                const SizedBox(height: 10),
                Text(
                  '${formatNumber(item.currentAmount)} / '
                  '${formatNumber(item.vialSize)} '
                  '${item.unit}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                item.currentAmount <= 0
                    ? '${item.unopenedQuantity} unopened '
                          '$unopenedLabel'
                          ' • '
                          '${formatNumber(item.totalRemaining)} '
                          '${item.unit} available'
                    : '${item.unopenedQuantity} unopened '
                          '$unopenedLabel'
                          ' • '
                          '${formatNumber(item.totalRemaining)} '
                          '${item.unit} total',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _pluralize(String value) {
    if (value == 'box') {
      return 'boxes';
    }

    if (value.endsWith('s')) {
      return value;
    }

    return '${value}s';
  }
}

class _GhostSupplyBetaInformation extends StatefulWidget {
  const _GhostSupplyBetaInformation({required this.onDismiss});

  final Future<void> Function() onDismiss;

  @override
  State<_GhostSupplyBetaInformation> createState() =>
      _GhostSupplyBetaInformationState();
}

class _GhostSupplyBetaInformationState
    extends State<_GhostSupplyBetaInformation> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Ghost Supply Beta Information',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  IconButton(
                    tooltip: 'Dismiss',
                    onPressed: widget.onDismiss,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ghost Supply is currently in beta. Automatic '
                    'deductions work best when the protocol dose and '
                    'inventory use compatible units.',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Commonly supported units',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const _BetaUnitRow(label: 'Mass', units: 'mcg, mg, g'),
                  const _BetaUnitRow(label: 'Volume', units: 'mL'),
                  const _BetaUnitRow(
                    label: 'Count',
                    units:
                        'IU, units, tablets, capsules, pills, softgels, drops',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Custom units can still be tracked. Automatic '
                    'deduction may be unavailable unless the protocol '
                    'and inventory units match.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BetaUnitRow extends StatelessWidget {
  const _BetaUnitRow({required this.label, required this.units});

  final String label;
  final String units;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 17,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $units',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoMatchingInventory extends StatelessWidget {
  const _NoMatchingInventory();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.search_off_outlined, size: 48),
          const SizedBox(height: 12),
          const Text(
            'No matching inventory',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Try searching by protocol, vendor, batch, or container type.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EmptyInventoryState extends StatelessWidget {
  const _EmptyInventoryState({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Set up Ghost Supply™',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'BETA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Track current amounts, unopened '
              'containers, and low-stock alerts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add),
              label: const Text('Add Inventory'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumInventoryPreview extends StatelessWidget {
  const _PremiumInventoryPreview();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const _GhostSupplyTitle()),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 72,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 20),
            const Text(
              'Smart inventory tracking',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Track what remains, unopened '
              'containers, and reorder timing.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            const _PremiumFeature(
              icon: Icons.remove_circle_outline,
              text: 'Automatic deductions when doses are completed',
            ),
            const _PremiumFeature(
              icon: Icons.inventory_outlined,
              text: 'Track current and unopened containers',
            ),
            const _PremiumFeature(
              icon: Icons.warning_amber_outlined,
              text: 'Low-stock and reorder alerts',
            ),
            const _PremiumFeature(
              icon: Icons.local_shipping_outlined,
              text: 'Estimated shipping and depletion timing',
            ),
            const SizedBox(height: 28),
            const FilledButton(
              onPressed: null,
              child: Text('Upgrade to Premium'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumFeature extends StatelessWidget {
  const _PremiumFeature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 14),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
