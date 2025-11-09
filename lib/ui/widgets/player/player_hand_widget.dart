import 'package:flutter/material.dart';

// modelsパッケージからimport
import 'package:test_web_app/models/player.dart';
import 'package:test_web_app/models/enums.dart';

// utilsからimport
import 'package:test_web_app/utils/constants.dart';

/// プレイヤーの手札（資源カード）を表示するウィジェット
class PlayerHandWidget extends StatelessWidget {
  final Player player;
  final bool compact; // コンパクト表示（横並び）
  final bool showEmpty; // 0枚の資源も表示するか

  const PlayerHandWidget({
    super.key,
    required this.player,
    this.compact = true,
    this.showEmpty = true,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactView();
    } else {
      return _buildDetailedView();
    }
  }

  /// コンパクト表示（横並び）
  Widget _buildCompactView() {
    final resources = ResourceType.values;

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: resources.map((resource) {
        final count = player.resources[resource] ?? 0;
        if (!showEmpty && count == 0) {
          return const SizedBox.shrink();
        }

        return _buildResourceChip(resource, count);
      }).toList(),
    );
  }

  /// 詳細表示（縦並び）
  Widget _buildDetailedView() {
    final resources = ResourceType.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: resources.map((resource) {
        final count = player.resources[resource] ?? 0;
        if (!showEmpty && count == 0) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: _buildResourceRow(resource, count),
        );
      }).toList(),
    );
  }

  /// 資源チップ（コンパクト表示用）
  Widget _buildResourceChip(ResourceType resource, int count) {
    final icon = ResourceIcons.getIcon(resource);
    final color = GameColors.getResourceColor(resource);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: color,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 4),
          Text(
            '×$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color.computeLuminance() > 0.5
                  ? Colors.black87
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 資源行（詳細表示用）
  Widget _buildResourceRow(ResourceType resource, int count) {
    final icon = ResourceIcons.getIcon(resource);
    final color = GameColors.getResourceColor(resource);
    final name = _getResourceName(resource);

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color.computeLuminance() > 0.5
                    ? Colors.black87
                    : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 資源名を取得
  String _getResourceName(ResourceType resource) {
    switch (resource) {
      case ResourceType.lumber:
        return '木材';
      case ResourceType.brick:
        return 'レンガ';
      case ResourceType.wool:
        return '羊毛';
      case ResourceType.grain:
        return '小麦';
      case ResourceType.ore:
        return '鉱石';
    }
  }
}

/// 総資源数表示ウィジェット
class TotalResourcesWidget extends StatelessWidget {
  final Player player;

  const TotalResourcesWidget({
    super.key,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final totalResources = player.totalResources;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.brown.shade100,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.brown.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.layers,
            size: 18,
            color: Colors.brown,
          ),
          const SizedBox(width: 6),
          Text(
            '合計: $totalResources枚',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
        ],
      ),
    );
  }
}
