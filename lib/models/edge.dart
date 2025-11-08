import 'road.dart';

/// 辺（道路を配置）
class Edge {
  final String id;
  final String vertex1Id;
  final String vertex2Id;
  Road? road;

  Edge({
    required this.id,
    required this.vertex1Id,
    required this.vertex2Id,
    this.road,
  });

  /// 道路があるか
  bool get hasRoad => road != null;

  /// 特定のプレイヤーの道路があるか
  bool hasRoadOfPlayer(String playerId) {
    return road != null && road!.playerId == playerId;
  }

  /// この辺が特定の頂点に接続しているか
  bool isConnectedToVertex(String vertexId) {
    return vertex1Id == vertexId || vertex2Id == vertexId;
  }
}
