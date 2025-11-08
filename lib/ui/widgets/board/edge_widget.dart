import 'package:flutter/material.dart';
import 'vertex_widget.dart'; // PlayerColorを使用

/// 辺ウィジェット（道路を配置する位置）
class EdgeWidget extends StatelessWidget {
  final String edgeId; // 辺の一意なID
  final Offset startPosition; // 開始頂点の位置
  final Offset endPosition; // 終了頂点の位置
  final bool hasRoad; // 道路が配置されているか
  final PlayerColor? playerColor; // 道路の所有者の色
  final bool isHighlighted; // ハイライト表示（配置可能な場合など）
  final VoidCallback? onTap;

  const EdgeWidget({
    super.key,
    required this.edgeId,
    required this.startPosition,
    required this.endPosition,
    this.hasRoad = false,
    this.playerColor,
    this.isHighlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: CustomPaint(
        size: Size.infinite,
        painter: EdgePainter(
          startPosition: startPosition,
          endPosition: endPosition,
          hasRoad: hasRoad,
          playerColor: playerColor,
          isHighlighted: isHighlighted,
        ),
      ),
    );
  }
}

/// 辺のペインター
class EdgePainter extends CustomPainter {
  final Offset startPosition;
  final Offset endPosition;
  final bool hasRoad;
  final PlayerColor? playerColor;
  final bool isHighlighted;

  EdgePainter({
    required this.startPosition,
    required this.endPosition,
    this.hasRoad = false,
    this.playerColor,
    required this.isHighlighted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hasRoad && playerColor != null) {
      // 道路を描画
      _drawRoad(canvas, playerColor!);
    } else if (isHighlighted) {
      // ハイライト表示（配置可能な辺）
      _drawHighlight(canvas);
    } else {
      // 空の辺（細い線）
      _drawEmptyEdge(canvas);
    }
  }

  /// 道路の描画
  void _drawRoad(Canvas canvas, PlayerColor color) {
    final paint = Paint()
      ..color = _getPlayerColor(color)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(startPosition, endPosition, paint);

    // 枠線（黒い縁取り）
    final borderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    // 枠線を先に描いて、その上に本体を描画
    canvas.drawLine(startPosition, endPosition, borderPaint);
    canvas.drawLine(startPosition, endPosition, paint);
  }

  /// ハイライト表示（配置可能な辺）
  void _drawHighlight(Canvas canvas) {
    // 点滅効果用の外側の線
    final outerPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(startPosition, endPosition, outerPaint);

    // メインのハイライト線
    final paint = Paint()
      ..color = Colors.yellowAccent.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(startPosition, endPosition, paint);
  }

  /// 空の辺（細い線）
  void _drawEmptyEdge(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(startPosition, endPosition, paint);
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
  bool shouldRepaint(covariant EdgePainter oldDelegate) {
    return oldDelegate.startPosition != startPosition ||
        oldDelegate.endPosition != endPosition ||
        oldDelegate.hasRoad != hasRoad ||
        oldDelegate.playerColor != playerColor ||
        oldDelegate.isHighlighted != isHighlighted;
  }

  @override
  bool hitTest(Offset position) {
    // タップ検出のための当たり判定
    // 線の近くをタップした場合にtrueを返す
    final distance = _distanceToLine(position, startPosition, endPosition);
    return distance < 15.0; // 15ピクセル以内ならヒット
  }

  /// 点から線分までの距離を計算
  double _distanceToLine(Offset point, Offset lineStart, Offset lineEnd) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;
    final lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) {
      // 線分が点の場合
      return (point - lineStart).distance;
    }

    // 線分上の最も近い点のパラメータt（0〜1）を計算
    var t = ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) / lengthSquared;
    t = t.clamp(0.0, 1.0);

    // 最も近い点を計算
    final closestPoint = Offset(
      lineStart.dx + t * dx,
      lineStart.dy + t * dy,
    );

    return (point - closestPoint).distance;
  }
}

/// 辺の向きを計算するユーティリティ
class EdgeOrientation {
  /// 2つの位置から辺の角度を計算（ラジアン）
  static double getAngle(Offset start, Offset end) {
    return (end - start).direction;
  }

  /// 2つの位置から辺の長さを計算
  static double getLength(Offset start, Offset end) {
    return (end - start).distance;
  }

  /// 辺の中点を計算
  static Offset getMidpoint(Offset start, Offset end) {
    return Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );
  }
}
