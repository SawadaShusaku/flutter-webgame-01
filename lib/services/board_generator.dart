import 'dart:math';
import 'package:flutter/material.dart';

// modelsからimport
import 'package:test_web_app/models/hex_tile.dart';
import 'package:test_web_app/models/vertex.dart';
import 'package:test_web_app/models/edge.dart';
import 'package:test_web_app/models/trade.dart';
import 'package:test_web_app/models/enums.dart';

/// ボード生成サービス
/// 19枚の六角形タイルを配置し、数字チップをランダムに配置、頂点と辺を生成
class BoardGenerator {
  final Random _random;

  BoardGenerator({Random? random}) : _random = random ?? Random();

  /// 標準的なカタンボードを生成
  /// - 19枚の六角形タイル
  /// - 数字チップ（2-12）をランダムに配置
  /// - 砂漠タイルの処理
  /// - 頂点（Vertex）と辺（Edge）の生成
  /// - 港（Harbor）の配置
  ({
    List<HexTile> hexTiles,
    List<Vertex> vertices,
    List<Edge> edges,
    List<Harbor> harbors,
    String desertHexId,
  }) generateBoard({bool randomize = true}) {
    // 1. タイル配置の生成
    final hexTiles = _generateHexTiles(randomize: randomize);

    // 2. 頂点の生成
    final vertices = _generateVertices(hexTiles);

    // 3. 辺の生成
    final edges = _generateEdges(vertices);

    // 4. 港の生成
    final harbors = _generateHarbors(randomize: randomize);

    // 5. 砂漠タイルのIDを取得
    final desertHex = hexTiles.firstWhere((hex) => hex.terrain == TerrainType.desert);

    return (
      hexTiles: hexTiles,
      vertices: vertices,
      edges: edges,
      harbors: harbors,
      desertHexId: desertHex.id,
    );
  }

  /// 六角形タイルを生成
  List<HexTile> _generateHexTiles({bool randomize = true}) {
    // カタンの標準的な地形配置
    final terrains = [
      TerrainType.forest, TerrainType.forest, TerrainType.forest, TerrainType.forest,
      TerrainType.hills, TerrainType.hills, TerrainType.hills,
      TerrainType.pasture, TerrainType.pasture, TerrainType.pasture, TerrainType.pasture,
      TerrainType.fields, TerrainType.fields, TerrainType.fields, TerrainType.fields,
      TerrainType.mountains, TerrainType.mountains, TerrainType.mountains,
      TerrainType.desert, // 砂漠は1枚のみ
    ];

    // 数字チップ（砂漠を除く18枚分）
    final numbers = [
      2, 3, 3, 4, 4, 5, 5, 6, 6, 8, 8, 9, 9, 10, 10, 11, 11, 12,
    ];

    // ランダム化
    if (randomize) {
      terrains.shuffle(_random);
      numbers.shuffle(_random);
    }

    // 六角形の配置座標を計算
    final positions = _calculateHexPositions();

    // タイルを生成
    final hexTiles = <HexTile>[];
    int numberIndex = 0;

    for (int i = 0; i < terrains.length; i++) {
      final terrain = terrains[i];
      final position = positions[i];

      // 砂漠タイルには数字を割り当てない
      final number = terrain == TerrainType.desert ? null : numbers[numberIndex++];

      hexTiles.add(HexTile(
        id: 'hex_$i',
        terrain: terrain,
        number: number,
        position: position,
        hasRobber: terrain == TerrainType.desert, // 砂漠に初期盗賊を配置
      ));
    }

    return hexTiles;
  }

  /// 六角形の配置位置を計算
  /// カタンの標準的な19枚配置（3-4-5-4-3）
  List<Offset> _calculateHexPositions() {
    const hexSize = 80.0; // 六角形のサイズ
    const hexWidth = hexSize * 2.0;
    const hexHeight = hexSize * sqrt(3);
    const horizontalSpacing = hexWidth * 0.75;
    const verticalSpacing = hexHeight;

    final positions = <Offset>[];

    // 中心座標
    const centerX = 400.0;
    const centerY = 300.0;

    // 各行のタイル数: [3, 4, 5, 4, 3]
    final rowTileCounts = [3, 4, 5, 4, 3];
    int tileIndex = 0;

    for (int row = 0; row < rowTileCounts.length; row++) {
      final tilesInRow = rowTileCounts[row];
      final rowY = centerY + (row - 2) * verticalSpacing;

      // 行のオフセット（奇数行は半タイル分ずらす）
      final rowOffset = (5 - tilesInRow) * horizontalSpacing / 2;

      for (int col = 0; col < tilesInRow; col++) {
        final x = centerX - (tilesInRow - 1) * horizontalSpacing / 2 + col * horizontalSpacing + rowOffset;
        positions.add(Offset(x, rowY));
        tileIndex++;
      }
    }

    return positions;
  }

