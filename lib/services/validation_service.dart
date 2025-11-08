import '../models/game_state.dart';
import '../models/player.dart';
import '../models/vertex.dart';
import '../models/edge.dart';
import '../models/enums.dart';
import '../utils/constants.dart';

/// ゲームルール検証サービス
class ValidationService {
  /// 集落を配置可能か検証
  bool canPlaceSettlement(
    GameState state,
    Player player,
    String vertexId, {
    bool isSetupPhase = false,
  }) {
    final vertex = state.vertices.firstWhere((v) => v.id == vertexId);

    // 既に建設物がある場合は不可
    if (vertex.hasBuilding) {
      return false;
    }

    // 距離ルール: 隣接する頂点に建設物がある場合は不可
    if (!_checkDistanceRule(state, vertexId)) {
      return false;
    }

    // 初期配置フェーズ以外は、自分の道路に接続している必要がある
    if (!isSetupPhase && !_isConnectedToPlayerRoad(state, player, vertexId)) {
      return false;
    }

    // 資源チェック（初期配置フェーズ以外）
    if (!isSetupPhase && !player.hasResources(BuildingCosts.settlement)) {
      return false;
    }

    // 建設数制限
    if (player.settlementsBuilt >= GameConstants.maxSettlements) {
      return false;
    }

    return true;
  }

  /// 都市にアップグレード可能か検証
  bool canUpgradeToCity(
    GameState state,
    Player player,
    String vertexId,
  ) {
    final vertex = state.vertices.firstWhere((v) => v.id == vertexId);

    // 自分の集落がある必要がある
    if (vertex.building == null ||
        vertex.building!.playerId != player.id ||
        vertex.building!.type != BuildingType.settlement) {
      return false;
    }

    // 資源チェック
    if (!player.hasResources(BuildingCosts.city)) {
      return false;
    }

    // 建設数制限
    if (player.citiesBuilt >= GameConstants.maxCities) {
      return false;
    }

    return true;
  }

  /// 道路を配置可能か検証
  bool canPlaceRoad(
    GameState state,
    Player player,
    String edgeId, {
    bool isSetupPhase = false,
  }) {
    final edge = state.edges.firstWhere((e) => e.id == edgeId);

    // 既に道路がある場合は不可
    if (edge.hasRoad) {
      return false;
    }

    // 初期配置フェーズ: 直前に配置した集落に隣接している必要がある
    if (isSetupPhase) {
      // TODO: 直前に配置した集落のチェック
      return true;
    }

    // 通常プレイ: 自分の建設物または道路に接続している必要がある
    if (!_isConnectedToPlayerBuildingOrRoad(state, player, edgeId)) {
      return false;
    }

    // 資源チェック
    if (!player.hasResources(BuildingCosts.road)) {
      return false;
    }

    // 建設数制限
    if (player.roadsBuilt >= GameConstants.maxRoads) {
      return false;
    }

    return true;
  }

  /// 発展カードを購入可能か検証
  bool canBuyDevelopmentCard(GameState state, Player player) {
    // デッキが空の場合は不可
    if (state.developmentCardDeck.isEmpty) {
      return false;
    }

    // 資源チェック
    if (!player.hasResources(BuildingCosts.developmentCard)) {
      return false;
    }

    return true;
  }

  /// 距離ルール: 隣接する頂点に建設物がないか確認
  bool _checkDistanceRule(GameState state, String vertexId) {
    final vertex = state.vertices.firstWhere((v) => v.id == vertexId);

    // この頂点に隣接する全ての辺を取得
    final adjacentEdges = state.edges
        .where((e) => vertex.adjacentEdgeIds.contains(e.id))
        .toList();

    // 各辺の反対側の頂点を確認
    for (var edge in adjacentEdges) {
      final otherVertexId =
          edge.vertex1Id == vertexId ? edge.vertex2Id : edge.vertex1Id;
      final otherVertex =
          state.vertices.firstWhere((v) => v.id == otherVertexId);

      // 隣接する頂点に建設物がある場合は距離ルール違反
      if (otherVertex.hasBuilding) {
        return false;
      }
    }

    return true;
  }

  /// プレイヤーの道路に接続しているか確認
  bool _isConnectedToPlayerRoad(
    GameState state,
    Player player,
    String vertexId,
  ) {
    final vertex = state.vertices.firstWhere((v) => v.id == vertexId);

    // この頂点に接続する辺を確認
    for (var edgeId in vertex.adjacentEdgeIds) {
      final edge = state.edges.firstWhere((e) => e.id == edgeId);
      if (edge.hasRoadOfPlayer(player.id)) {
        return true;
      }
    }

    return false;
  }

  /// プレイヤーの建設物または道路に接続しているか確認
  bool _isConnectedToPlayerBuildingOrRoad(
    GameState state,
    Player player,
    String edgeId,
  ) {
    final edge = state.edges.firstWhere((e) => e.id == edgeId);

    // 両端の頂点を確認
    final vertex1 = state.vertices.firstWhere((v) => v.id == edge.vertex1Id);
    final vertex2 = state.vertices.firstWhere((v) => v.id == edge.vertex2Id);

    // 頂点に自分の建設物があるか
    if (vertex1.hasBuildingOfPlayer(player.id) ||
        vertex2.hasBuildingOfPlayer(player.id)) {
      return true;
    }

    // 頂点に接続する他の辺に自分の道路があるか
    for (var adjacentEdgeId in vertex1.adjacentEdgeIds) {
      if (adjacentEdgeId == edgeId) continue;
      final adjacentEdge = state.edges.firstWhere((e) => e.id == adjacentEdgeId);
      if (adjacentEdge.hasRoadOfPlayer(player.id)) {
        return true;
      }
    }

    for (var adjacentEdgeId in vertex2.adjacentEdgeIds) {
      if (adjacentEdgeId == edgeId) continue;
      final adjacentEdge = state.edges.firstWhere((e) => e.id == adjacentEdgeId);
      if (adjacentEdge.hasRoadOfPlayer(player.id)) {
        return true;
      }
    }

    return false;
  }

  /// 交易可能か検証（銀行交易）
  bool canBankTrade(Player player, ResourceType giving) {
    // 指定した資源を4枚以上持っているか
    return (player.resources[giving] ?? 0) >= GameConstants.bankTradeRate;
  }

  /// プレイヤー間交渉が可能か検証
  bool canProposeTrade(
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
    final requestingTotal = requesting.values.fold(0, (sum, count) => sum + count);

    if (offeringTotal == 0 || requestingTotal == 0) {
      return false;
    }

    return true;
  }

  /// ターン終了可能か検証
  bool canEndTurn(GameState state) {
    // 通常プレイフェーズのみ
    if (state.phase != GamePhase.normalPlay) {
      return false;
    }

    // サイコロを振っている必要がある
    if (state.lastDiceRoll == null) {
      return false;
    }

    return true;
  }
}
