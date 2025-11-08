import 'package:flutter/material.dart';

// modelsパッケージからimport
import '../../../models/lib/models/hex_tile.dart';
import '../../../models/lib/models/vertex.dart';
import '../../../models/lib/models/edge.dart';
import '../../../models/lib/models/building.dart';
import '../../../models/lib/models/road.dart';
import '../../../models/lib/models/player.dart';
import '../../../models/lib/models/enums.dart';

// servicesパッケージからimport
import '../../../services/lib/services/board_generator.dart';

// ui-widgetsからimport
import 'ui/widgets/board/game_board_widget.dart';

/// GameBoardWidgetのデモアプリケーション
class GameBoardDemo extends StatefulWidget {
  const GameBoardDemo({super.key});

  @override
  State<GameBoardDemo> createState() => _GameBoardDemoState();
}

class _GameBoardDemoState extends State<GameBoardDemo> {
  late List<HexTile> hexTiles;
  late List<Vertex> vertices;
  late List<Edge> edges;
  late String desertHexId;
  late Map<String, Player> players;

  Set<String> highlightedVertexIds = {};
  Set<String> highlightedEdgeIds = {};

  String? selectedAction; // 'settlement', 'city', 'road'
  String currentPlayerId = 'player1';

  @override
  void initState() {
    super.initState();
    _initializeBoard();
    _initializePlayers();
  }

  /// ボードを初期化
  void _initializeBoard() {
    final generator = BoardGenerator();
    final board = generator.generateBoard(randomize: true);

    hexTiles = board.hexTiles;
    vertices = board.vertices;
    edges = board.edges;
    desertHexId = board.desertHexId;
  }

  /// プレイヤーを初期化
  void _initializePlayers() {
    players = {
      'player1': Player(
        id: 'player1',
        name: 'プレイヤー1',
        color: PlayerColor.red,
      ),
      'player2': Player(
        id: 'player2',
        name: 'プレイヤー2',
        color: PlayerColor.blue,
      ),
      'player3': Player(
        id: 'player3',
        name: 'プレイヤー3',
        color: PlayerColor.green,
      ),
      'player4': Player(
        id: 'player4',
        name: 'プレイヤー4',
        color: PlayerColor.yellow,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カタンボードゲーム - デモ'),
        backgroundColor: Colors.brown,
      ),
      body: Column(
        children: [
          // 情報パネル
          _buildInfoPanel(),
          // ボード表示
          Expanded(
            child: GameBoardWidget(
              hexTiles: hexTiles,
              vertices: vertices,
              edges: edges,
              players: players,
              onVertexTap: _handleVertexTap,
              onEdgeTap: _handleEdgeTap,
              onHexTileTap: _handleHexTileTap,
              highlightedVertexIds: highlightedVertexIds,
              highlightedEdgeIds: highlightedEdgeIds,
            ),
          ),
          // 操作パネル
          _buildControlPanel(),
        ],
      ),
    );
  }

