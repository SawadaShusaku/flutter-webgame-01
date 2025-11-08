import 'package:flutter/material.dart';
import '../utils/hex_math.dart';
import '../widgets/board/hex_tile_widget.dart';
import '../widgets/board/vertex_widget.dart';
import '../widgets/board/edge_widget.dart';

/// ボード上のタイル情報
class BoardTileData {
  final HexCoordinate coordinate;
  final TerrainType terrain;
  final int? number;
  final bool hasRobber;

  const BoardTileData({
    required this.coordinate,
    required this.terrain,
    this.number,
    this.hasRobber = false,
  });
}

/// ボード上の頂点情報
class BoardVertexData {
  final String vertexId;
  final Offset position;
  final BuildingType? buildingType;
  final PlayerColor? playerColor;

  const BoardVertexData({
    required this.vertexId,
    required this.position,
    this.buildingType,
    this.playerColor,
  });
}

/// ボード上の辺情報
class BoardEdgeData {
  final String edgeId;
  final Offset startPosition;
  final Offset endPosition;
  final bool hasRoad;
  final PlayerColor? playerColor;

  const BoardEdgeData({
    required this.edgeId,
    required this.startPosition,
    required this.endPosition,
    this.hasRoad = false,
    this.playerColor,
  });
}

/// カタンボード全体を描画するペインター
class BoardPainter extends CustomPainter {
  final List<BoardTileData> tiles;
  final HexLayout layout;
  final List<BoardVertexData> vertices;
  final List<BoardEdgeData> edges;

  BoardPainter({
    required this.tiles,
    required this.layout,
    this.vertices = const [],
    this.edges = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 描画順序：
    // 1. 六角形タイル
    // 2. 辺（道路）
    // 3. 頂点（集落・都市）

    // 1. 六角形タイルを描画
    for (final tile in tiles) {
      final tilePainter = HexTilePainter(
        coordinate: tile.coordinate,
        terrain: tile.terrain,
        number: tile.number,
        hasRobber: tile.hasRobber,
        layout: layout,
        isHighlighted: false,
      );
      tilePainter.paint(canvas, size);
    }

    // 2. 辺を描画
    for (final edge in edges) {
      final edgePainter = EdgePainter(
        startPosition: edge.startPosition,
        endPosition: edge.endPosition,
        hasRoad: edge.hasRoad,
        playerColor: edge.playerColor,
        isHighlighted: false,
      );
      edgePainter.paint(canvas, size);
    }

    // 3. 頂点を描画
    for (final vertex in vertices) {
      final vertexPainter = VertexPainter(
        buildingType: vertex.buildingType,
        playerColor: vertex.playerColor,
        isHighlighted: false,
      );

      // 頂点の位置を中心とした小さなキャンバスに描画
      canvas.save();
      canvas.translate(vertex.position.dx, vertex.position.dy);
      vertexPainter.paint(canvas, const Size(20, 20));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    // パフォーマンス最適化：データが変更された場合のみ再描画
    return tiles != oldDelegate.tiles ||
        vertices != oldDelegate.vertices ||
        edges != oldDelegate.edges;
  }
}

/// カタンボード全体を表示するウィジェット
class CatanBoardWidget extends StatefulWidget {
  final List<BoardTileData> tiles;
  final HexLayout layout;
  final List<BoardVertexData> vertices;
  final List<BoardEdgeData> edges;
  final Function(HexCoordinate)? onTileTap;
  final Function(String)? onVertexTap;
  final Function(String)? onEdgeTap;

  const CatanBoardWidget({
    super.key,
    required this.tiles,
    required this.layout,
    this.vertices = const [],
    this.edges = const [],
    this.onTileTap,
    this.onVertexTap,
    this.onEdgeTap,
  });

  @override
  State<CatanBoardWidget> createState() => _CatanBoardWidgetState();
}

class _CatanBoardWidgetState extends State<CatanBoardWidget> {
  Offset _panOffset = Offset.zero;
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        // ズーム・パン開始
      },
      onScaleUpdate: (details) {
        setState(() {
          _scale = (_scale * details.scale).clamp(0.5, 3.0);
          _panOffset += details.focalPointDelta;
        });
      },
      child: ClipRect(
        child: CustomPaint(
          size: Size.infinite,
          painter: TransformableBoardPainter(
            tiles: widget.tiles,
            layout: widget.layout,
            vertices: widget.vertices,
            edges: widget.edges,
            panOffset: _panOffset,
            scale: _scale,
          ),
        ),
      ),
    );
  }
}

