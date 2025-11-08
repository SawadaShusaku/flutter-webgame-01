import 'package:flutter/material.dart';
import 'dart:math' as math;

// modelsパッケージからimport
// TODO: pubspec.yamlに依存関係を追加した後、正しいimportパスに変更
// 今は相対パスでmodelsを参照
import '../../../../../models/lib/models/hex_tile.dart';
import '../../../../../models/lib/models/vertex.dart';
import '../../../../../models/lib/models/edge.dart';
import '../../../../../models/lib/models/building.dart';
import '../../../../../models/lib/models/road.dart';
import '../../../../../models/lib/models/player.dart';
import '../../../../../models/lib/models/enums.dart';

// servicesパッケージからimport
import '../../../../../services/lib/services/board_generator.dart';

/// ゲームボード全体を表示するウィジェット
class GameBoardWidget extends StatefulWidget {
  final List<HexTile> hexTiles;
  final List<Vertex> vertices;
  final List<Edge> edges;
  final Map<String, Player>? players; // プレイヤーID -> Player
  final Function(Vertex)? onVertexTap;
  final Function(Edge)? onEdgeTap;
  final Function(HexTile)? onHexTileTap;
  final Set<String>? highlightedVertexIds; // ハイライトする頂点のID
  final Set<String>? highlightedEdgeIds; // ハイライトする辺のID

  const GameBoardWidget({
    super.key,
    required this.hexTiles,
    required this.vertices,
    required this.edges,
    this.players,
    this.onVertexTap,
    this.onEdgeTap,
    this.onHexTileTap,
    this.highlightedVertexIds,
    this.highlightedEdgeIds,
  });

  @override
  State<GameBoardWidget> createState() => _GameBoardWidgetState();
}

class _GameBoardWidgetState extends State<GameBoardWidget> {
  Offset _panOffset = Offset.zero;
  double _scale = 1.0;
  Offset? _tapPosition;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        // ズーム・パン開始
      },
      onScaleUpdate: (details) {
        setState(() {
          _scale = (_scale * details.scale).clamp(0.3, 3.0);
          _panOffset += details.focalPointDelta;
        });
      },
      onTapDown: (details) {
        _tapPosition = details.localPosition;
      },
      onTapUp: (details) {
        if (_tapPosition != null) {
          _handleTap(_tapPosition!);
        }
      },
      child: ClipRect(
        child: CustomPaint(
          size: Size.infinite,
          painter: GameBoardPainter(
            hexTiles: widget.hexTiles,
            vertices: widget.vertices,
            edges: widget.edges,
            players: widget.players,
            panOffset: _panOffset,
            scale: _scale,
            highlightedVertexIds: widget.highlightedVertexIds ?? {},
            highlightedEdgeIds: widget.highlightedEdgeIds ?? {},
          ),
        ),
      ),
    );
  }

  /// タップ処理
  void _handleTap(Offset position) {
    // スクリーン座標をワールド座標に変換
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final worldX = (position.dx - centerX - _panOffset.dx) / _scale;
    final worldY = (position.dy - centerY - _panOffset.dy) / _scale;
    final worldPosition = Offset(worldX, worldY);

    // 頂点をチェック
    for (final vertex in widget.vertices) {
      final distance = (vertex.position - worldPosition).distance;
      if (distance < 15.0) {
        widget.onVertexTap?.call(vertex);
        return;
      }
    }

    // 辺をチェック
    for (final edge in widget.edges) {
      final v1 = widget.vertices.firstWhere((v) => v.id == edge.vertex1Id);
      final v2 = widget.vertices.firstWhere((v) => v.id == edge.vertex2Id);
      final distance = _distanceToLineSegment(
        worldPosition,
        v1.position,
        v2.position,
      );
      if (distance < 15.0) {
        widget.onEdgeTap?.call(edge);
        return;
      }
    }

    // 六角形タイルをチェック
    for (final hexTile in widget.hexTiles) {
      final distance = (hexTile.position - worldPosition).distance;
      if (distance < 80.0) {
        widget.onHexTileTap?.call(hexTile);
        return;
      }
    }
  }

  /// 点から線分までの距離を計算
  double _distanceToLineSegment(Offset point, Offset lineStart, Offset lineEnd) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;
    final lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) {
      return (point - lineStart).distance;
    }

    var t = ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) / lengthSquared;
    t = t.clamp(0.0, 1.0);

    final closestPoint = Offset(
      lineStart.dx + t * dx,
      lineStart.dy + t * dy,
    );

    return (point - closestPoint).distance;
  }
}

