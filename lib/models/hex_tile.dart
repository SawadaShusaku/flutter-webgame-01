import 'package:flutter/material.dart';
import 'enums.dart';

/// 六角形タイル
class HexTile {
  final String id;
  final TerrainType terrain;
  final int? number;  // 数字チップ (2-12, 砂漠はnull)
  final Offset position;
  bool hasRobber;

  HexTile({
    required this.id,
    required this.terrain,
    this.number,
    required this.position,
    this.hasRobber = false,
  }) : assert(terrain == TerrainType.desert || number != null,
             '砂漠以外のタイルには数字が必要です'),
       assert(number == null || (number >= 2 && number <= 12),
             '数字は2-12の範囲である必要があります');

  /// この地形が生産する資源タイプ
  ResourceType? get resourceType {
    switch (terrain) {
      case TerrainType.forest:
        return ResourceType.lumber;
      case TerrainType.hills:
        return ResourceType.brick;
      case TerrainType.pasture:
        return ResourceType.wool;
      case TerrainType.fields:
        return ResourceType.grain;
      case TerrainType.mountains:
        return ResourceType.ore;
      case TerrainType.desert:
        return null;
    }
  }
}
