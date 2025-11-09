import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:test_web_app/services/game_controller.dart';
import 'package:test_web_app/ui/screens/normal_play_screen.dart';

enum SetupPhase {
  placeSettlement,
  placeRoad,
}

enum SetupRound {
  firstRound,   // 順番通り
  secondRound,  // 逆順
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  // ゲーム状態
  SetupPhase _currentPhase = SetupPhase.placeSettlement;
  SetupRound _currentRound = SetupRound.firstRound;
  int _currentPlayerIndex = 0;

  // プレイヤー情報
  final List<PlayerInfo> _players = [
    PlayerInfo(name: 'プレイヤー1', color: Colors.red),
    PlayerInfo(name: 'プレイヤー2', color: Colors.blue),
    PlayerInfo(name: 'プレイヤー3', color: Colors.green),
    PlayerInfo(name: 'プレイヤー4', color: Colors.orange),
  ];

  // 配置された集落と道路
  final Map<String, int> _settlements = {}; // vertexId -> playerIndex
  final Map<String, int> _roads = {}; // edgeId -> playerIndex

  // ハイライト用
  String? _hoveredVertexId;
  String? _hoveredEdgeId;

  // ボード設定
  final double _hexSize = 40.0;
  final List<HexTile> _hexTiles = [];

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  void _initializeBoard() {
    // カタンの標準的なボード配置（19個の六角形）
    // 中心からの距離で配置
    final tiles = <HexTile>[];

    // 中央
    tiles.add(HexTile(q: 0, r: 0, resourceType: ResourceType.wheat));

    // 第1リング（6個）
    tiles.add(HexTile(q: 1, r: 0, resourceType: ResourceType.wood));
    tiles.add(HexTile(q: 1, r: -1, resourceType: ResourceType.brick));
    tiles.add(HexTile(q: 0, r: -1, resourceType: ResourceType.sheep));
    tiles.add(HexTile(q: -1, r: 0, resourceType: ResourceType.ore));
    tiles.add(HexTile(q: -1, r: 1, resourceType: ResourceType.wheat));
    tiles.add(HexTile(q: 0, r: 1, resourceType: ResourceType.wood));

    // 第2リング（12個）
    tiles.add(HexTile(q: 2, r: 0, resourceType: ResourceType.sheep));
    tiles.add(HexTile(q: 2, r: -1, resourceType: ResourceType.ore));
    tiles.add(HexTile(q: 2, r: -2, resourceType: ResourceType.wheat));
    tiles.add(HexTile(q: 1, r: -2, resourceType: ResourceType.wood));
    tiles.add(HexTile(q: 0, r: -2, resourceType: ResourceType.brick));
    tiles.add(HexTile(q: -1, r: -1, resourceType: ResourceType.sheep));
    tiles.add(HexTile(q: -2, r: 0, resourceType: ResourceType.ore));
    tiles.add(HexTile(q: -2, r: 1, resourceType: ResourceType.wheat));
    tiles.add(HexTile(q: -2, r: 2, resourceType: ResourceType.wood));
    tiles.add(HexTile(q: -1, r: 2, resourceType: ResourceType.brick));
    tiles.add(HexTile(q: 0, r: 2, resourceType: ResourceType.sheep));
    tiles.add(HexTile(q: 1, r: 1, resourceType: ResourceType.ore));

    _hexTiles.addAll(tiles);
  }

  PlayerInfo get _currentPlayer => _players[_currentPlayerIndex];

  void _placeSettlement(String vertexId) {
    if (!_canPlaceSettlement(vertexId)) return;

    setState(() {
      _settlements[vertexId] = _currentPlayerIndex;
      _currentPhase = SetupPhase.placeRoad;
    });
  }

  void _placeRoad(String edgeId) {
    if (!_canPlaceRoad(edgeId)) return;

    setState(() {
      _roads[edgeId] = _currentPlayerIndex;
      _nextTurn();
    });
  }

  bool _canPlaceSettlement(String vertexId) {
    // すでに集落が配置されているか
    if (_settlements.containsKey(vertexId)) return false;

    // 隣接する頂点に集落があるか（距離ルール）
    // TODO: 実装を簡略化のため、既存の集落がなければOKとする
    // 本来は隣接頂点のチェックが必要

    return true;
  }

  bool _canPlaceRoad(String edgeId) {
    // すでに道路が配置されているか
    if (_roads.containsKey(edgeId)) return false;

    // 配置した集落に隣接しているか
    // TODO: 実装を簡略化

    return true;
  }

  void _nextTurn() {
    setState(() {
      if (_currentRound == SetupRound.firstRound) {
        if (_currentPlayerIndex < _players.length - 1) {
          _currentPlayerIndex++;
        } else {
          // 第2ラウンドへ
          _currentRound = SetupRound.secondRound;
        }
      } else {
        // 第2ラウンド（逆順）
        if (_currentPlayerIndex > 0) {
          _currentPlayerIndex--;
        } else {
          // 初期配置完了
          _setupComplete();
          return;
        }
      }

      _currentPhase = SetupPhase.placeSettlement;
    });
  }

