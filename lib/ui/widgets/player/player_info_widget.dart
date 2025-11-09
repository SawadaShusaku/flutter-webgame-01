import 'package:flutter/material.dart';

// modelsパッケージからimport
import '../../../../../models/lib/models/player.dart';
import '../../../../../models/lib/models/enums.dart';

// utilsからimport
import '../../../utils/constants.dart';

/// プレイヤー情報カードを表示するウィジェット
class PlayerInfoWidget extends StatelessWidget {
  final Player player;
  final bool isCurrentPlayer; // 現在のプレイヤーかどうか
  final bool showResources; // 資源を表示するか
  final VoidCallback? onTap;

  const PlayerInfoWidget({
    super.key,
    required this.player,
    this.isCurrentPlayer = false,
    this.showResources = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final playerColor = GameColors.getPlayerColor(player.color);
    final victoryPoints = player.calculateVictoryPoints();

    return Card(
      elevation: isCurrentPlayer ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: playerColor,
          width: isCurrentPlayer ? 3.0 : 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // プレイヤー名とカラー
              _buildPlayerHeader(playerColor, victoryPoints),
              const SizedBox(height: 12),

              // 建設数
              _buildBuildingCounts(),
              const SizedBox(height: 8),

              // 発展カード枚数
              _buildDevelopmentCardCount(),

              // 特別ポイント
              if (player.hasLongestRoad || player.hasLargestArmy) ...[
                const SizedBox(height: 8),
                _buildSpecialPoints(),
              ],

              // 資源（オプション）
              if (showResources && player.totalResources > 0) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                _buildResourcesSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// プレイヤーヘッダー
  Widget _buildPlayerHeader(Color playerColor, int victoryPoints) {
    return Row(
      children: [
        // プレイヤーカラーインジケーター
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: playerColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // プレイヤー名
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: playerColor,
                ),
              ),
              if (isCurrentPlayer)
                Text(
                  '現在のプレイヤー',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),

        // 勝利点
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: victoryPoints >= GameConstants.victoryPointsToWin
                ? Colors.amber
                : playerColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: playerColor,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events,
                size: 18,
                color: Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                victoryPoints.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 建設数
  Widget _buildBuildingCounts() {
    return Row(
      children: [
        _buildBuildingItem(
          icon: Icons.home,
          label: '集落',
          count: player.settlementsBuilt,
          max: GameConstants.maxSettlements,
          color: Colors.blue,
        ),
        const SizedBox(width: 12),
        _buildBuildingItem(
          icon: Icons.location_city,
          label: '都市',
          count: player.citiesBuilt,
          max: GameConstants.maxCities,
          color: Colors.purple,
        ),
        const SizedBox(width: 12),
        _buildBuildingItem(
          icon: Icons.route,
          label: '道路',
          count: player.roadsBuilt,
          max: GameConstants.maxRoads,
          color: Colors.brown,
        ),
      ],
    );
  }

  /// 建設アイテム
  Widget _buildBuildingItem({
    required IconData icon,
    required String label,
    required int count,
    required int max,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              '$count/$max',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 発展カード枚数
  Widget _buildDevelopmentCardCount() {
    final cardCount = player.developmentCards.length;
    final knightsPlayed = player.knightsPlayed;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.style,
                  size: 20,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '発展カード',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '$cardCount枚',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                if (knightsPlayed > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🗡️',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          knightsPlayed.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 特別ポイント
  Widget _buildSpecialPoints() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: [
        if (player.hasLongestRoad)
          _buildSpecialPointChip(
            icon: '🛣️',
            label: '最長交易路',
            points: GameConstants.longestRoadPoints,
          ),
        if (player.hasLargestArmy)
          _buildSpecialPointChip(
            icon: '⚔️',
            label: '最大騎士力',
            points: GameConstants.largestArmyPoints,
          ),
      ],
    );
  }

  /// 特別ポイントチップ
  Widget _buildSpecialPointChip({
    required String icon,
    required String label,
    required int points,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.amber,
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
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '+$points',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  /// 資源セクション
  Widget _buildResourcesSection() {
    final totalResources = player.totalResources;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.layers,
              size: 16,
              color: Colors.brown,
            ),
            const SizedBox(width: 6),
            Text(
              '資源カード: $totalResources枚',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
