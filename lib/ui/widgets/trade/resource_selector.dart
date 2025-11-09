import 'package:flutter/material.dart';

/// 資源選択UI
/// 各資源タイプのカウンター（+/-ボタン）と所持数を表示
class ResourceSelector extends StatelessWidget {
  final Map<String, int> currentResources;
  final Map<String, int> selectedResources;
  final Function(String resourceType, int delta) onResourceChanged;
  final bool showAvailable;

  const ResourceSelector({
    super.key,
    required this.currentResources,
    required this.selectedResources,
    required this.onResourceChanged,
    this.showAvailable = true,
  });

  Color _getResourceColor(String name) {
    switch (name) {
      case '木材':
        return Colors.green[700]!;
      case 'レンガ':
        return Colors.red[700]!;
      case '羊毛':
        return Colors.lightGreen[300]!;
      case '小麦':
        return Colors.amber[600]!;
      case '鉱石':
        return Colors.grey[700]!;
      default:
        return Colors.grey;
    }
  }

  IconData _getResourceIcon(String name) {
    switch (name) {
      case '木材':
        return Icons.park;
      case 'レンガ':
        return Icons.square;
      case '羊毛':
        return Icons.pets;
      case '小麦':
        return Icons.grass;
      case '鉱石':
        return Icons.landscape;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: currentResources.entries.map((entry) {
        final resourceType = entry.key;
        final available = entry.value;
        final selected = selectedResources[resourceType] ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _ResourceRow(
            resourceType: resourceType,
            available: available,
            selected: selected,
            color: _getResourceColor(resourceType),
            icon: _getResourceIcon(resourceType),
            showAvailable: showAvailable,
            onIncrement: () {
              if (selected < available) {
                onResourceChanged(resourceType, 1);
              }
            },
            onDecrement: () {
              if (selected > 0) {
                onResourceChanged(resourceType, -1);
              }
            },
          ),
        );
      }).toList(),
    );
  }
}

class _ResourceRow extends StatelessWidget {
  final String resourceType;
  final int available;
  final int selected;
  final Color color;
  final IconData icon;
  final bool showAvailable;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _ResourceRow({
    required this.resourceType,
    required this.available,
    required this.selected,
    required this.color,
    required this.icon,
    required this.showAvailable,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final canIncrement = selected < available;
    final canDecrement = selected > 0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected > 0 ? color : Colors.grey[300]!,
          width: selected > 0 ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // アイコンと名前
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resourceType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (showAvailable)
                  Text(
                    '所持: $available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          // 選択数
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: selected > 0 ? color.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$selected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: selected > 0 ? color : Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // -ボタン
          IconButton(
            onPressed: canDecrement ? onDecrement : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: color,
            iconSize: 32,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          // +ボタン
          IconButton(
            onPressed: canIncrement ? onIncrement : null,
            icon: const Icon(Icons.add_circle_outline),
            color: color,
            iconSize: 32,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
