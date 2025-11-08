import 'package:flutter/material.dart';
import '../../../utils/hex_math.dart';

/// 地形タイプ（modelsパッケージのTerrainTypeに対応）
/// TODO: modelsパッケージが完成したら、そちらのTerrainTypeを使用
enum TerrainType {
  forest,     // 森（木材）
  hills,      // 丘陵（レンガ）
  pasture,    // 牧草地（羊毛）
  fields,     // 畑（小麦）
  mountains,  // 山（鉱石）
  desert,     // 砂漠（資源なし）
}

/// 六角形タイルの描画ウィジェット
class HexTileWidget extends StatelessWidget {
  final HexCoordinate coordinate;
  final TerrainType terrain;
  final int? number; // 数字チップ（2-12、7は除く）、砂漠の場合はnull
  final bool hasRobber; // 盗賊がいるかどうか
  final HexLayout layout;
  final VoidCallback? onTap;
  final bool isHighlighted; // ハイライト表示

  const HexTileWidget({
    super.key,
    required this.coordinate,
    required this.terrain,
    this.number,
    this.hasRobber = false,
    required this.layout,
    this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: HexTilePainter(
        coordinate: coordinate,
        terrain: terrain,
        number: number,
        hasRobber: hasRobber,
        layout: layout,
        isHighlighted: isHighlighted,
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
      ),
    );
  }
}

/// 六角形タイルのペインター
class HexTilePainter extends CustomPainter {
  final HexCoordinate coordinate;
  final TerrainType terrain;
  final int? number;
  final bool hasRobber;
  final HexLayout layout;
  final bool isHighlighted;

  HexTilePainter({
    required this.coordinate,
    required this.terrain,
    this.number,
    required this.hasRobber,
    required this.layout,
    required this.isHighlighted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final corners = layout.hexCorners(coordinate);
    final path = Path();

    // 六角形のパスを作成
    if (corners.isNotEmpty) {
      path.moveTo(corners[0].dx, corners[0].dy);
      for (int i = 1; i < corners.length; i++) {
        path.lineTo(corners[i].dx, corners[i].dy);
      }
      path.close();
    }

    // 地形に応じた塗りつぶし色
    final fillColor = _getTerrainColor(terrain);
    final paint = Paint()
      ..color = isHighlighted ? fillColor.withOpacity(0.8) : fillColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // 六角形の枠線
    final borderPaint = Paint()
      ..color = isHighlighted ? Colors.yellow : Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHighlighted ? 3.0 : 2.0;

    canvas.drawPath(path, borderPaint);

    final center = layout.hexToPixel(coordinate);

    // 数字チップの描画
    if (number != null && terrain != TerrainType.desert) {
      _drawNumberChip(canvas, center, number!);
    }

    // 盗賊の描画
    if (hasRobber) {
      _drawRobber(canvas, center);
    }
  }

  /// 地形タイプに応じた色を取得
  Color _getTerrainColor(TerrainType terrain) {
    switch (terrain) {
      case TerrainType.forest:
        return const Color(0xFF2D5016); // 濃い緑（森）
      case TerrainType.hills:
        return const Color(0xFFB85C38); // 茶色（丘陵）
      case TerrainType.pasture:
        return const Color(0xFF90C850); // 明るい緑（牧草地）
      case TerrainType.fields:
        return const Color(0xFFE8C547); // 黄色（畑）
      case TerrainType.mountains:
        return const Color(0xFF8B8680); // 灰色（山）
      case TerrainType.desert:
        return const Color(0xFFD4B896); // 砂色（砂漠）
    }
  }

  /// 数字チップの描画
  void _drawNumberChip(Canvas canvas, Offset center, int number) {
    // 数字チップの背景円
    final chipRadius = layout.size * 0.35;
    final chipPaint = Paint()
      ..color = const Color(0xFFF5E6D3) // ベージュ
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, chipRadius, chipPaint);

    // 数字チップの枠線
    final chipBorderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, chipRadius, chipBorderPaint);

    // 数字の描画
    final textSpan = TextSpan(
      text: number.toString(),
      style: TextStyle(
        color: _getNumberColor(number),
        fontSize: layout.size * 0.4,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();
    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, textOffset);

    // 確率ドット（6と8は赤、その他は黒）
    if (number == 6 || number == 8) {
      final dotRadius = 2.0;
      final dotPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      final dotCount = 6; // 6と8は出やすい
      final dotY = center.dy + chipRadius * 0.6;

      for (int i = 0; i < dotCount; i++) {
        final dotX = center.dx - (dotCount - 1) * dotRadius + i * dotRadius * 2;
        canvas.drawCircle(Offset(dotX, dotY), dotRadius, dotPaint);
      }
    }
  }

  /// 数字の色を取得（6と8は赤、その他は黒）
  Color _getNumberColor(int number) {
    return (number == 6 || number == 8) ? Colors.red : Colors.black87;
  }

  /// 盗賊の描画
  void _drawRobber(Canvas canvas, Offset center) {
    final robberSize = layout.size * 0.3;

    // 盗賊のシルエット（簡易版：円と帽子）
    final bodyPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // 体部分（円）
    canvas.drawCircle(
      Offset(center.dx, center.dy + robberSize * 0.1),
      robberSize * 0.4,
      bodyPaint,
    );

    // 帽子部分（台形風）
    final hatPath = Path();
    hatPath.moveTo(center.dx - robberSize * 0.3, center.dy - robberSize * 0.2);
    hatPath.lineTo(center.dx + robberSize * 0.3, center.dy - robberSize * 0.2);
    hatPath.lineTo(center.dx + robberSize * 0.2, center.dy - robberSize * 0.5);
    hatPath.lineTo(center.dx - robberSize * 0.2, center.dy - robberSize * 0.5);
    hatPath.close();

    canvas.drawPath(hatPath, bodyPaint);

    // 盗賊の影（アウトライン）
    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(
      Offset(center.dx, center.dy + robberSize * 0.1),
      robberSize * 0.4,
      outlinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant HexTilePainter oldDelegate) {
    return oldDelegate.coordinate != coordinate ||
        oldDelegate.terrain != terrain ||
        oldDelegate.number != number ||
        oldDelegate.hasRobber != hasRobber ||
        oldDelegate.isHighlighted != isHighlighted;
  }
}

/// 地形タイプの拡張メソッド
extension TerrainTypeExtension on TerrainType {
  /// 地形の日本語名を取得
  String get japaneseName {
    switch (this) {
      case TerrainType.forest:
        return '森';
      case TerrainType.hills:
        return '丘陵';
      case TerrainType.pasture:
        return '牧草地';
      case TerrainType.fields:
        return '畑';
      case TerrainType.mountains:
        return '山';
      case TerrainType.desert:
        return '砂漠';
    }
  }

  /// 地形から生産される資源名を取得
  String? get resourceName {
    switch (this) {
      case TerrainType.forest:
        return '木材';
      case TerrainType.hills:
        return 'レンガ';
      case TerrainType.pasture:
        return '羊毛';
      case TerrainType.fields:
        return '小麦';
      case TerrainType.mountains:
        return '鉱石';
      case TerrainType.desert:
        return null; // 砂漠は資源を生産しない
    }
  }
}
