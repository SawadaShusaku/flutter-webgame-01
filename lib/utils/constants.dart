import 'package:flutter/material.dart';

// modelsパッケージからenums.dartをimport
// TODO: pubspec.yamlで依存関係を追加後、正しいimportパスに変更
import '../../../../models/lib/models/enums.dart';

/// ゲーム定数
class GameConstants {
  GameConstants._();

  // プレイヤー数
  static const int minPlayers = 2;
  static const int maxPlayers = 4;
  static const int defaultPlayers = 4;

  // 建設物の最大数
  static const int maxSettlements = 5;
  static const int maxCities = 4;
  static const int maxRoads = 15;

  // 勝利点
  static const int victoryPointsToWin = 10;

  // 資源カード枚数（各種類）
  static const int resourceCardsPerType = 19;

  // 発展カード枚数
  static const int knightCards = 14;
  static const int victoryPointCards = 5;
  static const int roadBuildingCards = 2;
  static const int yearOfPlentyCards = 2;
  static const int monopolyCards = 2;

  // ボード設定
  static const int hexTileCount = 19;
  static const double hexSize = 50.0;

  // 特別ポイント
  static const int longestRoadPoints = 2;
  static const int largestArmyPoints = 2;
  static const int minRoadLengthForBonus = 5;
  static const int minKnightsForBonus = 3;

  // 交易レート
  static const int bankTradeRate = 4; // 4:1
  static const int harborTradeRate3to1 = 3; // 3:1
  static const int harborTradeRate2to1 = 2; // 2:1

  // 資源破棄
  static const int discardThreshold = 8; // 8枚以上で半分破棄
}

/// 建設コスト
class BuildingCosts {
  BuildingCosts._();

  /// 道路のコスト
  static const Map<ResourceType, int> road = {
    ResourceType.lumber: 1,
    ResourceType.brick: 1,
  };

  /// 集落のコスト
  static const Map<ResourceType, int> settlement = {
    ResourceType.lumber: 1,
    ResourceType.brick: 1,
    ResourceType.wool: 1,
    ResourceType.grain: 1,
  };

  /// 都市のコスト（集落からアップグレード）
  static const Map<ResourceType, int> city = {
    ResourceType.grain: 2,
    ResourceType.ore: 3,
  };

  /// 発展カードのコスト
  static const Map<ResourceType, int> developmentCard = {
    ResourceType.wool: 1,
    ResourceType.grain: 1,
    ResourceType.ore: 1,
  };
}

/// カラーパレット
class GameColors {
  GameColors._();

  // プレイヤーカラー
  static const Map<PlayerColor, Color> playerColors = {
    PlayerColor.red: Color(0xFFE53935),
    PlayerColor.blue: Color(0xFF1E88E5),
    PlayerColor.green: Color(0xFF43A047),
    PlayerColor.yellow: Color(0xFFFDD835),
  };

  /// プレイヤーカラーを取得
  static Color getPlayerColor(PlayerColor color) {
    return playerColors[color] ?? Colors.grey;
  }

  // 地形カラー
  static const Map<TerrainType, Color> terrainColors = {
    TerrainType.forest: Color(0xFF2E7D32),     // 濃い緑
    TerrainType.hills: Color(0xFFD84315),      // レンガ色
    TerrainType.pasture: Color(0xFF9CCC65),    // 明るい緑
    TerrainType.fields: Color(0xFFFDD835),     // 黄色
    TerrainType.mountains: Color(0xFF616161),  // 灰色
    TerrainType.desert: Color(0xFFFFCC80),     // 砂色
  };

  // 資源カラー
  static const Map<ResourceType, Color> resourceColors = {
    ResourceType.lumber: Color(0xFF2E7D32),
    ResourceType.brick: Color(0xFFD84315),
    ResourceType.wool: Color(0xFF9CCC65),
    ResourceType.grain: Color(0xFFFDD835),
    ResourceType.ore: Color(0xFF616161),
  };

  /// 資源カラーを取得
  static Color getResourceColor(ResourceType resource) {
    return resourceColors[resource] ?? Colors.grey;
  }

  // 数字チップの出現確率に応じた色
  static Color getNumberColor(int number) {
    if (number == 6 || number == 8) {
      return Colors.red; // 最頻出
    } else if (number == 5 || number == 9) {
      return Colors.orange;
    } else if (number == 4 || number == 10) {
      return Colors.yellow[700]!;
    } else {
      return Colors.grey[600]!;
    }
  }
}

/// 資源アイコン（絵文字）
class ResourceIcons {
  ResourceIcons._();

  static const Map<ResourceType, String> icons = {
    ResourceType.lumber: '🌲',
    ResourceType.brick: '🧱',
    ResourceType.wool: '🐑',
    ResourceType.grain: '🌾',
    ResourceType.ore: '⛰️',
  };

  /// 資源アイコンを取得
  static String getIcon(ResourceType resource) {
    return icons[resource] ?? '❓';
  }

  static const Map<TerrainType, String> terrainIcons = {
    TerrainType.forest: '🌲',
    TerrainType.hills: '🧱',
    TerrainType.pasture: '🐑',
    TerrainType.fields: '🌾',
    TerrainType.mountains: '⛰️',
    TerrainType.desert: '🏜️',
  };
}

/// サイコロの出現確率
class DiceProbabilities {
  DiceProbabilities._();

  static const Map<int, int> dots = {
    2: 1,
    3: 2,
    4: 3,
    5: 4,
    6: 5,
    8: 5,
    9: 4,
    10: 3,
    11: 2,
    12: 1,
  };

  /// サイコロの目から確率ドット数を取得
  static int getDots(int number) {
    return dots[number] ?? 0;
  }
}
