import 'package:flutter/material.dart';
import '../../../utils/hex_math.dart';

/// 建設物のタイプ（modelsパッケージのBuildingTypeに対応）
/// TODO: modelsパッケージが完成したら、そちらのBuildingTypeを使用
enum BuildingType {
  settlement, // 集落（1勝利点）
  city,       // 都市（2勝利点）
}

/// プレイヤーカラー（modelsパッケージのPlayerColorに対応）
/// TODO: modelsパッケージが完成したら、そちらのPlayerColorを使用
enum PlayerColor {
  red,
  blue,
  green,
  yellow,
}

/// 頂点ウィジェット（集落・都市を配置する位置）
class VertexWidget extends StatelessWidget {
  final String vertexId; // 頂点の一意なID
  final Offset position; // 画面上の位置
  final BuildingType? buildingType; // 配置されている建設物（null = 未配置）
  final PlayerColor? playerColor; // 建設物の所有者の色
  final bool isHighlighted; // ハイライト表示（配置可能な場合など）
  final VoidCallback? onTap;
  final double size; // 頂点のサイズ

  const VertexWidget({
    super.key,
    required this.vertexId,
    required this.position,
    this.buildingType,
    this.playerColor,
    this.isHighlighted = false,
    this.onTap,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - size / 2,
      top: position.dy - size / 2,
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          size: Size(size, size),
          painter: VertexPainter(
            buildingType: buildingType,
            playerColor: playerColor,
            isHighlighted: isHighlighted,
          ),
        ),
      ),
    );
  }
}

/// 頂点のペインター
class VertexPainter extends CustomPainter {
  final BuildingType? buildingType;
  final PlayerColor? playerColor;
  final bool isHighlighted;

  VertexPainter({
    this.buildingType,
    this.playerColor,
    required this.isHighlighted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    if (buildingType != null && playerColor != null) {
      // 建設物を描画
      if (buildingType == BuildingType.settlement) {
        _drawSettlement(canvas, center, size, playerColor!);
      } else if (buildingType == BuildingType.city) {
        _drawCity(canvas, center, size, playerColor!);
      }
    } else if (isHighlighted) {
      // ハイライト表示（配置可能な頂点）
      _drawHighlight(canvas, center, size);
    } else {
      // 空の頂点（小さな円）
      _drawEmptyVertex(canvas, center, size);
    }
  }

  /// 集落の描画（小さな家アイコン）
  void _drawSettlement(Canvas canvas, Offset center, Size size, PlayerColor color) {
    final paint = Paint()
      ..color = _getPlayerColor(color)
      ..style = PaintingStyle.fill;

    final houseSize = size.width * 0.8;
    final houseHeight = houseSize * 0.6;
    final roofHeight = houseSize * 0.4;

    // 家の本体（長方形）
    final bodyRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + roofHeight * 0.3),
      width: houseSize * 0.7,
      height: houseHeight,
    );
    canvas.drawRect(bodyRect, paint);

    // 屋根（三角形）
    final roofPath = Path();
    roofPath.moveTo(center.dx - houseSize * 0.5, center.dy);
    roofPath.lineTo(center.dx + houseSize * 0.5, center.dy);
    roofPath.lineTo(center.dx, center.dy - roofHeight);
    roofPath.close();
    canvas.drawPath(roofPath, paint);

    // 枠線
    final borderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(bodyRect, borderPaint);
    canvas.drawPath(roofPath, borderPaint);
  }

  /// 都市の描画（大きな建物アイコン）
  void _drawCity(Canvas canvas, Offset center, Size size, PlayerColor color) {
    final paint = Paint()
      ..color = _getPlayerColor(color)
      ..style = PaintingStyle.fill;

    final citySize = size.width * 0.9;

    // 都市の本体（2つのタワー）
    final leftTowerRect = Rect.fromCenter(
      center: Offset(center.dx - citySize * 0.2, center.dy + citySize * 0.1),
      width: citySize * 0.35,
      height: citySize * 0.7,
    );
    canvas.drawRect(leftTowerRect, paint);

    final rightTowerRect = Rect.fromCenter(
      center: Offset(center.dx + citySize * 0.2, center.dy),
      width: citySize * 0.35,
      height: citySize * 0.9,
    );
    canvas.drawRect(rightTowerRect, paint);

    // 塔の上部（旗や装飾）
    final topPath = Path();
    topPath.moveTo(center.dx + citySize * 0.05, center.dy - citySize * 0.45);
    topPath.lineTo(center.dx + citySize * 0.35, center.dy - citySize * 0.45);
    topPath.lineTo(center.dx + citySize * 0.35, center.dy - citySize * 0.55);
    topPath.lineTo(center.dx + citySize * 0.05, center.dy - citySize * 0.55);
    topPath.close();
    canvas.drawPath(topPath, paint);

    // 枠線
    final borderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(leftTowerRect, borderPaint);
    canvas.drawRect(rightTowerRect, borderPaint);
    canvas.drawPath(topPath, borderPaint);
  }

  /// ハイライト表示（配置可能な頂点）
  void _drawHighlight(Canvas canvas, Offset center, Size size) {
    final paint = Paint()
      ..color = Colors.yellowAccent.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final radius = size.width * 0.4;
    canvas.drawCircle(center, radius, paint);

    // 点滅効果用の外側の円
    final outerPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, radius * 1.3, outerPaint);
  }

  /// 空の頂点（小さな円）
  void _drawEmptyVertex(Canvas canvas, Offset center, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final radius = size.width * 0.2;
    canvas.drawCircle(center, radius, paint);
  }

  /// プレイヤーカラーをFlutterのColorに変換
  Color _getPlayerColor(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return const Color(0xFFE63946); // 赤
      case PlayerColor.blue:
        return const Color(0xFF457B9D); // 青
      case PlayerColor.green:
        return const Color(0xFF2A9D8F); // 緑
      case PlayerColor.yellow:
        return const Color(0xFFE9C46A); // 黄色
    }
  }

  @override
  bool shouldRepaint(covariant VertexPainter oldDelegate) {
    return oldDelegate.buildingType != buildingType ||
        oldDelegate.playerColor != playerColor ||
        oldDelegate.isHighlighted != isHighlighted;
  }
}

/// プレイヤーカラーの拡張メソッド
extension PlayerColorExtension on PlayerColor {
  /// プレイヤーカラーの日本語名を取得
  String get japaneseName {
    switch (this) {
      case PlayerColor.red:
        return '赤';
      case PlayerColor.blue:
        return '青';
      case PlayerColor.green:
        return '緑';
      case PlayerColor.yellow:
        return '黄';
    }
  }

  /// FlutterのColorに変換
  Color get color {
    switch (this) {
      case PlayerColor.red:
        return const Color(0xFFE63946);
      case PlayerColor.blue:
        return const Color(0xFF457B9D);
      case PlayerColor.green:
        return const Color(0xFF2A9D8F);
      case PlayerColor.yellow:
        return const Color(0xFFE9C46A);
    }
  }
}