/// ゲームボード描画用のペインター
class GameBoardPainter extends CustomPainter {
  final List<HexTile> hexTiles;
  final List<Vertex> vertices;
  final List<Edge> edges;
  final Map<String, Player>? players;
  final Offset panOffset;
  final double scale;
  final Set<String> highlightedVertexIds;
  final Set<String> highlightedEdgeIds;

  GameBoardPainter({
    required this.hexTiles,
    required this.vertices,
    required this.edges,
    this.players,
    required this.panOffset,
    required this.scale,
    required this.highlightedVertexIds,
    required this.highlightedEdgeIds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // キャンバスの中心を原点に
    canvas.translate(size.width / 2, size.height / 2);

    // パンとズームを適用
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(scale);

    // 描画順序：タイル → 辺 → 頂点

    // 1. 六角形タイルを描画
    for (final hexTile in hexTiles) {
      _drawHexTile(canvas, hexTile);
    }

    // 2. 辺を描画
    for (final edge in edges) {
      _drawEdge(canvas, edge);
    }

    // 3. 頂点を描画
    for (final vertex in vertices) {
      _drawVertex(canvas, vertex);
    }

    canvas.restore();
  }

  /// 六角形タイルを描画
  void _drawHexTile(Canvas canvas, HexTile hexTile) {
    const hexSize = 80.0;
    final center = hexTile.position;

    // 六角形のパスを作成
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i;
      final x = center.dx + hexSize * math.cos(angle);
      final y = center.dy + hexSize * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // 地形に応じた塗りつぶし色
    final fillColor = _getTerrainColor(hexTile.terrain);
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // 枠線
    final borderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(path, borderPaint);

    // 数字チップの描画
    if (hexTile.number != null && hexTile.terrain != TerrainType.desert) {
      _drawNumberChip(canvas, center, hexTile.number!);
    }

    // 盗賊の描画
    if (hexTile.hasRobber) {
      _drawRobber(canvas, center);
    }
  }

  /// 地形タイプに応じた色を取得
  Color _getTerrainColor(TerrainType terrain) {
    switch (terrain) {
      case TerrainType.forest:
        return const Color(0xFF2D5016);
      case TerrainType.hills:
        return const Color(0xFFB85C38);
      case TerrainType.pasture:
        return const Color(0xFF90C850);
      case TerrainType.fields:
        return const Color(0xFFE8C547);
      case TerrainType.mountains:
        return const Color(0xFF8B8680);
      case TerrainType.desert:
        return const Color(0xFFD4B896);
    }
  }

  /// 数字チップの描画
  void _drawNumberChip(Canvas canvas, Offset center, int number) {
    const chipRadius = 28.0;

    // 背景円
    final chipPaint = Paint()
      ..color = const Color(0xFFF5E6D3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, chipRadius, chipPaint);

    // 枠線
    final chipBorderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, chipRadius, chipBorderPaint);

    // 数字
    final textSpan = TextSpan(
      text: number.toString(),
      style: TextStyle(
        color: (number == 6 || number == 8) ? Colors.red : Colors.black87,
        fontSize: 32.0,
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

    // 確率ドット
    if (number == 6 || number == 8) {
      const dotRadius = 2.0;
      final dotPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      const dotCount = 5;
      const dotY = 20.0;

      for (int i = 0; i < dotCount; i++) {
        final dotX = center.dx - (dotCount - 1) * dotRadius + i * dotRadius * 2;
        canvas.drawCircle(Offset(dotX, center.dy + dotY), dotRadius, dotPaint);
      }
    }
  }

  /// 盗賊の描画
  void _drawRobber(Canvas canvas, Offset center) {
    const robberSize = 25.0;

    final bodyPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // 体部分
    canvas.drawCircle(
      Offset(center.dx, center.dy + robberSize * 0.1),
      robberSize * 0.4,
      bodyPaint,
    );

    // 帽子部分
    final hatPath = Path();
    hatPath.moveTo(center.dx - robberSize * 0.3, center.dy);
    hatPath.lineTo(center.dx + robberSize * 0.3, center.dy);
    hatPath.lineTo(center.dx + robberSize * 0.2, center.dy - robberSize * 0.5);
    hatPath.lineTo(center.dx - robberSize * 0.2, center.dy - robberSize * 0.5);
    hatPath.close();

    canvas.drawPath(hatPath, bodyPaint);

    // アウトライン
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

  /// 辺を描画
  void _drawEdge(Canvas canvas, Edge edge) {
    final v1 = vertices.firstWhere((v) => v.id == edge.vertex1Id);
    final v2 = vertices.firstWhere((v) => v.id == edge.vertex2Id);

    final isHighlighted = highlightedEdgeIds.contains(edge.id);

    if (edge.hasRoad) {
      // 道路を描画
      final player = players?[edge.road!.playerId];
      final color = player != null ? _getPlayerColor(player.color) : Colors.grey;

      // 枠線
      final borderPaint = Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(v1.position, v2.position, borderPaint);

      // 本体
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(v1.position, v2.position, paint);
    } else if (isHighlighted) {
      // ハイライト表示
      final outerPaint = Paint()
        ..color = Colors.yellow.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(v1.position, v2.position, outerPaint);

      final paint = Paint()
        ..color = Colors.yellowAccent.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(v1.position, v2.position, paint);
    } else {
      // 空の辺
      final paint = Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(v1.position, v2.position, paint);
    }
  }

  /// 頂点を描画
  void _drawVertex(Canvas canvas, Vertex vertex) {
    const vertexSize = 20.0;
    final center = vertex.position;
    final isHighlighted = highlightedVertexIds.contains(vertex.id);

    if (vertex.hasBuilding) {
      // 建設物を描画
      final building = vertex.building!;
      final player = players?[building.playerId];
      final color = player != null ? _getPlayerColor(player.color) : Colors.grey;

      if (building.type == BuildingType.settlement) {
        _drawSettlement(canvas, center, vertexSize, color);
      } else if (building.type == BuildingType.city) {
        _drawCity(canvas, center, vertexSize, color);
      }
    } else if (isHighlighted) {
      // ハイライト表示
      final paint = Paint()
        ..color = Colors.yellowAccent.withOpacity(0.7)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, vertexSize * 0.4, paint);

      final outerPaint = Paint()
        ..color = Colors.yellow.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawCircle(center, vertexSize * 0.6, outerPaint);
    } else {
      // 空の頂点
      final paint = Paint()
        ..color = Colors.grey.withOpacity(0.5)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, vertexSize * 0.2, paint);
    }
  }

  /// 集落の描画
  void _drawSettlement(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final houseSize = size * 0.8;
    final houseHeight = houseSize * 0.6;
    final roofHeight = houseSize * 0.4;

    // 家の本体
    final bodyRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + roofHeight * 0.3),
      width: houseSize * 0.7,
      height: houseHeight,
    );
    canvas.drawRect(bodyRect, paint);

