import 'enums.dart';
import 'development_card.dart';

/// ゲーム中のプレイヤー情報
class Player {
  final String id;
  final String name;
  final PlayerColor color;

  /// 所持資源
  Map<ResourceType, int> resources;

  /// 所持している発展カード
  List<DevelopmentCard> developmentCards;

  /// 勝利点
  int victoryPoints;

  /// 建設物カウント
  int settlementsBuilt;  // 集落の数（最大5個）
  int citiesBuilt;       // 都市の数（最大4個）
  int roadsBuilt;        // 道路の数（最大15本）

  /// 特別ポイント
  bool hasLongestRoad;   // 最長交易路
  bool hasLargestArmy;   // 最大騎士力
  int knightsPlayed;     // 使用した騎士カード数

  Player({
    required this.id,
    required this.name,
    required this.color,
    Map<ResourceType, int>? resources,
    List<DevelopmentCard>? developmentCards,
    this.victoryPoints = 0,
    this.settlementsBuilt = 0,
    this.citiesBuilt = 0,
    this.roadsBuilt = 0,
    this.hasLongestRoad = false,
    this.hasLargestArmy = false,
    this.knightsPlayed = 0,
  })  : resources = resources ?? _initialResources(),
        developmentCards = developmentCards ?? [];

  /// 初期資源（全て0）
  static Map<ResourceType, int> _initialResources() {
    return {
      ResourceType.lumber: 0,
      ResourceType.brick: 0,
      ResourceType.wool: 0,
      ResourceType.grain: 0,
      ResourceType.ore: 0,
    };
  }

  /// 資源の総数
  int get totalResources {
    return resources.values.fold(0, (sum, count) => sum + count);
  }

  /// 特定の資源を追加
  void addResource(ResourceType type, int amount) {
    resources[type] = (resources[type] ?? 0) + amount;
  }

  /// 特定の資源を減らす
  bool removeResource(ResourceType type, int amount) {
    final current = resources[type] ?? 0;
    if (current < amount) return false;
    resources[type] = current - amount;
    return true;
  }

  /// 資源を持っているか確認
  bool hasResources(Map<ResourceType, int> required) {
    for (var entry in required.entries) {
      if ((resources[entry.key] ?? 0) < entry.value) {
        return false;
      }
    }
    return true;
  }

  /// 発展カードを追加
  void addDevelopmentCard(DevelopmentCard card) {
    developmentCards.add(card);
  }

  /// 発展カードを使用
  bool playDevelopmentCard(DevelopmentCard card) {
    if (!developmentCards.contains(card) || card.played) {
      return false;
    }
    card.played = true;
    if (card.type == DevelopmentCardType.knight) {
      knightsPlayed++;
    }
    return true;
  }

  /// 勝利点を計算（建設物 + 特別ポイント + 勝利点カード）
  int calculateVictoryPoints() {
    int points = 0;

    // 集落（1点）+ 都市（2点）
    points += settlementsBuilt * 1;
    points += citiesBuilt * 2;

    // 最長交易路（2点）
    if (hasLongestRoad) points += 2;

    // 最大騎士力（2点）
    if (hasLargestArmy) points += 2;

    // 勝利点カード
    final victoryPointCards = developmentCards
        .where((card) => card.type == DevelopmentCardType.victoryPoint)
        .length;
    points += victoryPointCards;

    return points;
  }
}
