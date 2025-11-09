import 'dart:math';

// modelsからimport
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/vertex.dart';
import '../models/edge.dart';
import '../models/building.dart';
import '../models/road.dart';
import '../models/enums.dart';

// servicesからimport
import 'resource_service.dart';

/// 初期配置フェーズの状態
enum SetupPhase {
  determiningOrder, // 順番決め中
  firstRoundSettlement, // 1巡目：集落配置
  firstRoundRoad, // 1巡目：道路配置
  secondRoundSettlement, // 2巡目：集落配置
  secondRoundRoad, // 2巡目：道路配置
  completed, // 初期配置完了
}

/// 初期配置の状態管理
class SetupState {
  final SetupPhase phase;
  final int currentPlayerIndex;
  final bool isReversed; // 2巡目（逆順）かどうか
  final String? lastPlacedSettlementId; // 最後に配置した集落の頂点ID
  final Map<String, int> playerOrderRolls; // プレイヤーごとのサイコロの出目

  const SetupState({
    required this.phase,
    required this.currentPlayerIndex,
    this.isReversed = false,
    this.lastPlacedSettlementId,
    this.playerOrderRolls = const {},
  });

  SetupState copyWith({
    SetupPhase? phase,
    int? currentPlayerIndex,
    bool? isReversed,
    String? lastPlacedSettlementId,
    Map<String, int>? playerOrderRolls,
  }) {
    return SetupState(
      phase: phase ?? this.phase,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      isReversed: isReversed ?? this.isReversed,
      lastPlacedSettlementId: lastPlacedSettlementId ?? this.lastPlacedSettlementId,
      playerOrderRolls: playerOrderRolls ?? this.playerOrderRolls,
    );
  }
}

/// 建設物配置サービス
/// フェーズ2「初期配置」の実装
class BuildingService {
  final ResourceService _resourceService;
  final Random _random;

  BuildingService({
    ResourceService? resourceService,
    Random? random,
  })  : _resourceService = resourceService ?? ResourceService(),
        _random = random ?? Random();

  /// 初期配置フェーズを開始
  ///
  /// [gameState] ゲーム状態
  ///
  /// 戻り値: 初期配置の状態
  SetupState startSetupPhase(GameState gameState) {
    gameState.phase = GamePhase.setup;

    return const SetupState(
      phase: SetupPhase.determiningOrder,
      currentPlayerIndex: 0,
      playerOrderRolls: {},
    );
  }

  /// プレイヤーの順番を決めるためにサイコロを振る
  ///
  /// [setupState] 初期配置の状態
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: (更新された状態, サイコロの出目)
  (SetupState, int) rollForOrder(SetupState setupState, String playerId) {
    assert(setupState.phase == SetupPhase.determiningOrder,
        '順番決めフェーズでのみ使用できます');

    // サイコロを2つ振る
    final die1 = _random.nextInt(6) + 1;
    final die2 = _random.nextInt(6) + 1;
    final total = die1 + die2;

    // 出目を記録
    final updatedRolls = Map<String, int>.from(setupState.playerOrderRolls);
    updatedRolls[playerId] = total;

    return (
      setupState.copyWith(playerOrderRolls: updatedRolls),
      total,
    );
  }

  /// 順番決めを完了し、配置順を確定
  ///
  /// [gameState] ゲーム状態
  /// [setupState] 初期配置の状態
  ///
  /// 戻り値: (更新されたゲーム状態, 更新された初期配置状態, 配置順のプレイヤーIDリスト)
  (GameState, SetupState, List<String>) finalizePlayerOrder(
    GameState gameState,
    SetupState setupState,
  ) {
    assert(setupState.phase == SetupPhase.determiningOrder,
        '順番決めフェーズでのみ使用できます');
    assert(setupState.playerOrderRolls.length == gameState.players.length,
        'すべてのプレイヤーがサイコロを振る必要があります');

    // 出目の大きい順にソート
    final sortedPlayers = gameState.players.toList()
      ..sort((a, b) {
        final rollA = setupState.playerOrderRolls[a.id] ?? 0;
        final rollB = setupState.playerOrderRolls[b.id] ?? 0;
        return rollB.compareTo(rollA); // 降順
      });

    // プレイヤーの順序を更新
    final orderedPlayerIds = sortedPlayers.map((p) => p.id).toList();

    // 1巡目の集落配置フェーズへ移行
    final newSetupState = setupState.copyWith(
      phase: SetupPhase.firstRoundSettlement,
      currentPlayerIndex: 0,
    );

    return (gameState, newSetupState, orderedPlayerIds);
  }