  /// 情報パネル
  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: Colors.brown.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'カタンボードゲーム',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPlayerColor(players[currentPlayerId]!.color),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  players[currentPlayerId]!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'タイル: ${hexTiles.length}, 頂点: ${vertices.length}, 辺: ${edges.length}',
            style: const TextStyle(fontSize: 12),
          ),
          if (selectedAction != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '選択中: ${_getActionName(selectedAction!)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 操作パネル
  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: Colors.brown.shade100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // プレイヤー選択
          Row(
            children: [
              const Text('プレイヤー: '),
              ...players.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        currentPlayerId = entry.key;
                        selectedAction = null;
                        highlightedVertexIds.clear();
                        highlightedEdgeIds.clear();
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getPlayerColor(entry.value.color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: currentPlayerId == entry.key
                              ? Colors.black
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
          const SizedBox(height: 8),
          // アクションボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                'settlement',
                Icons.home,
                '集落',
                selectedAction == 'settlement',
              ),
              _buildActionButton(
                'city',
                Icons.location_city,
                '都市',
                selectedAction == 'city',
              ),
              _buildActionButton(
                'road',
                Icons.route,
                '道路',
                selectedAction == 'road',
              ),
              IconButton(
                onPressed: _resetBoard,
                icon: const Icon(Icons.refresh),
                tooltip: 'リセット',
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'ピンチでズーム、ドラッグでパン操作',
            style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  /// アクションボタン
  Widget _buildActionButton(
    String action,
    IconData icon,
    String label,
    bool isSelected,
  ) {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          if (selectedAction == action) {
            selectedAction = null;
            highlightedVertexIds.clear();
            highlightedEdgeIds.clear();
          } else {
            selectedAction = action;
            _updateHighlights();
          }
        });
      },
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.orange : null,
      ),
    );
  }

  /// 頂点タップ処理
  void _handleVertexTap(Vertex vertex) {
    if (selectedAction == 'settlement') {
      _placeSettlement(vertex);
    } else if (selectedAction == 'city') {
      _upgradeToCity(vertex);
    } else {
      debugPrint('頂点タップ: ${vertex.id}');
    }
  }

  /// 辺タップ処理
  void _handleEdgeTap(Edge edge) {
    if (selectedAction == 'road') {
      _placeRoad(edge);
    } else {
      debugPrint('辺タップ: ${edge.id}');
    }
  }

  /// 六角形タイルタップ処理
  void _handleHexTileTap(HexTile hexTile) {
    debugPrint('タイルタップ: ${hexTile.id}, 地形: ${hexTile.terrain}');
  }

  /// 集落を配置
  void _placeSettlement(Vertex vertex) {
    if (vertex.hasBuilding) {
      _showMessage('すでに建設物があります');
      return;
    }

    // 距離ルール: 隣接する頂点に建設物がないか確認
    for (final edgeId in vertex.adjacentEdgeIds) {
      final edge = edges.firstWhere((e) => e.id == edgeId);
      final otherVertexId =
          edge.vertex1Id == vertex.id ? edge.vertex2Id : edge.vertex1Id;
      final otherVertex = vertices.firstWhere((v) => v.id == otherVertexId);

      if (otherVertex.hasBuilding) {
        _showMessage('近くに建設物があるため配置できません');
        return;
      }
    }

    setState(() {
      vertex.building = Building(
        playerId: currentPlayerId,
        type: BuildingType.settlement,
      );
      players[currentPlayerId]!.settlementsBuilt++;
      _showMessage('集落を配置しました');
    });
  }

  /// 都市にアップグレード
  void _upgradeToCity(Vertex vertex) {
    if (!vertex.hasBuilding) {
      _showMessage('集落がありません');
      return;
    }

    if (vertex.building!.playerId != currentPlayerId) {
      _showMessage('他のプレイヤーの建設物です');
      return;
    }

    if (vertex.building!.type == BuildingType.city) {
      _showMessage('すでに都市です');
      return;
    }

    setState(() {
      vertex.building = Building(
        playerId: currentPlayerId,
        type: BuildingType.city,
      );
      players[currentPlayerId]!.settlementsBuilt--;
      players[currentPlayerId]!.citiesBuilt++;
      _showMessage('都市にアップグレードしました');
    });
  }

  /// 道路を配置
  void _placeRoad(Edge edge) {
    if (edge.hasRoad) {
      _showMessage('すでに道路があります');
      return;
    }

    setState(() {
      edge.road = Road(playerId: currentPlayerId);
      players[currentPlayerId]!.roadsBuilt++;
      _showMessage('道路を配置しました');
    });
  }

  /// ハイライトを更新
  void _updateHighlights() {
    setState(() {
      highlightedVertexIds.clear();
      highlightedEdgeIds.clear();

      if (selectedAction == 'settlement' || selectedAction == 'city') {
        // 建設可能な頂点をハイライト
        for (final vertex in vertices) {
          if (selectedAction == 'settlement' && !vertex.hasBuilding) {
            highlightedVertexIds.add(vertex.id);
          } else if (selectedAction == 'city' &&
              vertex.hasBuilding &&
              vertex.building!.playerId == currentPlayerId &&
              vertex.building!.type == BuildingType.settlement) {
            highlightedVertexIds.add(vertex.id);
          }
        }
      } else if (selectedAction == 'road') {
        // 道路配置可能な辺をハイライト
        for (final edge in edges) {
          if (!edge.hasRoad) {
            highlightedEdgeIds.add(edge.id);
          }
        }
      }
    });
  }

  /// ボードをリセット
  void _resetBoard() {
    setState(() {
      _initializeBoard();
      _initializePlayers();
      selectedAction = null;
      highlightedVertexIds.clear();
      highlightedEdgeIds.clear();
    });
    _showMessage('ボードをリセットしました');
  }

  /// メッセージを表示
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// プレイヤーカラーを取得
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

  /// アクション名を取得
  String _getActionName(String action) {
    switch (action) {
      case 'settlement':
        return '集落を配置';
      case 'city':
        return '都市にアップグレード';
      case 'road':
        return '道路を配置';
      default:
        return '';
    }
  }
}
