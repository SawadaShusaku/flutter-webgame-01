// modelsからimport
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/vertex.dart';
import '../models/edge.dart';
import '../models/building.dart';
import '../models/road.dart';
import '../models/development_card.dart';
import '../models/enums.dart';

// servicesからimport
import 'building_costs.dart';
import 'resource_manager.dart';
import 'validation_service.dart';

/// 建設結果
class ConstructionResult {
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic>? data;

  const ConstructionResult.success([this.data])
      : success = true,
        errorMessage = null;

  const ConstructionResult.failure(this.errorMessage)
      : success = false,
        data = null;

  @override
  String toString() {
    return success ? 'Success' : 'Failed: $errorMessage';
  }
}

/// 通常フェーズでの建設サービス
///
/// Phase 3: 通常プレイフェーズでの建設機能を実装
/// - 集落建設
/// - 都市アップグレード
/// - 道路建設
/// - 発展カード購入
class ConstructionService {
  final ResourceManager _resourceManager;
  final ValidationService _validationService;

  ConstructionService({
    ResourceManager? resourceManager,
    ValidationService? validationService,
  })  : _resourceManager = resourceManager ?? ResourceManager(),
        _validationService = validationService ?? ValidationService();

  // ========== 集落の建設 ==========

  /// 通常フェーズで集落を建設
  ///
  /// [gameState] ゲーム状態
  /// [vertexId] 頂点ID
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: 建設結果
  ConstructionResult buildSettlementNormalPhase(
    GameState gameState,
    String vertexId,
    String playerId,
  ) {
    // 1. 検証
    final validation = _validationService.validateSettlementPlacement(
      gameState,
      vertexId,
      playerId,
    );

    if (!validation.isValid) {
      return ConstructionResult.failure(validation.errorMessage);
    }

    // 2. プレイヤーと頂点を取得
    final player = gameState.players.firstWhere((p) => p.id == playerId);
    final vertex = gameState.vertices.firstWhere((v) => v.id == vertexId);

    // 3. 資源を消費
    if (!_resourceManager.consumeResources(player, BuildingCosts.settlement)) {
      return const ConstructionResult.failure('資源の消費に失敗しました');
    }

    // 4. 集落を配置
    vertex.building = Building(
      playerId: playerId,
      type: BuildingType.settlement,
    );
    player.settlementsBuilt++;

    // 5. 勝利点を更新
    player.victoryPoints = player.calculateVictoryPoints();

    // 6. イベントログに追加
    gameState.logEvent(GameEvent(
      timestamp: DateTime.now(),
      playerId: playerId,
      type: GameEventType.buildingPlaced,
      data: {
        'vertexId': vertexId,
        'type': 'settlement',
        'phase': 'normal',
      },
    ));

    return ConstructionResult.success({
      'vertexId': vertexId,
      'settlementsBuilt': player.settlementsBuilt,
      'victoryPoints': player.victoryPoints,
    });
  }

  // ========== 都市へのアップグレード ==========

  /// 集落を都市にアップグレード
  ///
  /// [gameState] ゲーム状態
  /// [vertexId] 頂点ID
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: 建設結果
  ConstructionResult upgradeToCity(
    GameState gameState,
    String vertexId,
    String playerId,
  ) {
    // 1. 検証
    final validation = _validationService.validateCityUpgrade(
      gameState,
      vertexId,
      playerId,
    );

    if (!validation.isValid) {
      return ConstructionResult.failure(validation.errorMessage);
    }

    // 2. プレイヤーと頂点を取得
    final player = gameState.players.firstWhere((p) => p.id == playerId);
    final vertex = gameState.vertices.firstWhere((v) => v.id == vertexId);

    // 3. 資源を消費
    if (!_resourceManager.consumeResources(player, BuildingCosts.city)) {
      return const ConstructionResult.failure('資源の消費に失敗しました');
    }

    // 4. 都市にアップグレード
    vertex.building = Building(
      playerId: playerId,
      type: BuildingType.city,
    );

    // 5. 集落数を減らし、都市数を増やす
    player.settlementsBuilt--;
    player.citiesBuilt++;

    // 6. 勝利点を更新
    player.victoryPoints = player.calculateVictoryPoints();

    // 7. イベントログに追加
    gameState.logEvent(GameEvent(
      timestamp: DateTime.now(),
      playerId: playerId,
      type: GameEventType.buildingPlaced,
      data: {
        'vertexId': vertexId,
        'type': 'city',
        'phase': 'normal',
        'upgraded': true,
      },
    ));

    return ConstructionResult.success({
      'vertexId': vertexId,
      'settlementsBuilt': player.settlementsBuilt,
      'citiesBuilt': player.citiesBuilt,
      'victoryPoints': player.victoryPoints,
    });
  }

  // ========== 道路の建設 ==========

