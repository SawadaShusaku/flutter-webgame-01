import 'package:flutter/material.dart';

// modelsパッケージからimport
import 'package:test_web_app/models/player.dart';
import 'package:test_web_app/models/enums.dart';

// utilsからimport
import 'package:test_web_app/utils/constants.dart';

/// 建設アクションボタンパネルを表示するウィジェット
class BuildActionsWidget extends StatelessWidget {
  final Player player;
  final VoidCallback? onBuildSettlement;
  final VoidCallback? onUpgradeCity;
  final VoidCallback? onBuildRoad;
  final VoidCallback? onBuyDevelopmentCard;

  const BuildActionsWidget({
    super.key,
    required this.player,
    this.onBuildSettlement,
    this.onUpgradeCity,
    this.onBuildRoad,
    this.onBuyDevelopmentCard,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // タイトル
            Row(
              children: [
                const Icon(
                  Icons.construction,
                  size: 24,
                  color: Colors.brown,
                ),
                const SizedBox(width: 8),
                const Text(
                  '建設アクション',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 集落建設
            _buildActionButton(
              context: context,
              icon: Icons.home,
              label: '集落を建設',
              cost: BuildingCosts.settlement,
              enabled: player.hasResources(BuildingCosts.settlement) &&
                  player.settlementsBuilt < GameConstants.maxSettlements,
              onPressed: onBuildSettlement,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),

            // 都市アップグレード
            _buildActionButton(
              context: context,
              icon: Icons.location_city,
              label: '都市にアップグレード',
              cost: BuildingCosts.city,
              enabled: player.hasResources(BuildingCosts.city) &&
                  player.citiesBuilt < GameConstants.maxCities &&
                  player.settlementsBuilt > 0,
              onPressed: onUpgradeCity,
              color: Colors.purple,
            ),
            const SizedBox(height: 12),

            // 道路建設
            _buildActionButton(
              context: context,
              icon: Icons.route,
              label: '道路を建設',
              cost: BuildingCosts.road,
              enabled: player.hasResources(BuildingCosts.road) &&
                  player.roadsBuilt < GameConstants.maxRoads,
              onPressed: onBuildRoad,
              color: Colors.brown,
            ),
            const SizedBox(height: 12),

            // 発展カード購入
            _buildActionButton(
              context: context,
              icon: Icons.style,
              label: '発展カードを購入',
              cost: BuildingCosts.developmentCard,
              enabled: player.hasResources(BuildingCosts.developmentCard),
              onPressed: onBuyDevelopmentCard,
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  /// アクションボタン
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Map<ResourceType, int> cost,
    required bool enabled,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey[300],
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[300],
        disabledForegroundColor: Colors.grey[600],
        padding: const EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        elevation: enabled ? 2 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // アイコンとラベル
          Row(
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // コスト表示
          _buildCostDisplay(cost, enabled),
        ],
      ),
    );
  }

  /// コスト表示
  Widget _buildCostDisplay(Map<ResourceType, int> cost, bool enabled) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: cost.entries.map((entry) {
        final resource = entry.key;
        final requiredCount = entry.value;
        final playerCount = player.resources[resource] ?? 0;
        final hasEnough = playerCount >= requiredCount;

        return _buildCostChip(
          resource: resource,
          requiredCount: requiredCount,
          playerCount: playerCount,
          hasEnough: hasEnough,
          enabled: enabled,
        );
      }).toList(),
    );
  }

  /// コストチップ
  Widget _buildCostChip({
    required ResourceType resource,
    required int requiredCount,
    required int playerCount,
    required bool hasEnough,
    required bool enabled,
  }) {
    final icon = ResourceIcons.getIcon(resource);
    final resourceColor = GameColors.getResourceColor(resource);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: enabled
            ? (hasEnough
                ? resourceColor.withOpacity(0.2)
                : Colors.red.withOpacity(0.2))
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: enabled
              ? (hasEnough ? resourceColor : Colors.red)
              : Colors.grey,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            '×$requiredCount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: enabled
                  ? (hasEnough ? Colors.black87 : Colors.red)
                  : Colors.grey,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($playerCount)',
            style: TextStyle(
              fontSize: 11,
              color: enabled
                  ? (hasEnough ? Colors.green : Colors.red)
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

/// シンプルな建設ボタン（コンパクト版）
class CompactBuildButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Map<ResourceType, int> cost;
  final bool enabled;
  final VoidCallback? onPressed;
  final Color color;

  const CompactBuildButton({
    super.key,
    required this.icon,
    required this.label,
    required this.cost,
    required this.enabled,
    this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey[300],
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[300],
        disabledForegroundColor: Colors.grey[600],
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      icon: Icon(icon, size: 20),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _getCostSummary(cost),
            style: const TextStyle(
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// コストサマリーを取得
  String _getCostSummary(Map<ResourceType, int> cost) {
    return cost.entries
        .map((e) => '${ResourceIcons.getIcon(e.key)}×${e.value}')
        .join(' ');
  }
}