  /// 配置可能な頂点をすべて取得
  ///
  /// [gameState] ゲーム状態
  /// [setupState] 初期配置の状態
  ///
  /// 戻り値: 配置可能な頂点IDのリスト
  List<String> getAvailableVertices(GameState gameState, SetupState setupState) {
    final availableVertices = <String>[];

    for (final vertex in gameState.vertices) {
      if (canPlaceSettlement(gameState, vertex.id, setupState)) {
        availableVertices.add(vertex.id);
      }
    }

    return availableVertices;
  }

  /// 集落を配置できるかチェック
  ///
  /// [gameState] ゲーム状態
  /// [vertexId] 頂点ID
  /// [setupState] 初期配置の状態（nullの場合は通常プレイ）
  ///
  /// 戻り値: 配置可能かどうか
  bool canPlaceSettlement(
    GameState gameState,
    String vertexId, [
    SetupState? setupState,
  ]) {
    final vertex = gameState.vertices.firstWhere((v) => v.id == vertexId);

    // 既に建設物がある場合はNG
    if (vertex.hasBuilding) {
      return false;
    }

    // 距離ルールをチェック
    if (!checkDistanceRule(gameState, vertexId)) {
      return false;
    }

    // 初期配置フェーズ以外では、道路接続ルールをチェック
    if (setupState == null || setupState.phase == SetupPhase.completed) {
      final currentPlayerId = gameState.currentPlayer.id;
      if (!isConnectedByRoad(gameState, vertexId, currentPlayerId)) {
        return false;
      }
    }

    return true;
  }

