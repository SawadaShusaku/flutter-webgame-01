// modelsからimport
import '../../../models/lib/models/enums.dart';

/// 建設物のコスト定義
///
/// カタンゲームにおける各建設物・アクションに必要な資源を定義します。
class BuildingCosts {
  BuildingCosts._(); // プライベートコンストラクタ（インスタンス化不可）

  /// 道路の建設コスト
  /// - 木材 x1
  /// - レンガ x1
  static const Map<ResourceType, int> road = {
    ResourceType.lumber: 1,
    ResourceType.brick: 1,
  };

  /// 集落の建設コスト
  /// - 木材 x1
  /// - レンガ x1
  /// - 羊毛 x1
  /// - 小麦 x1
  static const Map<ResourceType, int> settlement = {
    ResourceType.lumber: 1,
    ResourceType.brick: 1,
    ResourceType.wool: 1,
    ResourceType.grain: 1,
  };

  /// 都市へのアップグレードコスト
  /// - 小麦 x2
  /// - 鉱石 x3
  static const Map<ResourceType, int> city = {
    ResourceType.grain: 2,
    ResourceType.ore: 3,
  };

  /// 発展カードの購入コスト
  /// - 羊毛 x1
  /// - 小麦 x1
  /// - 鉱石 x1
  static const Map<ResourceType, int> developmentCard = {
    ResourceType.wool: 1,
    ResourceType.grain: 1,
    ResourceType.ore: 1,
  };

  /// 建設物タイプに応じたコストを取得
  ///
  /// [type] 建設物のタイプ ("road", "settlement", "city", "development_card")
  ///
  /// 戻り値: 必要な資源のマップ
  static Map<ResourceType, int> getCost(String type) {
    switch (type) {
      case 'road':
        return road;
      case 'settlement':
        return settlement;
      case 'city':
        return city;
      case 'development_card':
        return developmentCard;
      default:
        throw ArgumentError('Unknown building type: $type');
    }
  }

  /// コストの合計資源数を取得
  ///
  /// [cost] 資源コストのマップ
  ///
  /// 戻り値: 合計資源数
  static int getTotalCount(Map<ResourceType, int> cost) {
    return cost.values.fold(0, (sum, count) => sum + count);
  }

  /// コストを文字列で表現
  ///
  /// [cost] 資源コストのマップ
  ///
  /// 戻り値: "木材x1 レンガx1" のような文字列
  static String costToString(Map<ResourceType, int> cost) {
    final parts = <String>[];
    for (final entry in cost.entries) {
      final resourceName = _getResourceName(entry.key);
      parts.add('${resourceName}x${entry.value}');
    }
    return parts.join(' ');
  }

  /// 資源タイプの日本語名を取得
  static String _getResourceName(ResourceType type) {
    switch (type) {
      case ResourceType.lumber:
        return '木材';
      case ResourceType.brick:
        return 'レンガ';
      case ResourceType.wool:
        return '羊毛';
      case ResourceType.grain:
        return '小麦';
      case ResourceType.ore:
        return '鉱石';
    }
  }
}

/// 建設物の最大数制限
class BuildingLimits {
  BuildingLimits._(); // プライベートコンストラクタ

  /// 集落の最大数
  static const int maxSettlements = 5;

  /// 都市の最大数
  static const int maxCities = 4;

  /// 道路の最大数
  static const int maxRoads = 15;

  /// 建設可能な残り数を計算
  ///
  /// [built] 既に建設した数
  /// [max] 最大数
  ///
  /// 戻り値: 残り建設可能数
  static int getRemainingCount(int built, int max) {
    return (max - built).clamp(0, max);
  }

  /// 建設可能かチェック
  ///
  /// [built] 既に建設した数
  /// [max] 最大数
  ///
  /// 戻り値: 建設可能ならtrue
  static bool canBuild(int built, int max) {
    return built < max;
  }
}
