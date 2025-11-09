import 'package:flutter/material.dart';
import '../../services/victory_service.dart';

/// ゲーム終了画面
///
/// 勝者の発表と全プレイヤーの最終スコアを表示
class GameOverScreen extends StatelessWidget {
  /// 勝利判定結果
  final VictoryCheckResult victoryResult;

  /// ゲーム統計（オプション）
  final GameStatistics? statistics;

  /// 新規ゲーム開始コールバック
  final VoidCallback? onNewGame;

  /// メニューに戻るコールバック
  final VoidCallback? onBackToMenu;

  const GameOverScreen({
    super.key,
    required this.victoryResult,
    this.statistics,
    this.onNewGame,
    this.onBackToMenu,
  });

  @override
  Widget build(BuildContext context) {
    final winner = victoryResult.winnerBreakdown;
    final allPlayers = victoryResult.allPlayerPoints;

    // 勝利点でソート（降順）
    final sortedPlayers = List<VictoryPointBreakdown>.from(allPlayers)
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 勝利宣言
                _buildVictoryAnnouncement(winner),

                const SizedBox(height: 40),

                // 最終スコアボード
                _buildScoreboard(context, sortedPlayers, winner?.playerId),

                const SizedBox(height: 40),

                // ゲーム統計
                if (statistics != null) ...[
                  _buildStatistics(context, statistics!),
                  const SizedBox(height: 40),
                ],

                // アクションボタン
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 勝利宣言セクション
  Widget _buildVictoryAnnouncement(VictoryPointBreakdown? winner) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.amber, Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'VICTORY!',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          if (winner != null)
            Text(
              'Player ${winner.playerId}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          const SizedBox(height: 8),
          if (winner != null)
            Text(
              '${winner.totalPoints} Victory Points',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }

  /// スコアボードセクション
  Widget _buildScoreboard(
    BuildContext context,
    List<VictoryPointBreakdown> players,
    String? winnerId,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Final Scoreboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          ...players.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            final isWinner = player.playerId == winnerId;

            return _buildPlayerScore(
              context,
              player,
              index + 1,
              isWinner,
            );
          }),
        ],
      ),
    );
  }

  /// プレイヤースコアカード
  Widget _buildPlayerScore(
    BuildContext context,
    VictoryPointBreakdown player,
    int rank,
    bool isWinner,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWinner ? Colors.amber[900] : Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWinner ? Colors.amber : Colors.grey[600]!,
          width: isWinner ? 3 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // プレイヤー情報とランク
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isWinner ? Colors.amber : Colors.grey[700],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isWinner ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Player ${player.playerId}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (isWinner) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                  ],
                ],
              ),
              Text(
                '${player.totalPoints} pts',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 得点内訳
          _buildPointBreakdown(player),
        ],
      ),
    );
  }

  /// 得点内訳
  Widget _buildPointBreakdown(VictoryPointBreakdown player) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (player.settlementPoints > 0)
          _buildPointChip(
            Icons.home,
            'Settlements',
            player.settlementPoints,
            Colors.brown,
          ),
        if (player.cityPoints > 0)
          _buildPointChip(
            Icons.location_city,
            'Cities',
            player.cityPoints,
            Colors.blue,
          ),
        if (player.victoryCardPoints > 0)
          _buildPointChip(
            Icons.star,
            'Victory Cards',
            player.victoryCardPoints,
            Colors.purple,
          ),
        if (player.longestRoadPoints > 0)
          _buildPointChip(
            Icons.route,
            'Longest Road',
            player.longestRoadPoints,
            Colors.orange,
          ),
        if (player.largestArmyPoints > 0)
          _buildPointChip(
            Icons.shield,
            'Largest Army',
            player.largestArmyPoints,
            Colors.red,
          ),
      ],
    );
  }

  /// 得点チップ
  Widget _buildPointChip(
    IconData icon,
    String label,
    int points,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '+$points',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// ゲーム統計セクション
  Widget _buildStatistics(BuildContext context, GameStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Game Statistics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow('Total Turns', '${stats.totalTurns}'),
          _buildStatRow('Game Duration', stats.duration),
          _buildStatRow('Total Roads Built', '${stats.totalRoadsBuilt}'),
          _buildStatRow('Total Settlements Built', '${stats.totalSettlementsBuilt}'),
          _buildStatRow('Total Cities Built', '${stats.totalCitiesBuilt}'),
          _buildStatRow('Development Cards Used', '${stats.developmentCardsUsed}'),
        ],
      ),
    );
  }

  /// 統計行
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// アクションボタン
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (onBackToMenu != null)
          ElevatedButton.icon(
            onPressed: onBackToMenu,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Main Menu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        const SizedBox(width: 16),
        if (onNewGame != null)
          ElevatedButton.icon(
            onPressed: onNewGame,
            icon: const Icon(Icons.refresh),
            label: const Text('New Game'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
      ],
    );
  }
}

/// ゲーム統計データ
class GameStatistics {
  /// 総ターン数
  final int totalTurns;

  /// ゲーム時間
  final String duration;

  /// 建設した道路の総数
  final int totalRoadsBuilt;

  /// 建設した集落の総数
  final int totalSettlementsBuilt;

  /// 建設した都市の総数
  final int totalCitiesBuilt;

  /// 使用した発展カードの総数
  final int developmentCardsUsed;

  const GameStatistics({
    required this.totalTurns,
    required this.duration,
    required this.totalRoadsBuilt,
    required this.totalSettlementsBuilt,
    required this.totalCitiesBuilt,
    required this.developmentCardsUsed,
  });

  /// JSONから作成
  factory GameStatistics.fromJson(Map<String, dynamic> json) {
    return GameStatistics(
      totalTurns: json['totalTurns'] ?? 0,
      duration: json['duration'] ?? '0:00',
      totalRoadsBuilt: json['totalRoadsBuilt'] ?? 0,
      totalSettlementsBuilt: json['totalSettlementsBuilt'] ?? 0,
      totalCitiesBuilt: json['totalCitiesBuilt'] ?? 0,
      developmentCardsUsed: json['developmentCardsUsed'] ?? 0,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'totalTurns': totalTurns,
      'duration': duration,
      'totalRoadsBuilt': totalRoadsBuilt,
      'totalSettlementsBuilt': totalSettlementsBuilt,
      'totalCitiesBuilt': totalCitiesBuilt,
      'developmentCardsUsed': developmentCardsUsed,
    };
  }
}
