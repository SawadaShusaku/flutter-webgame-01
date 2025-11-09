import 'package:flutter/material.dart';

// modelsパッケージからimport
import 'package:test_web_app/models/hex_tile.dart';
import 'package:test_web_app/models/enums.dart';

// utilsからimport
import 'package:test_web_app/utils/constants.dart';

/// 現在盗賊がいるヘックスを示すインジケーター
class RobberIndicatorWidget extends StatelessWidget {
  final HexTile? robberHex;
  final bool showDetails;
  final VoidCallback? onTap;

  const RobberIndicatorWidget({
    super.key,
    this.robberHex,
    this.showDetails = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (robberHex == null) {
      return const SizedBox.shrink();
    }

    if (showDetails) {
      return _buildDetailedIndicator();
    } else {
      return _buildCompactIndicator();
    }
  }

  /// 詳細インジケーター
  Widget _buildDetailedIndicator() {
    final terrainName = _getTerrainName(robberHex!.terrain);
    final terrainColor = GameColors.terrainColors[robberHex!.terrain] ?? Colors.grey;
    final terrainIcon = ResourceIcons.terrainIcons[robberHex!.terrain] ?? '❓';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 盗賊アイコン
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '🦹',
                  style: TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 位置情報
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '盗賊の位置',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      terrainIcon,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      terrainName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (robberHex!.number != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: GameColors.getNumberColor(robberHex!.number!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${robberHex!.number}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// コンパクトインジケーター
  Widget _buildCompactIndicator() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Text(
          '🦹',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  /// 地形名を取得
  String _getTerrainName(TerrainType terrain) {
    switch (terrain) {
      case TerrainType.forest:
        return '森林';
      case TerrainType.hills:
        return '丘陵';
      case TerrainType.pasture:
        return '牧草地';
      case TerrainType.fields:
        return '畑';
      case TerrainType.mountains:
        return '山地';
      case TerrainType.desert:
        return '砂漠';
    }
  }
}

/// ボード上に表示する盗賊のオーバーレイ
class RobberOverlayWidget extends StatelessWidget {
  final double size;
  final bool animate;

  const RobberOverlayWidget({
    super.key,
    this.size = 32,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (animate) {
      return _AnimatedRobber(size: size);
    } else {
      return _StaticRobber(size: size);
    }
  }
}

/// アニメーション付き盗賊
class _AnimatedRobber extends StatefulWidget {
  final double size;

  const _AnimatedRobber({required this.size});

  @override
  State<_AnimatedRobber> createState() => _AnimatedRobberState();
}

class _AnimatedRobberState extends State<_AnimatedRobber>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: _StaticRobber(size: widget.size),
    );
  }
}

/// 静的な盗賊
class _StaticRobber extends StatelessWidget {
  final double size;

  const _StaticRobber({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.red.shade700,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '🦹',
          style: TextStyle(fontSize: size * 0.6),
        ),
      ),
    );
  }
}
