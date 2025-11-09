import 'package:flutter/material.dart';

// modelsパッケージからimport
import '../../../../models/lib/models/development_card.dart';
import '../../../../models/lib/models/enums.dart';

/// 発展カードのビジュアル表示ウィジェット
class DevelopmentCardWidget extends StatefulWidget {
  final DevelopmentCard card;
  final bool faceUp; // 表面/裏面
  final bool canPlay; // 使用可能か
  final VoidCallback? onPlay; // カード使用時のコールバック
  final VoidCallback? onTap; // タップ時のコールバック
  final double width;
  final double height;

  const DevelopmentCardWidget({
    super.key,
    required this.card,
    this.faceUp = true,
    this.canPlay = false,
    this.onPlay,
    this.onTap,
    this.width = 120,
    this.height = 160,
  });

  @override
  State<DevelopmentCardWidget> createState() => _DevelopmentCardWidgetState();
}

class _DevelopmentCardWidgetState extends State<DevelopmentCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.faceUp) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(DevelopmentCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.faceUp != oldWidget.faceUp) {
      if (widget.faceUp) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * 3.14159;
          final showFront = angle < 3.14159 / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showFront
                ? _buildCardFront()
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.14159),
                    child: _buildCardBack(),
                  ),
          );
        },
      ),
    );
  }

  /// カード裏面
  Widget _buildCardBack() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.brown.shade700,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.brown.shade900,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 装飾パターン
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.brown.shade300,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  '発展カード',
                  style: TextStyle(
                    color: Colors.brown.shade300,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// カード表面
  Widget _buildCardFront() {
    final cardInfo = _getCardInfo(widget.card.type);
    final isPlayed = widget.card.played;

    return Opacity(
      opacity: isPlayed ? 0.5 : 1.0,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: cardInfo.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPlayed ? Colors.grey : cardInfo.borderColor,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // カード内容
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // カードタイトル
                  Text(
                    cardInfo.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // アイコン
                  Center(
                    child: Icon(
                      cardInfo.icon,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const Spacer(),
                  // 説明テキスト
                  Text(
                    cardInfo.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            // 使用済みマーク
            if (isPlayed)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '使用済み',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // 使用ボタン
            if (widget.canPlay && !isPlayed && widget.onPlay != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onPlay,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '使用',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// カード情報を取得
  _CardInfo _getCardInfo(DevelopmentCardType type) {
    switch (type) {
      case DevelopmentCardType.knight:
        return _CardInfo(
          title: '騎士',
          icon: Icons.shield,
          description: '盗賊を移動させ、\n隣接するプレイヤーから\n資源を1枚奪う',
          color: Colors.red.shade700,
          borderColor: Colors.red.shade900,
        );
      case DevelopmentCardType.victoryPoint:
        return _CardInfo(
          title: '勝利点',
          icon: Icons.emoji_events,
          description: '勝利点+1\n（常に公開）',
          color: Colors.amber.shade700,
          borderColor: Colors.amber.shade900,
        );
      case DevelopmentCardType.roadBuilding:
        return _CardInfo(
          title: '街道建設',
          icon: Icons.alt_route,
          description: '道路を2本まで\n無料で建設できる',
          color: Colors.brown.shade600,
          borderColor: Colors.brown.shade800,
        );
      case DevelopmentCardType.yearOfPlenty:
        return _CardInfo(
          title: '資源発見',
          icon: Icons.card_giftcard,
          description: '好きな資源を\n2枚獲得できる',
          color: Colors.green.shade700,
          borderColor: Colors.green.shade900,
        );
      case DevelopmentCardType.monopoly:
        return _CardInfo(
          title: '資源独占',
          icon: Icons.attach_money,
          description: '特定の資源を\n全プレイヤーから\n奪う',
          color: Colors.purple.shade700,
          borderColor: Colors.purple.shade900,
        );
    }
  }
}

/// カード情報クラス
class _CardInfo {
  final String title;
  final IconData icon;
  final String description;
  final Color color;
  final Color borderColor;

  _CardInfo({
    required this.title,
    required this.icon,
    required this.description,
    required this.color,
    required this.borderColor,
  });
}