/// 変換可能なボードペインター（ズーム・パン対応）
class TransformableBoardPainter extends CustomPainter {
  final List<BoardTileData> tiles;
  final HexLayout layout;
  final List<BoardVertexData> vertices;
  final List<BoardEdgeData> edges;
  final Offset panOffset;
  final double scale;

  TransformableBoardPainter({
    required this.tiles,
    required this.layout,
    required this.vertices,
    required this.edges,
    required this.panOffset,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // キャンバスの中心を原点に
    canvas.translate(size.width / 2, size.height / 2);

    // パンとズームを適用
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(scale);

    // BoardPainterを使用して描画
    final boardPainter = BoardPainter(
      tiles: tiles,
      layout: layout,
      vertices: vertices,
      edges: edges,
    );
    boardPainter.paint(canvas, size);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TransformableBoardPainter oldDelegate) {
    return tiles != oldDelegate.tiles ||
        vertices != oldDelegate.vertices ||
        edges != oldDelegate.edges ||
        panOffset != oldDelegate.panOffset ||
        scale != oldDelegate.scale;
  }
}

/// ボードデータを生成するユーティリティ
class BoardDataGenerator {
  /// 標準的なカタンボードのタイルデータを生成（テスト用）
  static List<BoardTileData> generateStandardBoard() {
    final coordinates = CatanBoardLayout.getStandardBoard();
    final List<BoardTileData> tiles = [];

    // 地形タイプの配列（カタンの標準配置）
    final terrains = [
      TerrainType.mountains,
      TerrainType.pasture,
      TerrainType.forest,
      TerrainType.fields,
      TerrainType.hills,
      TerrainType.pasture,
      TerrainType.hills,
      TerrainType.fields,
      TerrainType.forest,
      TerrainType.desert, // 中心は砂漠
      TerrainType.forest,
      TerrainType.mountains,
      TerrainType.fields,
      TerrainType.mountains,
      TerrainType.forest,
      TerrainType.pasture,
      TerrainType.hills,
      TerrainType.fields,
      TerrainType.pasture,
    ];

    // 数字チップの配列（カタンの標準配置、砂漠は除く）
    final numbers = [
      10, 2, 9, 12, 6, 4, 10, 9, 11,
      null, // 砂漠
      3, 8, 8, 3, 4, 5, 5, 6, 11,
    ];

    for (int i = 0; i < coordinates.length && i < terrains.length; i++) {
      tiles.add(BoardTileData(
        coordinate: coordinates[i],
        terrain: terrains[i],
        number: numbers[i],
        hasRobber: terrains[i] == TerrainType.desert,
      ));
    }

    return tiles;
  }

  /// 全ての頂点データを生成
  static List<BoardVertexData> generateVertices(
    List<BoardTileData> tiles,
    HexLayout layout,
  ) {
    final Map<String, Offset> vertexPositions = {};

    // 各タイルの6つの頂点を生成
    for (final tile in tiles) {
      for (int corner = 0; corner < 6; corner++) {
        final vertexId = HexLayout.getVertexId(tile.coordinate, corner);
        final position = layout.hexCorner(tile.coordinate, corner);
        vertexPositions[vertexId] = position;
      }
    }

    return vertexPositions.entries
        .map((e) => BoardVertexData(
              vertexId: e.key,
              position: e.value,
            ))
        .toList();
  }

  /// 全ての辺データを生成
  static List<BoardEdgeData> generateEdges(
    List<BoardTileData> tiles,
    HexLayout layout,
  ) {
    final Map<String, (Offset, Offset)> edgePositions = {};

    // 各タイルの6つの辺を生成
    for (final tile in tiles) {
      for (int edge = 0; edge < 6; edge++) {
        final edgeId = HexLayout.getEdgeId(tile.coordinate, edge);
        final startCorner = edge;
        final endCorner = (edge + 1) % 6;

        final startPosition = layout.hexCorner(tile.coordinate, startCorner);
        final endPosition = layout.hexCorner(tile.coordinate, endCorner);

        edgePositions[edgeId] = (startPosition, endPosition);
      }
    }

    return edgePositions.entries
        .map((e) => BoardEdgeData(
              edgeId: e.key,
              startPosition: e.value.$1,
              endPosition: e.value.$2,
            ))
        .toList();
  }
}
