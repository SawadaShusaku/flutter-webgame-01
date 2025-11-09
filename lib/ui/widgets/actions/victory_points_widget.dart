import 'package:flutter/material.dart';

// modelsパッケージからimport
import '../../../../../models/lib/models/player.dart';
import '../../../../../models/lib/models/enums.dart';

// utilsからimport
import '../../../utils/constants.dart';

/// 勝利点の詳細な内訳を表示するウィジェット
class VictoryPointsWidget extends StatelessWidget {
  final Player player;
  final bool expanded; // 展開表示

  const VictoryPointsWidget({
    super.key,
    required this.player,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final totalPoints = player.calculateVictoryPoints();
    final settlementsPoints = player.settlementsBuilt * 1;
    final citiesPoints = player.citiesBuilt * 2;
    final longestRoadPoints =
        player.hasLongestRoad ? GameConstants.longestRoadPoints : 0;
    final largestArmyPoints =
        player.hasLargestArmy ? GameConstants.largestArmyPoints : 0;
    final victoryPointCardCount = player.developmentCards
        .where((card) => card.type == DevelopmentCardType.victoryPoint)
        .length;

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
            // タイトルと総合点
            _buildHeader(totalPoints),

            if (expanded) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // 内訳
              _buildPointItem(
                icon: Icons.home,
                label: '集落',
                count: player.settlementsBuilt,
                pointsPerItem: 1,
                totalPoints: settlementsPoints,
                color: Colors.blue,
              ),
              const SizedBox(height: 8),

              _buildPointItem(
                icon: Icons.location_city,
                label: '都市',
                count: player.citiesBuilt,
                pointsPerItem: 2,
                totalPoints: citiesPoints,
                color: Colors.purple,
              ),
              const SizedBox(height: 8),

              if (player.hasLongestRoad)
                _buildSpecialPointItem(
                  icon: '🛣️',
                  label: '最長交易路',
                  points: longestRoadPoints,
                  color: Colors.amber,
                ),

              if (player.hasLongestRoad) const SizedBox(height: 8),

              if (player.hasLargestArmy)
                _buildSpecialPointItem(
                  icon: '⚔️',
                  label: '最大騎士力',
                  points: largestArmyPoints,
                  color: Colors.red,
                ),

              if (player.hasLargestArmy) const SizedBox(height: 8),

              if (victoryPointCardCount > 0)
                _buildPointItem(
                  icon: Icons.style,
                  label: '勝利点カード',
                  count: victoryPointCardCount,
                  pointsPerItem: 1,
                  totalPoints: victoryPointCardCount,
                  color: Colors.orange,
                ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // 勝利条件
              _buildVictoryCondition(totalPoints),
            ],
          ],
        ),
      ),
    );
  }

  /// ヘッダー
  Widget _buildHeader(int totalPoints) {
    return Row(
      children: [
        const Icon(
          Icons.emoji_events,
          size: 28,
          color: Colors.amber,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            '勝利点',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: totalPoints >= GameConstants.victoryPointsToWin
                ? Colors.amber
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: totalPoints >= GameConstants.victoryPointsToWin
                  ? Colors.orange
                  : Colors.grey,
              width: 2,
            ),
          ),
          child: Text(
            totalPoints.toString(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: totalPoints >= GameConstants.victoryPointsToWin
                  ? Colors.white
                  : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  /// ポイント項目
  Widget _buildPointItem({
    required IconData icon,
    required String label,
    required int count,
    required int pointsPerItem,
    required int totalPoints,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
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
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$count × $pointsPerItem点',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              '+$totalPoints',
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

  /// 特別ポイント項目
  Widget _buildSpecialPointItem({
    required String icon,
    required String label,
    required int points,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
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
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              '+$points',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 勝利条件
  Widget _buildVictoryCondition(int totalPoints) {
    final pointsNeeded = GameConstants.victoryPointsToWin - totalPoints;
    final hasWon = totalPoints >= GameConstants.victoryPointsToWin;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: hasWon ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: hasWon ? Colors.green : Colors.orange,
          width: 2.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasWon ? Icons.celebration : Icons.flag,
            size: 24,
            color: hasWon ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasWon ? '勝利！' : '勝利まで',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: hasWon ? Colors.green : Colors.orange,
                  ),
                ),
                Text(
                  hasWon
                      ? '${GameConstants.victoryPointsToWin}点に到達しました！'
                      : 'あと$pointsNeeded点必要',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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

/// コンパクトな勝利点表示
class CompactVictoryPointsWidget extends StatelessWidget {
  final Player player;

  const CompactVictoryPointsWidget({
    super.key,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final totalPoints = player.calculateVictoryPoints();
    final hasWon = totalPoints >= GameConstants.victoryPointsToWin;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: hasWon ? Colors.amber : Colors.grey[200],
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: hasWon ? Colors.orange : Colors.grey,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasWon ? Icons.celebration : Icons.emoji_events,
            size: 20,
            color: hasWon ? Colors.white : Colors.grey[700],
          ),
          const SizedBox(width: 8),
          Text(
            '$totalPoints / ${GameConstants.victoryPointsToWin}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: hasWon ? Colors.white : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
