// modelsからimport
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/vertex.dart';
import '../models/edge.dart';
import '../models/enums.dart';

// servicesからimport
import 'building_costs.dart';
import 'resource_manager.dart';

/// 建設ルールの検証結果
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult.success()
      : isValid = true,
        errorMessage = null;

  const ValidationResult.failure(this.errorMessage) : isValid = false;

  @override
  String toString() {
    return isValid ? 'Valid' : 'Invalid: $errorMessage';
  }
}

/// ゲームルールの検証サービス
///
/// 建設物の配置ルール、資源の所持チェックなど、
/// カタンのルールに基づいた検証を行います。
class ValidationService {
  final ResourceManager _resourceManager;

  ValidationService({ResourceManager? resourceManager})
      : _resourceManager = resourceManager ?? ResourceManager();

  // ========== 集落の検証 ==========

  /// 集落を建設できるか検証
  ///
  /// [gameState] ゲーム状態
  /// [vertexId] 頂点ID
  /// [playerId] プレイヤーID
  /// [skipResourceCheck] 資源チェックをスキップ（初期配置用）
  ///
  /// 戻り値: 検証結果
  ValidationResult validateSettlementPlacement(
    GameState gameState,
    String vertexId,
    String playerId, {
    bool skipResourceCheck = false,
  }) {
    final player = gameState.players.firstWhere((p) => p.id == playerId);
    final vertex = gameState.vertices.firstWhere((v) => v.id == vertexId);

    // 1. 既に建設物があるか
    if (vertex.hasBuilding) {
      return const ValidationResult.failure('この場所には既に建設物があります');
    }

    // 2. 距離ルールをチェック
    if (!_checkDistanceRule(gameState, vertexId)) {
      return const ValidationResult.failure(
          '隣接する頂点に建設物があります（距離ルール違反）');
    }

    // 3. 集落の上限をチェック
    if (!BuildingLimits.canBuild(
        player.settlementsBuilt, BuildingLimits.maxSettlements)) {
      return const ValidationResult.failure(
          '集落の上限(${BuildingLimits.maxSettlements}個)に達しています');
    }

    // 4. 通常プレイ時は道路接続をチェック
    if (gameState.phase != GamePhase.setup) {
      if (!_isConnectedByRoad(gameState, vertexId, playerId)) {
        return const ValidationResult.failure(
            'この場所には道路が接続されていません');
      }
    }

    // 5. 資源チェック
    if (!skipResourceCheck) {
      if (!_resourceManager.hasEnoughResources(
          player, BuildingCosts.settlement)) {
        final missing =
            _resourceManager.getMissingResources(player, BuildingCosts.settlement);
        return ValidationResult.failure(
            '資源が不足しています: ${_formatMissingResources(missing)}');
      }
    }

    return const ValidationResult.success();
  }

  // ========== 都市の検証 ==========

  /// 都市へのアップグレードを検証
  ///
  /// [gameState] ゲーム状態
  /// [vertexId] 頂点ID
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: 検証結果
  ValidationResult validateCityUpgrade(
    GameState gameState,
    String vertexId,
    String playerId,
  ) {
    final player = gameState.players.firstWhere((p) => p.id == playerId);
    final vertex = gameState.vertices.firstWhere((v) => v.id == vertexId);

    // 1. 自分の集落があるか
    if (!vertex.hasBuildingOfPlayer(playerId)) {
      return const ValidationResult.failure('ここにはあなたの建設物がありません');
    }

    if (vertex.building!.type != BuildingType.settlement) {
      return const ValidationResult.failure('都市にアップグレードできるのは集落のみです');
    }

    // 2. 都市の上限をチェック
    if (!BuildingLimits.canBuild(player.citiesBuilt, BuildingLimits.maxCities)) {
      return const ValidationResult.failure(
          '都市の上限(${BuildingLimits.maxCities}個)に達しています');
    }

    // 3. 資源チェック
    if (!_resourceManager.hasEnoughResources(player, BuildingCosts.city)) {
      final missing =
          _resourceManager.getMissingResources(player, BuildingCosts.city);
      return ValidationResult.failure(
          '資源が不足しています: ${_formatMissingResources(missing)}');
    }

    return const ValidationResult.success();
  }

  // ========== 道路の検証 ==========

