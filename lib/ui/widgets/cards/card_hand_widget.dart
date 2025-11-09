import 'package:flutter/material.dart';

// modelsパッケージからimport
import '../../../../../models/lib/models/player.dart';
import '../../../../../models/lib/models/development_card.dart';
import '../../../../../models/lib/models/enums.dart';

// 発展カードウィジェットをimport
import 'development_card_widget.dart';

/// プレイヤーの発展カード一覧表示ウィジェット
class CardHandWidget extends StatefulWidget {
  final Player player;
  final bool canPlayCards; // カードを使用できる状態か
  final Function(DevelopmentCard)? onCardPlay; // カード使用時のコールバック
  final bool showFaceUp; // カードを表面で表示するか

  const CardHandWidget({
    super.key,
    required this.player,
    this.canPlayCards = true,
    this.onCardPlay,
    this.showFaceUp = true,
  });

  @override
  State<CardHandWidget> createState() => _CardHandWidgetState();
}

class _CardHandWidgetState extends State<CardHandWidget> {
  DevelopmentCard? _selectedCard;

  @override
  Widget build(BuildContext context) {
    final cards = widget.player.developmentCards;

    if (cards.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ヘッダー
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, size: 20),
              const SizedBox(width: 8),
              Text(
                '発展カード (${cards.length}枚)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // カードリスト（横スクロール）
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              final isSelected = _selectedCard == card;
              final canPlay = widget.canPlayCards &&
                             !card.played &&
                             _canPlayCard(card);

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildCardItem(card, isSelected, canPlay),
              );
            },
          ),
        ),
        // カード詳細表示
        if (_selectedCard != null)
          _buildCardDetails(_selectedCard!),
      ],
    );
  }

  /// カードアイテムウィジェット
  Widget _buildCardItem(DevelopmentCard card, bool isSelected, bool canPlay) {
    return Stack(
      children: [
        // カード本体
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..translate(0.0, isSelected ? -10.0 : 0.0),
          child: DevelopmentCardWidget(
            card: card,
            faceUp: widget.showFaceUp,
            canPlay: canPlay,
            onTap: () {
              setState(() {
                _selectedCard = isSelected ? null : card;
              });
            },
            onPlay: canPlay
                ? () {
                    widget.onCardPlay?.call(card);
                  }
                : null,
          ),
        ),
        // 選択インジケーター
        if (isSelected)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: const Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        // 使用不可インジケーター
        if (!canPlay && !card.played && widget.showFaceUp)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.lock,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
      ],
    );
  }

  /// カード詳細表示
  Widget _buildCardDetails(DevelopmentCard card) {
    final cardInfo = _getCardDetailInfo(card.type);

    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: cardInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cardInfo.color,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(cardInfo.icon, color: cardInfo.color),
              const SizedBox(width: 8),
              Text(
                cardInfo.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cardInfo.color,
                ),
              ),
              const Spacer(),
              if (card.played)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '使用済み',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            cardInfo.detailedDescription,
            style: const TextStyle(fontSize: 14),
          ),
          if (cardInfo.usage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '使い方:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: cardInfo.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              cardInfo.usage,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  /// 空の状態表示
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              '発展カードがありません',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// カードが使用可能かチェック
  bool _canPlayCard(DevelopmentCard card) {
    // 勝利点カードは自動的に公開されるため、使用ボタンは不要
    if (card.type == DevelopmentCardType.victoryPoint) {
      return false;
    }
    // その他のカードは使用可能
    return true;
  }

  /// カード詳細情報を取得
  _CardDetailInfo _getCardDetailInfo(DevelopmentCardType type) {
    switch (type) {
      case DevelopmentCardType.knight:
        return _CardDetailInfo(
          title: '騎士カード',
          icon: Icons.shield,
          color: Colors.red.shade700,
          detailedDescription: '盗賊を別のヘックスに移動させ、そのヘックスに隣接する建設物を持つプレイヤーから資源カードを1枚ランダムに奪います。',
          usage: '騎士カード3枚使用で「最大騎士力」(2勝利点)を獲得できます。',
        );
      case DevelopmentCardType.victoryPoint:
        return _CardDetailInfo(
          title: '勝利点カード',
          icon: Icons.emoji_events,
          color: Colors.amber.shade700,
          detailedDescription: '勝利点を1点獲得します。このカードは獲得と同時に公開され、常に勝利点として計算されます。',
          usage: '',
        );
      case DevelopmentCardType.roadBuilding:
        return _CardDetailInfo(
          title: '街道建設カード',
          icon: Icons.alt_route,
          color: Colors.brown.shade600,
          detailedDescription: '資源を消費せずに、道路を2本まで建設できます。',
          usage: '建設する道路の位置を選択してください。',
        );
      case DevelopmentCardType.yearOfPlenty:
        return _CardDetailInfo(
          title: '資源発見カード',
          icon: Icons.card_giftcard,
          color: Colors.green.shade700,
          detailedDescription: '銀行から好きな資源カードを2枚獲得できます。同じ種類でも異なる種類でも構いません。',
          usage: '獲得したい資源を2種類選択してください。',
        );
      case DevelopmentCardType.monopoly:
        return _CardDetailInfo(
          title: '資源独占カード',
          icon: Icons.attach_money,
          color: Colors.purple.shade700,
          detailedDescription: '特定の資源の種類を宣言し、すべての相手プレイヤーが持っているその資源をすべて獲得します。',
          usage: '独占したい資源の種類を選択してください。',
        );
    }
  }
}

/// カード詳細情報クラス
class _CardDetailInfo {
  final String title;
  final IconData icon;
  final Color color;
  final String detailedDescription;
  final String usage;

  _CardDetailInfo({
    required this.title,
    required this.icon,
    required this.color,
    required this.detailedDescription,
    required this.usage,
  });
}
