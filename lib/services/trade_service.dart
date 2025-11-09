import '../models/game_state.dart';
import '../models/player.dart';
import '../models/trade.dart';
import '../models/enums.dart';
import '../utils/constants.dart';

/// 交易システムを管理するサービス
class TradeService {
  /// 銀行交易を実行（4:1）
  bool executeBankTrade(
    Player player,
    ResourceType giving,
    ResourceType receiving,
  ) {
    // 4枚以上持っているか確認
    if ((player.resources[giving] ?? 0) < GameConstants.bankTradeRate) {
      return false;
    }

    // 資源を交換
    player.removeResource(giving, GameConstants.bankTradeRate);
    player.addResource(receiving, 1);

    return true;
  }

  /// 港交易を実行（3:1 または 2:1）
  bool executeHarborTrade(
    Player player,
    Harbor harbor,
    ResourceType giving,
    ResourceType receiving, {
    required bool hasAccessToHarbor,
  }) {
    // 港へのアクセス権があるか
    if (!hasAccessToHarbor) {
      return false;
    }

    // 特定資源の港の場合、その資源でなければならない
    if (harbor.isSpecific && harbor.resourceType != giving) {
      return false;
    }

    final rate = harbor.tradeRate;

    // 必要枚数を持っているか確認
    if ((player.resources[giving] ?? 0) < rate) {
      return false;
    }

    // 資源を交換
    player.removeResource(giving, rate);
    player.addResource(receiving, 1);

    return true;
  }

  /// プレイヤー間交易の提案を作成
  TradeOffer createTradeOffer(
    String proposerId,
    Map<ResourceType, int> offering,
    Map<ResourceType, int> requesting,
  ) {
    return TradeOffer(
      id: 'trade_${DateTime.now().millisecondsSinceEpoch}',
      proposerId: proposerId,
      offering: offering,
      requesting: requesting,
      createdAt: DateTime.now(),
    );
  }

  /// プレイヤー間交易を実行
  bool executePlayerTrade(
    TradeOffer offer,
    Player proposer,
    Player acceptor,
  ) {
    // 提案者が提供する資源を持っているか
    for (var entry in offer.offering.entries) {
      if ((proposer.resources[entry.key] ?? 0) < entry.value) {
        return false;
      }
    }

    // 受諾者が要求される資源を持っているか
    for (var entry in offer.requesting.entries) {
      if ((acceptor.resources[entry.key] ?? 0) < entry.value) {
        return false;
      }
    }

    // 交易を実行
    // 提案者: 提供する資源を減らし、要求する資源を増やす
    for (var entry in offer.offering.entries) {
      proposer.removeResource(entry.key, entry.value);
    }
    for (var entry in offer.requesting.entries) {
      proposer.addResource(entry.key, entry.value);
    }

    // 受諾者: 要求される資源を減らし、受け取る資源を増やす
    for (var entry in offer.requesting.entries) {
      acceptor.removeResource(entry.key, entry.value);
    }
    for (var entry in offer.offering.entries) {
      acceptor.addResource(entry.key, entry.value);
    }

    return true;
  }

  /// プレイヤーが港にアクセスできるか確認
  bool hasAccessToHarbor(
    GameState state,
    Player player,
    Harbor harbor,
  ) {
    // プレイヤーが港の頂点に建設物を持っているか確認
    for (var vertexId in harbor.vertexIds) {
      final vertex = state.vertices.firstWhere((v) => v.id == vertexId);
      if (vertex.hasBuildingOfPlayer(player.id)) {
        return true;
      }
    }
    return false;
  }

  /// プレイヤーが使用可能な港のリストを取得
  List<Harbor> getAvailableHarbors(
    GameState state,
    Player player,
  ) {
    final harbors = <Harbor>[];
    for (var harbor in state.harbors) {
      if (hasAccessToHarbor(state, player, harbor)) {
        harbors.add(harbor);
      }
    }
    return harbors;
  }

  /// 最適な交易レートを計算
  /// 銀行交易、汎用港、特定資源港の中から最良のレートを返す
  int getBestTradeRate(
    GameState state,
    Player player,
    ResourceType resourceType,
  ) {
    var bestRate = GameConstants.bankTradeRate; // デフォルトは4:1

    final availableHarbors = getAvailableHarbors(state, player);

    for (var harbor in availableHarbors) {
      if (harbor.type == HarborType.generic) {
        // 汎用港（3:1）
        bestRate = bestRate > 3 ? 3 : bestRate;
      } else if (harbor.resourceType == resourceType) {
        // 特定資源港（2:1）
        bestRate = 2;
        break; // 2:1が最良なので終了
      }
    }

    return bestRate;
  }

  /// 交易可能かチェック
  bool canTrade(
    Player player,
    ResourceType giving,
    int amount,
  ) {
    return (player.resources[giving] ?? 0) >= amount;
  }

  /// 交易提案が有効かチェック
  bool isValidTradeOffer(
    Player proposer,
    Map<ResourceType, int> offering,
    Map<ResourceType, int> requesting,
  ) {
    // 提供する資源を全て持っているか
    for (var entry in offering.entries) {
      if ((proposer.resources[entry.key] ?? 0) < entry.value) {
        return false;
      }
    }

    // 最低1枚以上の資源を提供・要求している
    final offeringTotal = offering.values.fold(0, (sum, count) => sum + count);
    final requestingTotal =
        requesting.values.fold(0, (sum, count) => sum + count);

    if (offeringTotal == 0 || requestingTotal == 0) {
      return false;
    }

    return true;
  }
}
