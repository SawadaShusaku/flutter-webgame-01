import 'package:flutter/material.dart';

// modelsパッケージからimport
import 'package:test_web_app/models/player.dart';
import 'package:test_web_app/models/enums.dart';
import 'package:test_web_app/models/trade_offer.dart';

// utilsからimport
import 'package:test_web_app/utils/constants.dart';

/// 取引履歴の表示ウィジェット
class TradeHistoryWidget extends StatelessWidget {
  final List<TradeHistoryEntry> history;
  final Map<String, Player> players; // player ID -> Player
  final bool compact;

  const TradeHistoryWidget({
    super.key,
    required this.history,
    required this.players,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = history[history.length - 1 - index]; // 新しい順
        return compact
            ? _buildCompactEntry(entry)
            : _buildDetailedEntry(entry);
      },
    );
  }

  /// 空の状態
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '取引履歴がありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// コンパクト表示
  Widget _buildCompactEntry(TradeHistoryEntry entry) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // 時刻
            Container(
              width: 50,
              child: Text(
                _formatTime(entry.timestamp),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 取引内容
            Expanded(
              child: entry.isBankTrade
                  ? _buildBankTradeCompact(entry.bankTrade!)
                  : _buildPlayerTradeCompact(entry.playerTrade!),
            ),

            // アイコン
            Icon(
              entry.isBankTrade ? Icons.account_balance : Icons.people,
              size: 20,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  /// 詳細表示
  Widget _buildDetailedEntry(TradeHistoryEntry entry) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              children: [
                Icon(
                  entry.isBankTrade ? Icons.account_balance : Icons.people,
                  size: 20,
                  color: entry.isBankTrade ? Colors.brown : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  entry.isBankTrade ? '銀行取引' : 'プレイヤー間取引',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTime(entry.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 取引内容
            entry.isBankTrade
                ? _buildBankTradeDetail(entry.bankTrade!)
                : _buildPlayerTradeDetail(entry.playerTrade!),
          ],
        ),
      ),
    );
  }

  /// 銀行取引（コンパクト）
  Widget _buildBankTradeCompact(BankTrade trade) {
    final player = players[trade.playerId];
    final playerName = player?.name ?? '不明';
    final givingIcon = ResourceIcons.getIcon(trade.giving);
    final receivingIcon = ResourceIcons.getIcon(trade.receiving);

    return Text(
      '$playerName: $givingIcon×${trade.givingAmount} → $receivingIcon×${trade.receivingAmount}',
      style: const TextStyle(fontSize: 13),
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 銀行取引（詳細）
  Widget _buildBankTradeDetail(BankTrade trade) {
    final player = players[trade.playerId];

    return Row(
      children: [
        // プレイヤー情報
        if (player != null) ...[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: GameColors.getPlayerColor(player.color),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${trade.rate}:1 レート',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],

        // 取引内容
        _buildResourceChip(trade.giving, trade.givingAmount),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(
            Icons.arrow_forward,
            size: 20,
            color: Colors.grey[400],
          ),
        ),
        _buildResourceChip(trade.receiving, trade.receivingAmount),
      ],
    );
  }

  /// プレイヤー間取引（コンパクト）
  Widget _buildPlayerTradeCompact(TradeOffer trade) {
    final fromPlayer = players[trade.fromPlayerId];
    final toPlayer = players[trade.toPlayerId];
    final fromName = fromPlayer?.name ?? '不明';
    final toName = toPlayer?.name ?? '不明';

    // 資源の概要
    final offeringCount = trade.offeringTotal;
    final requestingCount = trade.requestingTotal;

    return Text(
      '$fromName → $toName: $offeringCount資源 ⇄ $requestingCount資源',
      style: const TextStyle(fontSize: 13),
      overflow: TextOverflow.ellipsis,
    );
  }

  /// プレイヤー間取引（詳細）
  Widget _buildPlayerTradeDetail(TradeOffer trade) {
    final fromPlayer = players[trade.fromPlayerId];
    final toPlayer = players[trade.toPlayerId];

    return Column(
      children: [
        // 取引相手
        Row(
          children: [
            if (fromPlayer != null) _buildPlayerInfo(fromPlayer, '提供側'),
            Expanded(
              child: Icon(
                Icons.swap_horiz,
                size: 24,
                color: Colors.grey[400],
              ),
            ),
            if (toPlayer != null) _buildPlayerInfo(toPlayer, '受取側'),
          ],
        ),
        const SizedBox(height: 12),

        // 資源の詳細
        Row(
          children: [
            Expanded(
              child: _buildResourceList(
                trade.offering,
                Colors.red,
                '提供',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildResourceList(
                trade.requesting,
                Colors.green,
                '要求',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// プレイヤー情報
  Widget _buildPlayerInfo(Player player, String label) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: GameColors.getPlayerColor(player.color),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          player.name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 資源リスト
  Widget _buildResourceList(
    Map<ResourceType, int> resources,
    Color color,
    String label,
  ) {
    final filteredResources = resources.entries
        .where((entry) => entry.value > 0)
        .toList();

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          if (filteredResources.isEmpty)
            Text(
              'なし',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            )
          else
            Wrap(
              spacing: 4.0,
              runSpacing: 4.0,
              children: filteredResources.map((entry) {
                return _buildResourceChip(entry.key, entry.value);
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// 資源チップ
  Widget _buildResourceChip(ResourceType resource, int count) {
    final icon = ResourceIcons.getIcon(resource);
    final color = GameColors.getResourceColor(resource);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: color,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 3),
          Text(
            '×$count',
            style: TextStyle(
              fontSize: 10,
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

  /// 時刻をフォーマット
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// 取引履歴エントリー
class TradeHistoryEntry {
  final DateTime timestamp;
  final BankTrade? bankTrade;
  final TradeOffer? playerTrade;

  TradeHistoryEntry.bank({
    required this.bankTrade,
  })  : timestamp = bankTrade!.timestamp,
        playerTrade = null;

  TradeHistoryEntry.player({
    required this.playerTrade,
  })  : timestamp = playerTrade!.createdAt,
        bankTrade = null;

  bool get isBankTrade => bankTrade != null;
  bool get isPlayerTrade => playerTrade != null;
}
