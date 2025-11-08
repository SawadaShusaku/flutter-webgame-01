import 'package:flutter/material.dart';
import 'building.dart';

/// 頂点（集落/都市を配置）
class Vertex {
  final String id;
  final Offset position;
  final List<String> adjacentHexIds;  // 隣接するタイルID
  final List<String> adjacentEdgeIds; // 隣接する辺ID
  Building? building;

  Vertex({
    required this.id,
    required this.position,
    required this.adjacentHexIds,
    required this.adjacentEdgeIds,
    this.building,
  });

  /// 建設物があるか
  bool get hasBuilding => building != null;

  /// 特定のプレイヤーの建設物があるか
  bool hasBuildingOfPlayer(String playerId) {
    return building != null && building!.playerId == playerId;
  }
}