  /// 通常フェーズで道路を建設
  ///
  /// [gameState] ゲーム状態
  /// [edgeId] 辺ID
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: 建設結果
  ConstructionResult buildRoadNormalPhase(
    GameState gameState,
    String edgeId,
    String playerId,
  ) {
    // 1. 検証
    final validation = _validationService.validateRoadPlacement(
      gameState,
      edgeId,
      playerId,
    );

    if (!validation.isValid) {
      return ConstructionResult.failure(validation.errorMessage);
    }

    // 2. プレイヤーと辺を取得
    final player = gameState.players.firstWhere((p) => p.id == playerId);
    final edge = gameState.edges.firstWhere((e) => e.id == edgeId);

    // 3. 資源を消費
    if (!_resourceManager.consumeResources(player, BuildingCosts.road)) {
      return const ConstructionResult.failure('資源の消費に失敗しました');
    }

    // 4. 道路を配置
    edge.road = Road(playerId: playerId);
    player.roadsBuilt++;

    // 5. イベントログに追加
    gameState.logEvent(GameEvent(
      timestamp: DateTime.now(),
      playerId: playerId,
      type: GameEventType.roadPlaced,
      data: {
        'edgeId': edgeId,
        'phase': 'normal',
      },
    ));

    return ConstructionResult.success({
      'edgeId': edgeId,
      'roadsBuilt': player.roadsBuilt,
    });
  }

  // ========== 発展カードの購入 ==========

  /// 発展カードを購入
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: 建設結果（購入したカード情報を含む）
  ConstructionResult buyDevelopmentCard(
    GameState gameState,
    String playerId,
  ) {
    // 1. 検証
    final validation = _validationService.validateDevelopmentCardPurchase(
      gameState,
      playerId,
    );

    if (!validation.isValid) {
      return ConstructionResult.failure(validation.errorMessage);
    }

    // 2. プレイヤーを取得
    final player = gameState.players.firstWhere((p) => p.id == playerId);

    // 3. 資源を消費
    if (!_resourceManager.consumeResources(
        player, BuildingCosts.developmentCard)) {
      return const ConstructionResult.failure('資源の消費に失敗しました');
    }

    // 4. カードを引く
    final card = gameState.drawDevelopmentCard();
    if (card == null) {
      // 失敗した場合、資源を返却
      _resourceManager.addResources(player, BuildingCosts.developmentCard);
      return const ConstructionResult.failure('カードの山札が空です');
    }

    // 5. プレイヤーに追加
    player.addDevelopmentCard(card);

    // 6. 勝利点カードの場合、勝利点を更新
    if (card.type == DevelopmentCardType.victoryPoint) {
      player.victoryPoints = player.calculateVictoryPoints();
    }

    // 7. イベントログに追加
    gameState.logEvent(GameEvent(
      timestamp: DateTime.now(),
      playerId: playerId,
      type: GameEventType.cardPurchased,
      data: {
        'cardType': card.type.name,
      },
    ));

    return ConstructionResult.success({
      'cardType': card.type,
      'developmentCards': player.developmentCards.length,
      'victoryPoints': player.victoryPoints,
    });
  }

  // ========== 建設可能性のチェック ==========

  /// 集落を建設できるか簡易チェック
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: 建設可能な頂点IDのリスト
  List<String> getAvailableSettlementLocations(
    GameState gameState,
    String playerId,
  ) {
    final availableVertices = <String>[];

    for (final vertex in gameState.vertices) {
      final validation = _validationService.validateSettlementPlacement(
        gameState,
        vertex.id,
        playerId,
      );

      if (validation.isValid) {
        availableVertices.add(vertex.id);
      }
    }

    return availableVertices;
  }

  /// 道路を建設できるか簡易チェック
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: 建設可能な辺IDのリスト
  List<String> getAvailableRoadLocations(
    GameState gameState,
    String playerId,
  ) {
    final availableEdges = <String>[];

    for (final edge in gameState.edges) {
      final validation = _validationService.validateRoadPlacement(
        gameState,
        edge.id,
        playerId,
      );

      if (validation.isValid) {
        availableEdges.add(edge.id);
      }
    }

    return availableEdges;
  }

  /// 都市にアップグレード可能な集落のリスト
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: アップグレード可能な頂点IDのリスト
  List<String> getUpgradeableSettlements(
    GameState gameState,
    String playerId,
  ) {
    final upgradeableVertices = <String>[];

    for (final vertex in gameState.vertices) {
      if (!vertex.hasBuildingOfPlayer(playerId)) continue;
      if (vertex.building!.type != BuildingType.settlement) continue;

      final validation = _validationService.validateCityUpgrade(
        gameState,
        vertex.id,
        playerId,
      );

      if (validation.isValid) {
        upgradeableVertices.add(vertex.id);
      }
    }

    return upgradeableVertices;
  }

  /// プレイヤーが建設可能な建設物の種類を取得
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: 建設可能な種類のリスト
  List<String> getAvailableConstructionTypes(
    GameState gameState,
    String playerId,
  ) {
    final available = <String>[];
    final player = gameState.players.firstWhere((p) => p.id == playerId);

    // 道路
    if (BuildingLimits.canBuild(player.roadsBuilt, BuildingLimits.maxRoads) &&
        _resourceManager.hasEnoughResources(player, BuildingCosts.road)) {
      available.add('road');
    }

    // 集落
    if (BuildingLimits.canBuild(
            player.settlementsBuilt, BuildingLimits.maxSettlements) &&
        _resourceManager.hasEnoughResources(player, BuildingCosts.settlement)) {
      available.add('settlement');
    }

    // 都市
    if (BuildingLimits.canBuild(player.citiesBuilt, BuildingLimits.maxCities) &&
        player.settlementsBuilt > 0 &&
        _resourceManager.hasEnoughResources(player, BuildingCosts.city)) {
      available.add('city');
    }

    // 発展カード
    if (gameState.developmentCardDeck.isNotEmpty &&
        _resourceManager.hasEnoughResources(
            player, BuildingCosts.developmentCard)) {
      available.add('development_card');
    }

    return available;
  }
}