  /// 道路を建設できるか検証
  ///
  /// [gameState] ゲーム状態
  /// [edgeId] 辺ID
  /// [playerId] プレイヤーID
  /// [skipResourceCheck] 資源チェックをスキップ（初期配置用）
  ///
  /// 戻り値: 検証結果
  ValidationResult validateRoadPlacement(
    GameState gameState,
    String edgeId,
    String playerId, {
    bool skipResourceCheck = false,
  }) {
    final player = gameState.players.firstWhere((p) => p.id == playerId);
    final edge = gameState.edges.firstWhere((e) => e.id == edgeId);

    // 1. 既に道路があるか
    if (edge.hasRoad) {
      return const ValidationResult.failure('この場所には既に道路があります');
    }

    // 2. 道路の上限をチェック
    if (!BuildingLimits.canBuild(player.roadsBuilt, BuildingLimits.maxRoads)) {
      return const ValidationResult.failure(
          '道路の上限(${BuildingLimits.maxRoads}本)に達しています');
    }

    // 3. 通常プレイ時は接続をチェック
    if (gameState.phase != GamePhase.setup) {
      if (!_isRoadConnected(gameState, edgeId, playerId)) {
        return const ValidationResult.failure(
            'この道路は既存の道路または建設物に接続されていません');
      }
    }

    // 4. 資源チェック
    if (!skipResourceCheck) {
      if (!_resourceManager.hasEnoughResources(player, BuildingCosts.road)) {
        final missing =
            _resourceManager.getMissingResources(player, BuildingCosts.road);
        return ValidationResult.failure(
            '資源が不足しています: ${_formatMissingResources(missing)}');
      }
    }

    return const ValidationResult.success();
  }

  // ========== 発展カードの検証 ==========

  /// 発展カードを購入できるか検証
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: 検証結果
  ValidationResult validateDevelopmentCardPurchase(
    GameState gameState,
    String playerId,
  ) {
    final player = gameState.players.firstWhere((p) => p.id == playerId);

    // 1. デッキに残りがあるか
    if (gameState.developmentCardDeck.isEmpty) {
      return const ValidationResult.failure('発展カードの山札が空です');
    }

    // 2. 資源チェック
    if (!_resourceManager.hasEnoughResources(
        player, BuildingCosts.developmentCard)) {
      final missing = _resourceManager.getMissingResources(
          player, BuildingCosts.developmentCard);
      return ValidationResult.failure(
          '資源が不足しています: ${_formatMissingResources(missing)}');
    }

    return const ValidationResult.success();
  }

  // ========== プライベートヘルパーメソッド ==========

  /// 距離ルールをチェック
  /// 隣接する頂点に建設物がないか確認
  bool _checkDistanceRule(GameState gameState, String vertexId) {
    final vertex = gameState.vertices.firstWhere((v) => v.id == vertexId);

    // 隣接する辺を取得
    for (final edgeId in vertex.adjacentEdgeIds) {
      final edge = gameState.edges.firstWhere((e) => e.id == edgeId);

      // この辺の両端の頂点を取得
      final otherVertexId =
          edge.vertex1Id == vertexId ? edge.vertex2Id : edge.vertex1Id;
      final otherVertex =
          gameState.vertices.firstWhere((v) => v.id == otherVertexId);

      // 隣接する頂点に建設物がある場合はNG
      if (otherVertex.hasBuilding) {
        return false;
      }
    }

    return true;
  }

  /// 道路が接続しているかチェック
  bool _isConnectedByRoad(GameState gameState, String vertexId, String playerId) {
    final vertex = gameState.vertices.firstWhere((v) => v.id == vertexId);

    // 隣接する辺のいずれかにプレイヤーの道路があるか確認
    for (final edgeId in vertex.adjacentEdgeIds) {
      final edge = gameState.edges.firstWhere((e) => e.id == edgeId);
      if (edge.hasRoadOfPlayer(playerId)) {
        return true;
      }
    }

    return false;
  }

  /// 道路が既存の道路または建設物に接続されているかチェック
  bool _isRoadConnected(GameState gameState, String edgeId, String playerId) {
    final edge = gameState.edges.firstWhere((e) => e.id == edgeId);

    // 両端の頂点をチェック
    for (final vertexId in [edge.vertex1Id, edge.vertex2Id]) {
      final vertex = gameState.vertices.firstWhere((v) => v.id == vertexId);

      // この頂点に自分の建設物があれば接続されている
      if (vertex.hasBuildingOfPlayer(playerId)) {
        return true;
      }

      // この頂点に接続する他の辺に自分の道路があれば接続されている
      for (final adjacentEdgeId in vertex.adjacentEdgeIds) {
        if (adjacentEdgeId == edgeId) continue; // 自分自身はスキップ

        final adjacentEdge =
            gameState.edges.firstWhere((e) => e.id == adjacentEdgeId);
        if (adjacentEdge.hasRoadOfPlayer(playerId)) {
          return true;
        }
      }
    }

    return false;
  }

  /// 不足している資源を文字列化
  String _formatMissingResources(Map<ResourceType, int> missing) {
    if (missing.isEmpty) {
      return 'なし';
    }

    final parts = <String>[];
    for (final entry in missing.entries) {
      final resourceName = _getResourceName(entry.key);
      parts.add('$resourceName x${entry.value}');
    }
    return parts.join(', ');
  }

  /// 資源タイプの日本語名を取得
  String _getResourceName(ResourceType type) {
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
