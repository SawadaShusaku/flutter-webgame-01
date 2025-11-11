import 'package:flutter/material.dart';

// modelsパッケージからimport
import 'package:test_web_app/models/player.dart';
import 'package:test_web_app/models/enums.dart';
import 'package:test_web_app/models/trade_offer.dart';

// utilsからimport
import 'package:test_web_app/utils/constants.dart';

/// プレイヤー間取引のダイアログ
class PlayerTradeDialog extends StatefulWidget {
  final Player currentPlayer;
  final List<Player> otherPlayers;
  final Function(TradeOffer) onOfferCreated;

  const PlayerTradeDialog({
    super.key,
    required this.currentPlayer,
    required this.otherPlayers,
    required this.onOfferCreated,
  });

  @override
  State<PlayerTradeDialog> createState() => _PlayerTradeDialogState();
}

class _PlayerTradeDialogState extends State<PlayerTradeDialog> {
  // 提供する資源
  final Map<ResourceType, int> _offering = {
    ResourceType.lumber: 0,
    ResourceType.brick: 0,
    ResourceType.wool: 0,
    ResourceType.grain: 0,
    ResourceType.ore: 0,
  };

  // 要求する資源
  final Map<ResourceType, int> _requesting = {
    ResourceType.lumber: 0,
    ResourceType.brick: 0,
    ResourceType.wool: 0,
    ResourceType.grain: 0,
    ResourceType.ore: 0,
  };

  // 選択された取引相手（nullの場合は全員に提示）
  Player? _selectedPlayer;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            _buildHeader(),
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 取引相手の選択
                    _buildPlayerSelector(),
                    const SizedBox(height: 20),

                    // 提供する資源
                    _buildResourceSelector(
                      title: '提供する資源',
                      resources: _offering,
                      availableResources: widget.currentPlayer.resources,
                      color: Colors.red,
                      icon: Icons.arrow_upward,
                    ),
                    const SizedBox(height: 20),

                    // 要求する資源
                    _buildResourceSelector(
                      title: '要求する資源',
                      resources: _requesting,
                      availableResources: null, // 要求側は制限なし
                      color: Colors.green,
                      icon: Icons.arrow_downward,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // アクションボタン
            _buildActions(),
          ],
        ),
      ),
    );
  }

  /// ヘッダー
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: GameColors.getPlayerColor(widget.currentPlayer.color),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'プレイヤー間取引',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.currentPlayer.name,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  /// 取引相手の選択
  Widget _buildPlayerSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '取引相手',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            // 全員オプション
            _buildPlayerChip(
              null,
              '全員',
              Colors.blue,
            ),
            // 各プレイヤー
            ...widget.otherPlayers.map((player) {
              return _buildPlayerChip(
                player,
                player.name,
                GameColors.getPlayerColor(player.color),
              );
            }),
          ],
        ),
      ],
    );
  }

  /// プレイヤーチップ
  Widget _buildPlayerChip(Player? player, String label, Color color) {
    final isSelected = _selectedPlayer == player;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      avatar: player != null
          ? CircleAvatar(
              backgroundColor: color,
              radius: 12,
            )
          : const Icon(Icons.people, size: 16),
      onSelected: (selected) {
        setState(() {
          _selectedPlayer = player;
        });
      },
      selectedColor: color.withOpacity(0.3),
      checkmarkColor: color,
      side: BorderSide(
        color: isSelected ? color : Colors.grey[400]!,
        width: isSelected ? 2.0 : 1.0,
      ),
    );
  }

  /// 資源セレクター
  Widget _buildResourceSelector({
    required String title,
    required Map<ResourceType, int> resources,
    required Map<ResourceType, int>? availableResources,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: ResourceType.values.map((resourceType) {
              final available = availableResources?[resourceType];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildResourceRow(
                  resourceType,
                  resources[resourceType]!,
                  available,
                  (value) {
                    setState(() {
                      resources[resourceType] = value;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 資源行
  Widget _buildResourceRow(
    ResourceType resource,
    int value,
    int? available,
    Function(int) onChanged,
  ) {
    final icon = ResourceIcons.getIcon(resource);
    final color = GameColors.getResourceColor(resource);
    final name = _getResourceName(resource);
    final maxValue = available ?? 10; // 要求側は最大10まで

    return Row(
      children: [
        // 資源アイコンと名前
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: Text(
              icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (available != null)
                Text(
                  '所持: $available',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),

        // 減らすボタン
        IconButton(
          onPressed: value > 0
              ? () => onChanged(value - 1)
              : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: color,
        ),

        // 数値表示
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: value > 0 ? color : Colors.grey,
            ),
          ),
        ),

        // 増やすボタン
        IconButton(
          onPressed: value < maxValue
              ? () => onChanged(value + 1)
              : null,
          icon: const Icon(Icons.add_circle_outline),
          color: color,
        ),
      ],
    );
  }

  /// アクションボタン
  Widget _buildActions() {
    final canOffer = _canCreateOffer();

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
            child: const Text('キャンセル'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: canOffer ? _createOffer : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
            child: const Text('提案する'),
          ),
        ),
      ],
    );
  }

  /// オファーを作成できるか
  bool _canCreateOffer() {
    // 提供する資源が1つ以上ある
    final hasOffering = _offering.values.any((count) => count > 0);
    // 要求する資源が1つ以上ある
    final hasRequesting = _requesting.values.any((count) => count > 0);
    // 所持資源を超えていない
    final hasEnoughResources = _offering.entries.every((entry) {
      final available = widget.currentPlayer.resources[entry.key] ?? 0;
      return entry.value <= available;
    });

    return hasOffering && hasRequesting && hasEnoughResources;
  }

  /// オファーを作成
  void _createOffer() {
    final offer = TradeOffer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fromPlayerId: widget.currentPlayer.id,
      toPlayerId: _selectedPlayer?.id ?? '', // 空文字列は全員を意味する
      offering: Map.from(_offering),
      requesting: Map.from(_requesting),
    );

    widget.onOfferCreated(offer);
    Navigator.of(context).pop();
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
