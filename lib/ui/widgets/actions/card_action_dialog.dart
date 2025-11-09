import 'package:flutter/material.dart';

// modelsパッケージからimport
import '../../../../../models/lib/models/development_card.dart';
import '../../../../../models/lib/models/enums.dart';

// utilsからimport
import '../../../utils/constants.dart';

/// カード使用時のダイアログ
class CardActionDialog extends StatefulWidget {
  final DevelopmentCard card;
  final Function(Map<String, dynamic>)? onConfirm; // 確定時のコールバック

  const CardActionDialog({
    super.key,
    required this.card,
    this.onConfirm,
  });

  @override
  State<CardActionDialog> createState() => _CardActionDialogState();

  /// ダイアログを表示
  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    DevelopmentCard card,
  ) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CardActionDialog(card: card),
    );
  }
}

class _CardActionDialogState extends State<CardActionDialog> {
  // 騎士カード: 盗賊移動先（ヘックス座標）
  int? _robberHexIndex;

  // 資源発見: 選択した資源2枚
  final List<ResourceType> _selectedResources = [];

  // 資源独占: 選択した資源タイプ
  ResourceType? _monopolyResource;

  // 街道建設: 配置する道路の位置
  final List<int> _roadPositions = [];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildContent(),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  /// ヘッダー
  Widget _buildHeader() {
    final cardInfo = _getCardInfo(widget.card.type);
    return Row(
      children: [
        Icon(cardInfo.icon, color: cardInfo.color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            cardInfo.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// コンテンツ
  Widget _buildContent() {
    switch (widget.card.type) {
      case DevelopmentCardType.knight:
        return _buildKnightContent();
      case DevelopmentCardType.yearOfPlenty:
        return _buildYearOfPlentyContent();
      case DevelopmentCardType.monopoly:
        return _buildMonopolyContent();
      case DevelopmentCardType.roadBuilding:
        return _buildRoadBuildingContent();
      case DevelopmentCardType.victoryPoint:
        return const SizedBox.shrink(); // 勝利点カードは使用しない
    }
  }

  /// 騎士カード用コンテンツ
  Widget _buildKnightContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '盗賊を移動させるヘックスを選択してください:',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '※ ゲームボード上でヘックスをタップして選択してください。\n'
            '選択後、隣接するプレイヤーから資源を1枚奪うことができます。',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        if (_robberHexIndex != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'ヘックス #$_robberHexIndex を選択中',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 資源発見カード用コンテンツ
  Widget _buildYearOfPlentyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '獲得したい資源を2枚選択してください:',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ResourceType.values.map((resource) {
            final icon = ResourceIcons.getIcon(resource);
            final color = GameColors.getResourceColor(resource);
            final isSelected = _selectedResources.contains(resource);
            final count = _selectedResources.where((r) => r == resource).length;

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (_selectedResources.length < 2) {
                    _selectedResources.add(resource);
                  } else if (isSelected) {
                    _selectedResources.remove(resource);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.3)
                      : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? color : color.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 20)),
                    if (count > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          '選択中: ${_selectedResources.length}/2',
          style: TextStyle(
            fontSize: 12,
            color: _selectedResources.length == 2
                ? Colors.green.shade700
                : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// 資源独占カード用コンテンツ
  Widget _buildMonopolyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '独占したい資源を選択してください:',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ResourceType.values.map((resource) {
            final icon = ResourceIcons.getIcon(resource);
            final color = GameColors.getResourceColor(resource);
            final isSelected = _monopolyResource == resource;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _monopolyResource = resource;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.3)
                      : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? color : color.withOpacity(0.3),
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 28)),
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(
                          Icons.check_circle,
                          color: color,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'すべての相手プレイヤーから、選択した資源をすべて獲得します。',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 街道建設カード用コンテンツ
  Widget _buildRoadBuildingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '道路を2本まで建設できます:',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '※ ゲームボード上で道路を配置する辺を選択してください。\n'
            '資源を消費せずに道路を2本まで建設できます。',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        if (_roadPositions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_roadPositions.length}/2 本選択中',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ...(_roadPositions.map((pos) => Text(
                      '  • 道路 #$pos',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade600,
                      ),
                    ))),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// アクションボタン
  Widget _buildActions() {
    final canConfirm = _canConfirm();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: canConfirm ? _onConfirm : null,
          child: const Text('確定'),
        ),
      ],
    );
  }

  /// 確定可能かチェック
  bool _canConfirm() {
    switch (widget.card.type) {
      case DevelopmentCardType.knight:
        return _robberHexIndex != null;
      case DevelopmentCardType.yearOfPlenty:
        return _selectedResources.length == 2;
      case DevelopmentCardType.monopoly:
        return _monopolyResource != null;
      case DevelopmentCardType.roadBuilding:
        return _roadPositions.isNotEmpty;
      case DevelopmentCardType.victoryPoint:
        return false;
    }
  }

  /// 確定時の処理
  void _onConfirm() {
    Map<String, dynamic> result = {};

    switch (widget.card.type) {
      case DevelopmentCardType.knight:
        result = {'robberHexIndex': _robberHexIndex};
        break;
      case DevelopmentCardType.yearOfPlenty:
        result = {'resources': _selectedResources};
        break;
      case DevelopmentCardType.monopoly:
        result = {'resource': _monopolyResource};
        break;
      case DevelopmentCardType.roadBuilding:
        result = {'roadPositions': _roadPositions};
        break;
      case DevelopmentCardType.victoryPoint:
        break;
    }

    if (widget.onConfirm != null) {
      widget.onConfirm!(result);
    }

    Navigator.of(context).pop(result);
  }

  /// カード情報を取得
  _CardInfo _getCardInfo(DevelopmentCardType type) {
    switch (type) {
      case DevelopmentCardType.knight:
        return _CardInfo(
          title: '騎士カードを使用',
          icon: Icons.shield,
          color: Colors.red.shade700,
        );
      case DevelopmentCardType.victoryPoint:
        return _CardInfo(
          title: '勝利点カード',
          icon: Icons.emoji_events,
          color: Colors.amber.shade700,
        );
      case DevelopmentCardType.roadBuilding:
        return _CardInfo(
          title: '街道建設カードを使用',
          icon: Icons.alt_route,
          color: Colors.brown.shade600,
        );
      case DevelopmentCardType.yearOfPlenty:
        return _CardInfo(
          title: '資源発見カードを使用',
          icon: Icons.card_giftcard,
          color: Colors.green.shade700,
        );
      case DevelopmentCardType.monopoly:
        return _CardInfo(
          title: '資源独占カードを使用',
          icon: Icons.attach_money,
          color: Colors.purple.shade700,
        );
    }
  }
}

/// カード情報クラス
class _CardInfo {
  final String title;
  final IconData icon;
  final Color color;

  _CardInfo({
    required this.title,
    required this.icon,
    required this.color,
  });
}
