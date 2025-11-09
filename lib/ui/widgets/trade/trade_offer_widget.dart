import 'package:flutter/material.dart';

// modelsパッケージからimport
import 'package:test_web_app/models/player.dart';
import 'package:test_web_app/models/enums.dart';
import 'package:test_web_app/models/trade_offer.dart';

// utilsからimport
import 'package:test_web_app/utils/constants.dart';

/// 交易オファーの表示ウィジェット
class TradeOfferWidget extends StatelessWidget {
  final TradeOffer offer;
  final Player fromPlayer;
  final Player? toPlayer; // nullの場合は全員に提案
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;
  final bool showActions; // アクションボタンを表示するか

  const TradeOfferWidget({
    super.key,
    required this.offer,
    required this.fromPlayer,
    this.toPlayer,
    this.onAccept,
    this.onReject,
    this.onCancel,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final fromColor = GameColors.getPlayerColor(fromPlayer.color);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: _getStatusColor(),
          width: 2.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー（プレイヤー情報とステータス）
            _buildHeader(fromColor),
            const SizedBox(height: 16),

            // 取引内容
            _buildTradeContent(),

            // アクションボタン（承諾/拒否/キャンセル）
            if (showActions && offer.isPending) ...[
              const SizedBox(height: 16),
              _buildActions(),
            ],

            // ステータス表示
            if (!offer.isPending) ...[
              const SizedBox(height: 12),
              _buildStatusInfo(),
            ],
          ],
        ),
      ),
    );
  }

  /// ヘッダー（プレイヤー情報とステータス）
  Widget _buildHeader(Color playerColor) {
    return Row(
      children: [
        // プレイヤーカラー
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
        ),
        const SizedBox(width: 12),

        // プレイヤー名
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fromPlayer.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: playerColor,
                ),
              ),
              Text(
                toPlayer != null ? '${toPlayer!.name} へ提案' : '全員へ提案',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // ステータスバッジ
        _buildStatusBadge(),
      ],
    );
  }

  /// ステータスバッジ
  Widget _buildStatusBadge() {
    final (label, color, icon) = _getStatusInfo();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
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
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 取引内容
  Widget _buildTradeContent() {
    return Row(
      children: [
        // 提供する資源
        Expanded(
          child: _buildResourceSection(
            title: '提供',
            resources: offer.offering,
            color: Colors.red,
            icon: Icons.arrow_upward,
          ),
        ),

        // 矢印
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Icon(
            Icons.swap_horiz,
            size: 32,
            color: Colors.grey[400],
          ),
        ),

        // 要求する資源
        Expanded(
          child: _buildResourceSection(
            title: '要求',
            resources: offer.requesting,
            color: Colors.green,
            icon: Icons.arrow_downward,
          ),
        ),
      ],
    );
  }

  /// 資源セクション
  Widget _buildResourceSection({
    required String title,
    required Map<ResourceType, int> resources,
    required Color color,
    required IconData icon,
  }) {
    final filteredResources = resources.entries
        .where((entry) => entry.value > 0)
        .toList();

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (filteredResources.isEmpty)
            Text(
              'なし',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            )
          else
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
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
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.0),
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
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            '×$count',
            style: TextStyle(
              fontSize: 12,
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

  /// アクションボタン
  Widget _buildActions() {
    return Row(
      children: [
        if (onCancel != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('取り消し'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[400]!),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
        if (onCancel != null && (onAccept != null || onReject != null))
          const SizedBox(width: 12),
        if (onReject != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onReject,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('拒否'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
        if (onReject != null && onAccept != null) const SizedBox(width: 12),
        if (onAccept != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('承諾'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
      ],
    );
  }

  /// ステータス情報
  Widget _buildStatusInfo() {
    final time = offer.respondedAt ?? offer.createdAt;
    final timeStr = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 6),
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// ステータス情報を取得
  (String, Color, IconData) _getStatusInfo() {
    switch (offer.status) {
      case TradeOfferStatus.pending:
        return ('保留中', Colors.orange, Icons.schedule);
      case TradeOfferStatus.accepted:
        return ('承諾', Colors.green, Icons.check_circle);
      case TradeOfferStatus.rejected:
        return ('拒否', Colors.red, Icons.cancel);
      case TradeOfferStatus.cancelled:
        return ('取消', Colors.grey, Icons.block);
    }
  }

  /// ステータスカラーを取得
  Color _getStatusColor() {
    switch (offer.status) {
      case TradeOfferStatus.pending:
        return Colors.orange;
      case TradeOfferStatus.accepted:
        return Colors.green;
      case TradeOfferStatus.rejected:
        return Colors.red;
      case TradeOfferStatus.cancelled:
        return Colors.grey;
    }
  }
}
