import 'package:flutter/material.dart';
import 'catan_widgets.dart';
import 'game_board_demo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catan Widgets Demo',
      theme: ThemeData.light(),
      home: const DemoSelectionScreen(),
    );
  }
}

/// デモ選択画面
class DemoSelectionScreen extends StatelessWidget {
  const DemoSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catan Widgets Demo'),
        backgroundColor: Colors.brown,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'カタンウィジェットデモ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                '表示するデモを選択してください',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildDemoCard(
                context,
                title: '🎮 ゲームボードデモ',
                description: 'BoardGeneratorを使用した実際のゲームボード\n集落・都市・道路の配置が可能',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GameBoardDemo(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildDemoCard(
                context,
                title: '🎨 シンプルデモ',
                description: '基本ウィジェットのテスト用デモ\nカスタムレイアウトとボードデータ',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SimpleCatanBoardDemo(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCard(
    BuildContext context, {
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// シンプルなカタンボードデモ（旧デモ）
class SimpleCatanBoardDemo extends StatefulWidget {
  const SimpleCatanBoardDemo({super.key});

  @override
  State<SimpleCatanBoardDemo> createState() => _SimpleCatanBoardDemoState();
}

class _SimpleCatanBoardDemoState extends State<SimpleCatanBoardDemo> {
  late List<BoardTileData> tiles;
  late List<BoardVertexData> vertices;
  late List<BoardEdgeData> edges;
  late HexLayout layout;

  @override
  void initState() {
    super.initState();

    // レイアウトの初期化
    layout = const HexLayout(
      orientation: HexOrientation.flatTop,
      size: 50.0,
      origin: Offset.zero,
    );

    // 標準ボードのタイルを生成
    tiles = BoardDataGenerator.generateStandardBoard();

    // 頂点と辺を生成
    vertices = BoardDataGenerator.generateVertices(tiles, layout);
    edges = BoardDataGenerator.generateEdges(tiles, layout);

    // デモ用：いくつかの頂点と辺に建設物と道路を配置
    _addDemoBuildings();
  }

  void _addDemoBuildings() {
    // デモ用の建設物と道路を追加
    if (vertices.length > 10 && edges.length > 10) {
      // 赤プレイヤーの集落
      vertices = List.from(vertices);
      vertices[5] = BoardVertexData(
        vertexId: vertices[5].vertexId,
        position: vertices[5].position,
        buildingType: BuildingType.settlement,
        playerColor: PlayerColor.red,
      );

      // 青プレイヤーの都市
      vertices[15] = BoardVertexData(
        vertexId: vertices[15].vertexId,
        position: vertices[15].position,
        buildingType: BuildingType.city,
        playerColor: PlayerColor.blue,
      );

      // 緑プレイヤーの集落
      vertices[25] = BoardVertexData(
        vertexId: vertices[25].vertexId,
        position: vertices[25].position,
        buildingType: BuildingType.settlement,
        playerColor: PlayerColor.green,
      );

      // 黄プレイヤーの集落
      vertices[35] = BoardVertexData(
        vertexId: vertices[35].vertexId,
        position: vertices[35].position,
        buildingType: BuildingType.settlement,
        playerColor: PlayerColor.yellow,
      );

      // 道路を追加
      edges = List.from(edges);
      edges[3] = BoardEdgeData(
        edgeId: edges[3].edgeId,
        startPosition: edges[3].startPosition,
        endPosition: edges[3].endPosition,
        hasRoad: true,
        playerColor: PlayerColor.red,
      );

      edges[10] = BoardEdgeData(
        edgeId: edges[10].edgeId,
        startPosition: edges[10].startPosition,
        endPosition: edges[10].endPosition,
        hasRoad: true,
        playerColor: PlayerColor.blue,
      );

      edges[20] = BoardEdgeData(
        edgeId: edges[20].edgeId,
        startPosition: edges[20].startPosition,
        endPosition: edges[20].endPosition,
        hasRoad: true,
        playerColor: PlayerColor.green,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catan Board Widgets Demo'),
        backgroundColor: Colors.brown,
      ),
      body: Column(
        children: [
          // 情報パネル
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.brown.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catan Board Widgets Demo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('タイル数: ${tiles.length}'),
                Text('頂点数: ${vertices.length}'),
                Text('辺数: ${edges.length}'),
                const SizedBox(height: 8),
                const Text(
                  'ピンチでズーム、ドラッグでパン操作ができます',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          // ボード表示
          Expanded(
            child: CatanBoardWidget(
              tiles: tiles,
              layout: layout,
              vertices: vertices,
              edges: edges,
              onTileTap: (coordinate) {
                debugPrint('Tile tapped: $coordinate');
              },
              onVertexTap: (vertexId) {
                debugPrint('Vertex tapped: $vertexId');
              },
              onEdgeTap: (edgeId) {
                debugPrint('Edge tapped: $edgeId');
              },
            ),
          ),
          // 操作パネル
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.brown.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: _resetBoard,
                  icon: const Icon(Icons.refresh),
                  label: const Text('リセット'),
                ),
                ElevatedButton.icon(
                  onPressed: _addRandomBuilding,
                  icon: const Icon(Icons.add_home),
                  label: const Text('建物追加'),
                ),
                ElevatedButton.icon(
                  onPressed: _addRandomRoad,
                  icon: const Icon(Icons.add_road),
                  label: const Text('道路追加'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _resetBoard() {
    setState(() {
      vertices = BoardDataGenerator.generateVertices(tiles, layout);
      edges = BoardDataGenerator.generateEdges(tiles, layout);
      _addDemoBuildings();
    });
  }

  void _addRandomBuilding() {
    setState(() {
      final random = DateTime.now().millisecondsSinceEpoch;
      final index = random % vertices.length;
      final colors = [
        PlayerColor.red,
        PlayerColor.blue,
        PlayerColor.green,
        PlayerColor.yellow
      ];
      final types = [BuildingType.settlement, BuildingType.city];

      vertices = List.from(vertices);
      vertices[index] = BoardVertexData(
        vertexId: vertices[index].vertexId,
        position: vertices[index].position,
        buildingType: types[random % types.length],
        playerColor: colors[random % colors.length],
      );
    });
  }

  void _addRandomRoad() {
    setState(() {
      final random = DateTime.now().millisecondsSinceEpoch;
      final index = random % edges.length;
      final colors = [
        PlayerColor.red,
        PlayerColor.blue,
        PlayerColor.green,
        PlayerColor.yellow
      ];

      edges = List.from(edges);
      edges[index] = BoardEdgeData(
        edgeId: edges[index].edgeId,
        startPosition: edges[index].startPosition,
        endPosition: edges[index].endPosition,
        hasRoad: true,
        playerColor: colors[random % colors.length],
      );
    });
  }
}