  void _setupComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('初期配置完了'),
        content: const Text('ゲームを開始します！'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // ダイアログを閉じる

              // GameControllerに通常プレイ開始を通知
              final gameController = Provider.of<GameController>(context, listen: false);
              gameController.startNormalPlay();

              // NormalPlayScreenへ遷移
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const NormalPlayScreen(),
                ),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      appBar: AppBar(
        backgroundColor: Colors.brown[700],
        title: const Text('初期配置'),
      ),
      body: Column(
        children: [
          // プレイヤー順と状態表示
          _buildPlayerStatusBar(),

          // ボードエリア
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Center(
                child: GestureDetector(
                  onTapUp: (details) => _handleTap(details.localPosition),
                  child: CustomPaint(
                    size: const Size(600, 600),
                    painter: BoardPainter(
                      hexTiles: _hexTiles,
                      hexSize: _hexSize,
                      settlements: _settlements,
                      roads: _roads,
                      players: _players,
                      currentPhase: _currentPhase,
                      hoveredVertexId: _hoveredVertexId,
                      hoveredEdgeId: _hoveredEdgeId,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 操作ガイド
          _buildInstructionPanel(),
        ],
      ),
    );
  }

  Widget _buildPlayerStatusBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 現在のプレイヤー
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _currentPlayer.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_currentPlayer.name}のターン',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // プレイヤー一覧
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _players.asMap().entries.map((entry) {
              final index = entry.key;
              final player = entry.value;
              final isActive = index == _currentPlayerIndex;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? player.color.withOpacity(0.3) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? player.color : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: player.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        player.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionPanel() {
    String instruction;
    IconData icon;

    if (_currentPhase == SetupPhase.placeSettlement) {
      instruction = '集落を配置してください（交点をタップ）';
      icon = Icons.home;
    } else {
      instruction = '道路を配置してください（辺をタップ）';
      icon = Icons.route;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        border: Border(
          top: BorderSide(color: Colors.orange[300]!, width: 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Text(
            instruction,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '(${_currentRound == SetupRound.firstRound ? "第1" : "第2"}ラウンド)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(Offset position) {
    // ボードの中心を計算
    const boardSize = 600.0;
    final center = Offset(boardSize / 2, boardSize / 2);

    if (_currentPhase == SetupPhase.placeSettlement) {
      // 最も近い頂点を見つける
      final vertexId = _findNearestVertex(position, center);
      if (vertexId != null) {
        _placeSettlement(vertexId);
      }
    } else {
      // 最も近い辺を見つける
      final edgeId = _findNearestEdge(position, center);
      if (edgeId != null) {
        _placeRoad(edgeId);
      }
    }
  }

  String? _findNearestVertex(Offset tapPosition, Offset center) {
    // 全ての六角形の頂点をチェック
    double minDistance = double.infinity;
    String? nearestVertexId;

    for (final hex in _hexTiles) {
      final hexCenter = _hexToPixel(hex.q, hex.r, center);
      final vertices = _getHexVertices(hexCenter);

      for (int i = 0; i < vertices.length; i++) {
        final vertex = vertices[i];
        final distance = (vertex - tapPosition).distance;

        if (distance < 20 && distance < minDistance) {
          minDistance = distance;
          nearestVertexId = '${hex.q},${hex.r},$i';
        }
      }
    }

    return nearestVertexId;
  }

  String? _findNearestEdge(Offset tapPosition, Offset center) {
    // 全ての六角形の辺をチェック
    double minDistance = double.infinity;
    String? nearestEdgeId;

    for (final hex in _hexTiles) {
      final hexCenter = _hexToPixel(hex.q, hex.r, center);
      final vertices = _getHexVertices(hexCenter);

      for (int i = 0; i < vertices.length; i++) {
        final v1 = vertices[i];
        final v2 = vertices[(i + 1) % vertices.length];

        // 辺の中点までの距離
        final edgeMidpoint = Offset(
          (v1.dx + v2.dx) / 2,
          (v1.dy + v2.dy) / 2,
        );
        final distance = (edgeMidpoint - tapPosition).distance;

        if (distance < 15 && distance < minDistance) {
          minDistance = distance;
          nearestEdgeId = '${hex.q},${hex.r},$i';
        }
      }
    }

    return nearestEdgeId;
  }

  Offset _hexToPixel(int q, int r, Offset center) {
    final x = _hexSize * (3.0 / 2.0 * q);
    final y = _hexSize * (math.sqrt(3) / 2.0 * q + math.sqrt(3) * r);
    return Offset(center.dx + x, center.dy + y);
  }

  List<Offset> _getHexVertices(Offset center) {
    final vertices = <Offset>[];
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i;
      final x = center.dx + _hexSize * math.cos(angle);
      final y = center.dy + _hexSize * math.sin(angle);
      vertices.add(Offset(x, y));
    }
    return vertices;
  }
}

// データクラス
class PlayerInfo {
  final String name;
  final Color color;

  PlayerInfo({required this.name, required this.color});
}

class HexTile {
  final int q;
  final int r;
  final ResourceType resourceType;

  HexTile({
    required this.q,
    required this.r,
    required this.resourceType,
  });
}

enum ResourceType {
  wood,
  brick,
  sheep,
  wheat,
  ore,
  desert,
}

// カスタムペインター
class BoardPainter extends CustomPainter {
  final List<HexTile> hexTiles;
  final double hexSize;
  final Map<String, int> settlements;
  final Map<String, int> roads;
  final List<PlayerInfo> players;
  final SetupPhase currentPhase;
  final String? hoveredVertexId;
  final String? hoveredEdgeId;

  BoardPainter({
    required this.hexTiles,
    required this.hexSize,
    required this.settlements,
    required this.roads,
    required this.players,
    required this.currentPhase,
    this.hoveredVertexId,
    this.hoveredEdgeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 六角形を描画
    for (final hex in hexTiles) {
      _drawHex(canvas, hex, center);
    }

    // 配置可能な場所のハイライト（頂点または辺）
    if (currentPhase == SetupPhase.placeSettlement) {
      _drawVertexHighlights(canvas, center);
    } else {
      _drawEdgeHighlights(canvas, center);
    }

    // 道路を描画
    _drawRoads(canvas, center);

    // 集落を描画
    _drawSettlements(canvas, center);
  }

  void _drawHex(Canvas canvas, HexTile hex, Offset center) {
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

    // リソースアイコン（簡易表示）
    final textPainter = TextPainter(
      text: TextSpan(
        text: _getResourceEmoji(hex.resourceType),
        style: const TextStyle(fontSize: 20),
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

  void _drawVertexHighlights(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final Set<String> drawnVertices = {};

    for (final hex in hexTiles) {
      final hexCenter = _hexToPixel(hex.q, hex.r, center);
      final vertices = _getHexVertices(hexCenter);

      for (int i = 0; i < vertices.length; i++) {
        final vertexId = '${hex.q},${hex.r},$i';
        if (drawnVertices.contains(vertexId)) continue;
        drawnVertices.add(vertexId);

        // 既に配置されている場合はスキップ
        if (settlements.containsKey(vertexId)) continue;

        canvas.drawCircle(vertices[i], 6, paint);
      }
    }
  }

  void _drawEdgeHighlights(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final Set<String> drawnEdges = {};

    for (final hex in hexTiles) {
      final hexCenter = _hexToPixel(hex.q, hex.r, center);
      final vertices = _getHexVertices(hexCenter);

      for (int i = 0; i < vertices.length; i++) {
        final edgeId = '${hex.q},${hex.r},$i';
        if (drawnEdges.contains(edgeId)) continue;
        drawnEdges.add(edgeId);

        // 既に配置されている場合はスキップ
        if (roads.containsKey(edgeId)) continue;

        final v1 = vertices[i];
        final v2 = vertices[(i + 1) % vertices.length];
        canvas.drawLine(v1, v2, paint);
      }
    }
  }

  void _drawRoads(Canvas canvas, Offset center) {
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
        ..color = players[playerIndex].color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(v1, v2, paint);
    }
  }

  void _drawSettlements(Canvas canvas, Offset center) {
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

      // 集落（家のアイコン）
      final paint = Paint()
        ..color = players[playerIndex].color
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      // 四角形（家の本体）
      final rect = Rect.fromCenter(
        center: vertex,
        width: 12,
        height: 12,
      );
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);

      // 三角形（屋根）
      final roofPath = Path()
        ..moveTo(vertex.dx, vertex.dy - 6)
        ..lineTo(vertex.dx - 8, vertex.dy)
        ..lineTo(vertex.dx + 8, vertex.dy)
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

  Color _getResourceColor(ResourceType type) {
    switch (type) {
      case ResourceType.wood:
        return Colors.green[700]!;
      case ResourceType.brick:
        return Colors.red[700]!;
      case ResourceType.sheep:
        return Colors.lightGreen[300]!;
      case ResourceType.wheat:
        return Colors.amber[600]!;
      case ResourceType.ore:
        return Colors.grey[600]!;
      case ResourceType.desert:
        return Colors.brown[200]!;
    }
  }

  String _getResourceEmoji(ResourceType type) {
    switch (type) {
      case ResourceType.wood:
        return '🌲';
      case ResourceType.brick:
        return '🧱';
      case ResourceType.sheep:
        return '🐑';
      case ResourceType.wheat:
        return '🌾';
      case ResourceType.ore:
        return '⛰️';
      case ResourceType.desert:
        return '🏜️';
    }
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) {
    return settlements != oldDelegate.settlements ||
        roads != oldDelegate.roads ||
        currentPhase != oldDelegate.currentPhase ||
        hoveredVertexId != oldDelegate.hoveredVertexId ||
        hoveredEdgeId != oldDelegate.hoveredEdgeId;
  }
}