  /// 頂点を生成
  List<Vertex> _generateVertices(List<HexTile> hexTiles) {
    final vertices = <Vertex>[];
    final vertexPositions = <String, Offset>{};
    final vertexAdjacentHexes = <String, Set<String>>{};

    const hexSize = 80.0;
    const angle60 = pi / 3;

    // 各六角形の6つの頂点を計算
    for (final hex in hexTiles) {
      for (int i = 0; i < 6; i++) {
        // 頂点の座標を計算（六角形の中心から）
        final angle = angle60 * i;
        final vx = hex.position.dx + hexSize * cos(angle);
        final vy = hex.position.dy + hexSize * sin(angle);
        final position = Offset(vx, vy);

        // 座標を丸めて同じ頂点を識別
        final posKey = '${vx.toStringAsFixed(1)}_${vy.toStringAsFixed(1)}';

        vertexPositions[posKey] = position;

        // この頂点に隣接する六角形を記録
        vertexAdjacentHexes.putIfAbsent(posKey, () => <String>{});
        vertexAdjacentHexes[posKey]!.add(hex.id);
      }
    }

    // 頂点オブジェクトを生成
    int vertexId = 0;
    for (final entry in vertexPositions.entries) {
      final id = 'v_$vertexId';
      vertices.add(Vertex(
        id: id,
        position: entry.value,
        adjacentHexIds: vertexAdjacentHexes[entry.key]!.toList(),
        adjacentEdgeIds: [], // 辺生成時に設定
      ));
      vertexId++;
    }

    return vertices;
  }

  /// 辺を生成
  List<Edge> _generateEdges(List<Vertex> vertices) {
    final edges = <Edge>[];
    final edgeSet = <String>{};
    int edgeId = 0;

    // 各頂点のペアで辺を生成
    for (int i = 0; i < vertices.length; i++) {
      for (int j = i + 1; j < vertices.length; j++) {
        final v1 = vertices[i];
        final v2 = vertices[j];

        // 2つの頂点が隣接しているか（共通の六角形を持つか）
        final commonHexes = v1.adjacentHexIds
            .toSet()
            .intersection(v2.adjacentHexIds.toSet());

        if (commonHexes.isNotEmpty) {
          // 距離が近い場合のみ辺を生成（誤検出を防ぐ）
          final distance = (v1.position - v2.position).distance;
          if (distance < 85.0) {
            // 辺の重複を防ぐ
            final edgeKey = '${v1.id}_${v2.id}';
            final edgeKeyReverse = '${v2.id}_${v1.id}';

            if (!edgeSet.contains(edgeKey) && !edgeSet.contains(edgeKeyReverse)) {
              edgeSet.add(edgeKey);

              final edge = Edge(
                id: 'e_$edgeId',
                vertex1Id: v1.id,
                vertex2Id: v2.id,
              );
              edges.add(edge);

              // 頂点に辺IDを追加
              v1.adjacentEdgeIds.add(edge.id);
              v2.adjacentEdgeIds.add(edge.id);

              edgeId++;
            }
          }
        }
      }
    }

    return edges;
  }

  /// 港を生成
  /// カタンには9つの港がある:
  /// - 汎用港（3:1）: 4つ
  /// - 特定資源港（2:1）: 5つ（木材、レンガ、羊毛、小麦、鉱石）
  List<Harbor> _generateHarbors({bool randomize = true}) {
    // 港のタイプリスト
    final harborTypes = [
      HarborType.generic,
      HarborType.generic,
      HarborType.generic,
      HarborType.generic,
      HarborType.lumber,
      HarborType.brick,
      HarborType.wool,
      HarborType.grain,
      HarborType.ore,
    ];

    if (randomize) {
      harborTypes.shuffle(_random);
    }

    // ボードの海岸線に港を配置
    // 簡略化のため、固定位置に配置（実際のカタンでは海辺の頂点）
    final harborPositions = [
      // 上辺
      ['v_0_0', 'v_0_1'],
      ['v_1_1', 'v_1_2'],
      // 右上辺
      ['v_2_2', 'v_2_3'],
      // 右下辺
      ['v_3_3', 'v_3_4'],
      // 下辺
      ['v_4_4', 'v_4_5'],
      ['v_5_5', 'v_5_0'],
      // 左下辺
      ['v_6_0', 'v_6_1'],
      // 左上辺
      ['v_7_1', 'v_7_2'],
      ['v_8_2', 'v_8_0'],
    ];

    final harbors = <Harbor>[];
    for (int i = 0; i < harborTypes.length; i++) {
      final harbor = Harbor(
        id: 'harbor_$i',
        type: harborTypes[i],
        vertexIds: harborPositions[i],
      );
      harbors.add(harbor);
    }

    return harbors;
  }
}