    // 屋根
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

  /// 都市の描画
  void _drawCity(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final citySize = size * 0.9;

    // 左のタワー
    final leftTowerRect = Rect.fromCenter(
      center: Offset(center.dx - citySize * 0.2, center.dy + citySize * 0.1),
      width: citySize * 0.35,
      height: citySize * 0.7,
    );
    canvas.drawRect(leftTowerRect, paint);

    // 右のタワー
    final rightTowerRect = Rect.fromCenter(
      center: Offset(center.dx + citySize * 0.2, center.dy),
      width: citySize * 0.35,
      height: citySize * 0.9,
    );
    canvas.drawRect(rightTowerRect, paint);

    // 塔の上部
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

  /// プレイヤーカラーをFlutterのColorに変換
  Color _getPlayerColor(PlayerColor color) {
    switch (color) {
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

  @override
  bool shouldRepaint(covariant GameBoardPainter oldDelegate) {
    return hexTiles != oldDelegate.hexTiles ||
        vertices != oldDelegate.vertices ||
        edges != oldDelegate.edges ||
        panOffset != oldDelegate.panOffset ||
        scale != oldDelegate.scale ||
        highlightedVertexIds != oldDelegate.highlightedVertexIds ||
        highlightedEdgeIds != oldDelegate.highlightedEdgeIds;
  }
}