  /// 距離ルールをチェック
  /// 隣接する頂点に建設物がないか確認
  ///
  /// [gameState] ゲーム状態
  /// [vertexId] 頂点ID
  ///
  /// 戻り値: 距離ルールを満たしているか
  bool checkDistanceRule(GameState gameState, String vertexId) {
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
  ///
  /// [gameState] ゲーム状態
  /// [vertexId] 頂点ID
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: 道路が接続しているか
  bool isConnectedByRoad(GameState gameState, String vertexId, String playerId) {
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

  /// 初期配置フェーズで集落を配置
  ///
  /// [gameState] ゲーム状態
  /// [setupState] 初期配置の状態
  /// [vertexId] 頂点ID
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: (更新されたゲーム状態, 更新された初期配置状態, 成功したか)
  (GameState, SetupState, bool) placeInitialSettlement(
    GameState gameState,
    SetupState setupState,
    String vertexId,
    String playerId,
  ) {
    // 集落配置フェーズかチェック
    if (setupState.phase != SetupPhase.firstRoundSettlement &&
        setupState.phase != SetupPhase.secondRoundSettlement) {
      return (gameState, setupState, false);
    }

    // 配置可能かチェック
    if (!canPlaceSettlement(gameState, vertexId, setupState)) {
      return (gameState, setupState, false);
    }

    final player = gameState.players.firstWhere((p) => p.id == playerId);
    final vertex = gameState.vertices.firstWhere((v) => v.id == vertexId);

    // 集落の上限チェック
    if (player.settlementsBuilt >= 5) {
      return (gameState, setupState, false);
    }

    // 集落を配置
    vertex.building = Building(
      playerId: playerId,
      type: BuildingType.settlement,
    );
    player.settlementsBuilt++;

    // イベントログに追加
    gameState.logEvent(GameEvent(
      timestamp: DateTime.now(),
      playerId: playerId,
      type: GameEventType.buildingPlaced,
      data: {'vertexId': vertexId, 'type': 'settlement', 'phase': 'setup'},
    ));

    // 次のフェーズ（道路配置）へ移行
    final nextPhase = setupState.phase == SetupPhase.firstRoundSettlement
        ? SetupPhase.firstRoundRoad
        : SetupPhase.secondRoundRoad;

    final newSetupState = setupState.copyWith(
      phase: nextPhase,
      lastPlacedSettlementId: vertexId,
    );

    return (gameState, newSetupState, true);
  }

  /// 配置可能な辺をすべて取得
  ///
  /// [gameState] ゲーム状態
  /// [setupState] 初期配置の状態
  ///
  /// 戻り値: 配置可能な辺IDのリスト
  List<String> getAvailableEdges(GameState gameState, SetupState setupState) {
    final availableEdges = <String>[];

    // 初期配置の道路配置フェーズでは、最後に配置した集落に隣接する辺のみ
    if (setupState.lastPlacedSettlementId != null) {
      final vertex = gameState.vertices
          .firstWhere((v) => v.id == setupState.lastPlacedSettlementId);

      for (final edgeId in vertex.adjacentEdgeIds) {
        if (canPlaceRoad(gameState, edgeId, setupState)) {
          availableEdges.add(edgeId);
        }
      }
    }

    return availableEdges;
  }

  /// 道路を配置できるかチェック
  ///
  /// [gameState] ゲーム状態
  /// [edgeId] 辺ID
  /// [setupState] 初期配置の状態（nullの場合は通常プレイ）
  ///
  /// 戻り値: 配置可能かどうか
  bool canPlaceRoad(GameState gameState, String edgeId, [SetupState? setupState]) {
    final edge = gameState.edges.firstWhere((e) => e.id == edgeId);

    // 既に道路がある場合はNG
    if (edge.hasRoad) {
      return false;
    }

    // 初期配置フェーズでは、最後に配置した集落に隣接している必要がある
    if (setupState != null &&
        setupState.phase != SetupPhase.completed &&
        setupState.lastPlacedSettlementId != null) {
      if (!edge.isConnectedToVertex(setupState.lastPlacedSettlementId!)) {
        return false;
      }
    }

    return true;
  }

  /// 初期配置フェーズで道路を配置
  ///
  /// [gameState] ゲーム状態
  /// [setupState] 初期配置の状態
  /// [edgeId] 辺ID
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: (更新されたゲーム状態, 更新された初期配置状態, 成功したか)
  (GameState, SetupState, bool) placeInitialRoad(
    GameState gameState,
    SetupState setupState,
    String edgeId,
    String playerId,
  ) {
    // 道路配置フェーズかチェック
    if (setupState.phase != SetupPhase.firstRoundRoad &&
        setupState.phase != SetupPhase.secondRoundRoad) {
      return (gameState, setupState, false);
    }

    // 配置可能かチェック
    if (!canPlaceRoad(gameState, edgeId, setupState)) {
      return (gameState, setupState, false);
    }

    final player = gameState.players.firstWhere((p) => p.id == playerId);
    final edge = gameState.edges.firstWhere((e) => e.id == edgeId);

    // 道路の上限チェック
    if (player.roadsBuilt >= 15) {
      return (gameState, setupState, false);
    }

    // 道路を配置
    edge.road = Road(playerId: playerId);
    player.roadsBuilt++;

    // イベントログに追加
    gameState.logEvent(GameEvent(
      timestamp: DateTime.now(),
      playerId: playerId,
      type: GameEventType.roadPlaced,
      data: {'edgeId': edgeId, 'phase': 'setup'},
    ));

    // 2巡目の道路配置の場合、初期資源を配布
    final isSecondRound = setupState.phase == SetupPhase.secondRoundRoad;
    if (isSecondRound && setupState.lastPlacedSettlementId != null) {
      _resourceService.distributeInitialResources(
        setupState.lastPlacedSettlementId!,
        player,
        gameState,
      );

      // 資源獲得をログに記録
      for (final entry in player.resources.entries) {
        if (entry.value > 0) {
          gameState.logEvent(GameEvent(
            timestamp: DateTime.now(),
            playerId: playerId,
            type: GameEventType.resourceGained,
            data: {
              'resource': entry.key.name,
              'amount': entry.value,
              'reason': 'initial_setup',
            },
          ));
        }
      }
    }

    // 次のプレイヤーまたは次の巡へ移行
    final newSetupState = _advanceSetupPhase(gameState, setupState);

    return (gameState, newSetupState, true);
  }

  /// 初期配置フェーズを進める
  ///
  /// [gameState] ゲーム状態
  /// [setupState] 初期配置の状態
  ///
  /// 戻り値: 更新された初期配置状態
  SetupState _advanceSetupPhase(GameState gameState, SetupState setupState) {
    final playerCount = gameState.players.length;
    var nextPlayerIndex = setupState.currentPlayerIndex;
    var nextPhase = setupState.phase;
    var isReversed = setupState.isReversed;

    // 1巡目の道路配置が完了
    if (setupState.phase == SetupPhase.firstRoundRoad) {
      if (nextPlayerIndex < playerCount - 1) {
        // 次のプレイヤーへ
        nextPlayerIndex++;
        nextPhase = SetupPhase.firstRoundSettlement;
      } else {
        // 1巡目完了、2巡目へ（逆順）
        isReversed = true;
        nextPhase = SetupPhase.secondRoundSettlement;
        // 最後のプレイヤーから開始
      }
    }
    // 2巡目の道路配置が完了
    else if (setupState.phase == SetupPhase.secondRoundRoad) {
      if (nextPlayerIndex > 0) {
        // 前のプレイヤーへ（逆順）
        nextPlayerIndex--;
        nextPhase = SetupPhase.secondRoundSettlement;
      } else {
        // 2巡目完了、初期配置フェーズ終了
        nextPhase = SetupPhase.completed;
        gameState.phase = GamePhase.normalPlay;
      }
    }

    return setupState.copyWith(
      phase: nextPhase,
      currentPlayerIndex: nextPlayerIndex,
      isReversed: isReversed,
      lastPlacedSettlementId: null,
    );
  }

  /// 初期配置フェーズが完了したかチェック
  ///
  /// [setupState] 初期配置の状態
  ///
  /// 戻り値: 完了したかどうか
  bool isSetupComplete(SetupState setupState) {
    return setupState.phase == SetupPhase.completed;
  }

  /// 現在のプレイヤーが配置すべきものを取得
  ///
  /// [setupState] 初期配置の状態
  ///
  /// 戻り値: "settlement" または "road"
  String getCurrentPlacementType(SetupState setupState) {
    switch (setupState.phase) {
      case SetupPhase.firstRoundSettlement:
      case SetupPhase.secondRoundSettlement:
        return 'settlement';
      case SetupPhase.firstRoundRoad:
      case SetupPhase.secondRoundRoad:
        return 'road';
      default:
        return 'none';
    }
  }

  /// 初期配置の進行状況を取得
  ///
  /// [setupState] 初期配置の状態
  /// [playerCount] プレイヤー数
  ///
  /// 戻り値: (現在の巡, 合計の巡)
  (int, int) getSetupProgress(SetupState setupState, int playerCount) {
    final totalRounds = playerCount * 2; // 1巡目 + 2巡目

    int currentRound = 0;
    if (setupState.phase == SetupPhase.firstRoundSettlement ||
        setupState.phase == SetupPhase.firstRoundRoad) {
      currentRound = setupState.currentPlayerIndex + 1;
    } else if (setupState.phase == SetupPhase.secondRoundSettlement ||
        setupState.phase == SetupPhase.secondRoundRoad) {
      currentRound = playerCount + (playerCount - setupState.currentPlayerIndex);
    } else if (setupState.phase == SetupPhase.completed) {
      currentRound = totalRounds;
    }

    return (currentRound, totalRounds);
  }
}
