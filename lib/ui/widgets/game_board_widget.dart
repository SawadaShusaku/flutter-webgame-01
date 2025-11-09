import 'package:flutter/material.dart';
import 'dart:math' as math;

class GameBoardWidget extends StatelessWidget {
  final double hexSize;
  final Map<String, int>? settlements;
  final Map<String, int>? roads;

  const GameBoardWidget({
    super.key,
    this.hexSize = 35.0,
    this.settlements,
    this.roads,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      child: Center(
        child: CustomPaint(
          size: const Size(500, 500),
          painter: _BoardPainter(
            hexSize: hexSize,
            settlements: settlements ?? {},
            roads: roads ?? {},
          ),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  final double hexSize;
  final Map<String, int> settlements;
  final Map<String, int> roads;
  final List<_HexTile> hexTiles;

  _BoardPainter({
    required this.hexSize,
    required this.settlements,
    required this.roads,
  }) : hexTiles = _createHexTiles();

  static List<_HexTile> _createHexTiles() {
    final tiles = <_HexTile>[];

    // 中央
    tiles.add(_HexTile(q: 0, r: 0, resourceType: _ResourceType.wheat));

    // 第1リング（6個）
    tiles.add(_HexTile(q: 1, r: 0, resourceType: _ResourceType.wood));
    tiles.add(_HexTile(q: 1, r: -1, resourceType: _ResourceType.brick));
    tiles.add(_HexTile(q: 0, r: -1, resourceType: _ResourceType.sheep));
    tiles.add(_HexTile(q: -1, r: 0, resourceType: _ResourceType.ore));
    tiles.add(_HexTile(q: -1, r: 1, resourceType: _ResourceType.wheat));
    tiles.add(_HexTile(q: 0, r: 1, resourceType: _ResourceType.wood));

    // 第2リング（12個）
    tiles.add(_HexTile(q: 2, r: 0, resourceType: _ResourceType.sheep));
    tiles.add(_HexTile(q: 2, r: -1, resourceType: _ResourceType.ore));
    tiles.add(_HexTile(q: 2, r: -2, resourceType: _ResourceType.wheat));
    tiles.add(_HexTile(q: 1, r: -2, resourceType: _ResourceType.wood));
    tiles.add(_HexTile(q: 0, r: -2, resourceType: _ResourceType.brick));
    tiles.add(_HexTile(q: -1, r: -1, resourceType: _ResourceType.sheep));
    tiles.add(_HexTile(q: -2, r: 0, resourceType: _ResourceType.ore));
    tiles.add(_HexTile(q: -2, r: 1, resourceType: _ResourceType.wheat));
    tiles.add(_HexTile(q: -2, r: 2, resourceType: _ResourceType.wood));
    tiles.add(_HexTile(q: -1, r: 2, resourceType: _ResourceType.brick));
    tiles.add(_HexTile(q: 0, r: 2, resourceType: _ResourceType.sheep));
    tiles.add(_HexTile(q: 1, r: 1, resourceType: _ResourceType.ore));

    return tiles;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 六角形を描画
    for (final hex in hexTiles) {
      _drawHex(canvas, hex, center);
    }

    // 道路を描画
    _drawRoads(canvas, center);

    // 集落を描画
    _drawSettlements(canvas, center);
  }

  void _drawHex(Canvas canvas, _HexTile hex, Offset center) {
    final hexCenter = _hexToPixel(hex.q, hex.r, center);
    final vertices = _getHexVertices(hexCenter);

    final path = Path();
    path.moveTo(vertices[0].dx, vertices[0].dy);
    for (int i = 1; i < vertices.length; i++) {
      path.lineTo(vertices[i].dx, vertices[i].dy);
    }
    path.close();

    // 六角形の塗りつぶし
    final paint = Paint()
      ..color = _getResourceColor(hex.resourceType)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // 六角形の輪郭
    final borderPaint = Paint()
      ..color = Colors.brown[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);

    // リソースアイコン
    final textPainter = TextPainter(
      text: TextSpan(
        text: _getResourceEmoji(hex.resourceType),
        style: const TextStyle(fontSize: 18),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        hexCenter.dx - textPainter.width / 2,
        hexCenter.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawRoads(Canvas canvas, Offset center) {
    final playerColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
    ];

    for (final entry in roads.entries) {
      final parts = entry.key.split(',');
      final q = int.parse(parts[0]);
      final r = int.parse(parts[1]);
      final edgeIndex = int.parse(parts[2]);
      final playerIndex = entry.value;

      final hex = hexTiles.firstWhere((h) => h.q == q && h.r == r);
      final hexCenter = _hexToPixel(hex.q, hex.r, center);
      final vertices = _getHexVertices(hexCenter);

      final v1 = vertices[edgeIndex];
      final v2 = vertices[(edgeIndex + 1) % vertices.length];

      final paint = Paint()
        ..color = playerColors[playerIndex]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(v1, v2, paint);
    }
  }

  void _drawSettlements(Canvas canvas, Offset center) {
    final playerColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
    ];

    for (final entry in settlements.entries) {
      final parts = entry.key.split(',');
      final q = int.parse(parts[0]);
      final r = int.parse(parts[1]);
      final vertexIndex = int.parse(parts[2]);
      final playerIndex = entry.value;

      final hex = hexTiles.firstWhere((h) => h.q == q && h.r == r);
      final hexCenter = _hexToPixel(hex.q, hex.r, center);
      final vertices = _getHexVertices(hexCenter);
      final vertex = vertices[vertexIndex];

      final paint = Paint()
        ..color = playerColors[playerIndex]
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      // 集落（家）
      final rect = Rect.fromCenter(
        center: vertex,
        width: 10,
        height: 10,
      );
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);

      // 屋根
      final roofPath = Path()
        ..moveTo(vertex.dx, vertex.dy - 5)
        ..lineTo(vertex.dx - 7, vertex.dy)
        ..lineTo(vertex.dx + 7, vertex.dy)
        ..close();
      canvas.drawPath(roofPath, paint);
      canvas.drawPath(roofPath, borderPaint);
    }
  }

  Offset _hexToPixel(int q, int r, Offset center) {
    final x = hexSize * (3.0 / 2.0 * q);
    final y = hexSize * (math.sqrt(3) / 2.0 * q + math.sqrt(3) * r);
    return Offset(center.dx + x, center.dy + y);
  }

  List<Offset> _getHexVertices(Offset center) {
    final vertices = <Offset>[];
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i;
      final x = center.dx + hexSize * math.cos(angle);
      final y = center.dy + hexSize * math.sin(angle);
      vertices.add(Offset(x, y));
    }
    return vertices;
  }

  Color _getResourceColor(_ResourceType type) {
    switch (type) {
      case _ResourceType.wood:
        return Colors.green[700]!;
      case _ResourceType.brick:
        return Colors.red[700]!;
      case _ResourceType.sheep:
        return Colors.lightGreen[300]!;
      case _ResourceType.wheat:
        return Colors.amber[600]!;
      case _ResourceType.ore:
        return Colors.grey[600]!;
    }
  }

  String _getResourceEmoji(_ResourceType type) {
    switch (type) {
      case _ResourceType.wood:
        return '🌲';
      case _ResourceType.brick:
        return '🧱';
      case _ResourceType.sheep:
        return '🐑';
      case _ResourceType.wheat:
        return '🌾';
      case _ResourceType.ore:
        return '⛰️';
    }
  }

  @override
  bool shouldRepaint(_BoardPainter oldDelegate) {
    return settlements != oldDelegate.settlements ||
        roads != oldDelegate.roads;
  }
}

class _HexTile {
  final int q;
  final int r;
  final _ResourceType resourceType;

  _HexTile({
    required this.q,
    required this.r,
    required this.resourceType,
  });
}

enum _ResourceType {
  wood,
  brick,
  sheep,
  wheat,
  ore,
}
