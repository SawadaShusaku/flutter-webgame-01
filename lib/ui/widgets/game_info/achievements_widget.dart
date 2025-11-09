import 'package:flutter/material.dart';

// modelsパッケージからimport
import 'package:test_web_app/models/player.dart';
import 'package:test_web_app/models/enums.dart';

// utilsからimport
import 'package:test_web_app/utils/constants.dart';

/// 最長交易路と最大騎士力の表示ウィジェット
class AchievementsWidget extends StatelessWidget {
  final Player? longestRoadPlayer; // 最長交易路保持者
  final int longestRoadLength; // 最長交易路の長さ
  final Player? largestArmyPlayer; // 最大騎士力保持者
  final int largestArmySize; // 騎士数
  final bool compact; // コンパクト表示

  const AchievementsWidget({
    super.key,
    this.longestRoadPlayer,
    this.longestRoadLength = 0,
    this.largestArmyPlayer,
    this.largestArmySize = 0,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactView();
    } else {
      return _buildDetailedView();
    }
  }

  /// コンパクト表示
  Widget _buildCompactView() {
    return Row(
      children: [
        if (longestRoadPlayer != null)
          Expanded(
            child: _buildAchievementChip(
              icon: Icons.alt_route,
              color: Colors.brown.shade600,
              player: longestRoadPlayer!,
              value: longestRoadLength,
            ),
          ),
        if (longestRoadPlayer != null && largestArmyPlayer != null)
          const SizedBox(width: 8),
        if (largestArmyPlayer != null)
          Expanded(
            child: _buildAchievementChip(
              icon: Icons.shield,
              color: Colors.red.shade700,
              player: largestArmyPlayer!,
              value: largestArmySize,
            ),
          ),
      ],
    );
  }

  /// 詳細表示
  Widget _buildDetailedView() {
    return Column(
      children: [
        _buildAchievementCard(
          title: '最長交易路',
          subtitle: '${GameConstants.longestRoadPoints}勝利点',
          icon: Icons.alt_route,
          color: Colors.brown.shade600,
          player: longestRoadPlayer,
          value: longestRoadLength,
          valueLabel: '道路',
          minValue: GameConstants.minRoadLengthForBonus,
        ),
        const SizedBox(height: 12),
        _buildAchievementCard(
          title: '最大騎士力',
          subtitle: '${GameConstants.largestArmyPoints}勝利点',
          icon: Icons.shield,
          color: Colors.red.shade700,
          player: largestArmyPlayer,
          value: largestArmySize,
          valueLabel: '騎士',
          minValue: GameConstants.minKnightsForBonus,
        ),
      ],
    );
  }

  /// アチーブメントチップ（コンパクト用）
  Widget _buildAchievementChip({
    required IconData icon,
    required Color color,
    required Player player,
    required int value,
  }) {
    final playerColor = GameColors.getPlayerColor(player.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              player.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: playerColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// アチーブメントカード（詳細用）
  Widget _buildAchievementCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Player? player,
    required int value,
    required String valueLabel,
    required int minValue,
  }) {
    final hasAchievement = player != null && value >= minValue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasAchievement
            ? color.withOpacity(0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAchievement ? color : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasAchievement ? color : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(8),
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
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: hasAchievement ? color : Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasAchievement
                            ? color.withOpacity(0.8)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // ボーナスポイント表示
              if (hasAchievement)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${title == "最長交易路" ? GameConstants.longestRoadPoints : GameConstants.largestArmyPoints}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // プレイヤー情報
          if (hasAchievement)
            _buildPlayerInfo(player, value, valueLabel, color)
          else
            _buildNoPlayerInfo(minValue, valueLabel),
        ],
      ),
    );
  }

  /// プレイヤー情報表示
  Widget _buildPlayerInfo(
    Player player,
    int value,
    String valueLabel,
    Color color,
  ) {
    final playerColor = GameColors.getPlayerColor(player.color);

    return Row(
      children: [
        // プレイヤーアバター
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: playerColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              player.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: playerColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '保持者',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        // 値表示
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                valueLabel,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// プレイヤーなし表示
  Widget _buildNoPlayerInfo(int minValue, String valueLabel) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.help_outline,
            size: 32,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            '未獲得',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$minValue$valueLabel以上で獲得',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

/// シンプルなアチーブメント表示（ヘッダー用）
class SimpleAchievementsBadge extends StatelessWidget {
  final Player? longestRoadPlayer;
  final Player? largestArmyPlayer;

  const SimpleAchievementsBadge({
    super.key,
    this.longestRoadPlayer,
    this.largestArmyPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];

    if (longestRoadPlayer != null) {
      badges.add(_buildBadge(
        icon: Icons.alt_route,
        color: Colors.brown.shade600,
        tooltip: '最長交易路: ${longestRoadPlayer!.name}',
      ));
    }

    if (largestArmyPlayer != null) {
      badges.add(_buildBadge(
        icon: Icons.shield,
        color: Colors.red.shade700,
        tooltip: '最大騎士力: ${largestArmyPlayer!.name}',
      ));
    }

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: badges
          .expand((badge) => [badge, const SizedBox(width: 4)])
          .toList()
        ..removeLast(),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required Color color,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}
