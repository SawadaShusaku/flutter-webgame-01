import 'dart:math';

// modelsからimport
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/hex_tile.dart';
import '../models/vertex.dart';
import '../models/edge.dart';
import '../models/building.dart';
import '../models/road.dart';
import '../models/development_card.dart';
import '../models/enums.dart';

// servicesからimport
import 'board_generator.dart';
import 'resource_service.dart';
import 'development_card_service.dart';
import 'longest_road_service.dart';

/// ゲーム全体管理サービス
/// - ゲーム全体の管理
/// - ターン管理
/// - ゲーム状態の更新
class GameService {
  final BoardGenerator _boardGenerator;
  final ResourceService _resourceService;
  final DevelopmentCardService _developmentCardService;
  final LongestRoadService _longestRoadService;
  final Random _random;

  GameService({
    BoardGenerator? boardGenerator,
    ResourceService? resourceService,
    DevelopmentCardService? developmentCardService,
    LongestRoadService? longestRoadService,
    Random? random,
  })  : _boardGenerator = boardGenerator ?? BoardGenerator(),
        _resourceService = resourceService ?? ResourceService(),
        _developmentCardService =
            developmentCardService ?? DevelopmentCardService(),
        _longestRoadService = longestRoadService ?? LongestRoadService(),
        _random = random ?? Random();

  /// 新しいゲームを開始
  ///
  /// [gameId] ゲームID
  /// [playerNames] プレイヤー名のリスト
  /// [playerColors] プレイヤーカラーのリスト
  ///
  /// 戻り値: 初期化されたゲーム状態
  GameState startNewGame({
    required String gameId,
    required List<String> playerNames,
    required List<PlayerColor> playerColors,
    bool randomizeBoard = true,
  }) {
    assert(playerNames.length == playerColors.length,
        'プレイヤー名と色の数が一致していません');
    assert(playerNames.length >= 2 && playerNames.length <= 4,
        'プレイヤー数は2-4人である必要があります');

    // プレイヤーを作成
    final players = <Player>[];
    for (int i = 0; i < playerNames.length; i++) {
      players.add(Player(
        id: 'player_${i + 1}',
        name: playerNames[i],
        color: playerColors[i],
      ));
    }

    // ボードを生成
    final board = _boardGenerator.generateBoard(randomize: randomizeBoard);

    // 発展カードデッキを生成
    final developmentCardDeck = _createDevelopmentCardDeck();

    // ゲーム状態を作成
    return GameState(
      gameId: gameId,
      players: players,
      board: board.hexTiles,
      vertices: board.vertices,
      edges: board.edges,
      developmentCardDeck: developmentCardDeck,
      phase: GamePhase.setup,
      currentPlayerIndex: 0,
      turnNumber: 0,
      robberHexId: board.desertHexId,
    );
  }

  /// 発展カードデッキを作成
  List<DevelopmentCard> _createDevelopmentCardDeck() {
    final deck = <DevelopmentCard>[];

    // 騎士カード（14枚）
    for (int i = 0; i < 14; i++) {
      deck.add(const DevelopmentCard(type: DevelopmentCardType.knight));
    }

    // 勝利点カード（5枚）
    for (int i = 0; i < 5; i++) {
      deck.add(const DevelopmentCard(type: DevelopmentCardType.victoryPoint));
    }

    // 街道建設カード（2枚）
    for (int i = 0; i < 2; i++) {
      deck.add(const DevelopmentCard(type: DevelopmentCardType.roadBuilding));
    }

    // 資源発見カード（2枚）
    for (int i = 0; i < 2; i++) {
      deck.add(const DevelopmentCard(type: DevelopmentCardType.yearOfPlenty));
    }

    // 資源独占カード（2枚）
    for (int i = 0; i < 2; i++) {
      deck.add(const DevelopmentCard(type: DevelopmentCardType.monopoly));
    }

    // シャッフル
    deck.shuffle(_random);

    return deck;
  }

  /// サイコロを振る
  ///
  /// [gameState] ゲーム状態
  ///
  /// 戻り値: サイコロの結果
  DiceRoll rollDice(GameState gameState) {
    final die1 = _random.nextInt(6) + 1;
    final die2 = _random.nextInt(6) + 1;
    final roll = DiceRoll(die1, die2);

    gameState.lastDiceRoll = roll;

    // イベントログに追加
    gameState.logEvent(GameEvent(
      timestamp: DateTime.now(),
      playerId: gameState.currentPlayer.id,
      type: GameEventType.diceRolled,
      data: {'die1': die1, 'die2': die2, 'total': roll.total},
    ));

    // 7が出た場合の処理
    if (roll.total == 7) {
      gameState.phase = GamePhase.resourceDiscard;
    } else {
      // 資源を配布
      final resourcesGained =
          _resourceService.distributeResources(roll.total, gameState);

      // 資源獲得をログに追加
      for (final entry in resourcesGained.entries) {
        final playerId = entry.key;
        final resources = entry.value;

        for (final resourceEntry in resources.entries) {
          if (resourceEntry.value > 0) {
            gameState.logEvent(GameEvent(
              timestamp: DateTime.now(),
              playerId: playerId,
              type: GameEventType.resourceGained,
              data: {
                'resource': resourceEntry.key.name,
                'amount': resourceEntry.value,
              },
            ));
          }
        }
      }
    }

    return roll;
  }

  /// 道路を建設
  ///
  /// [gameState] ゲーム状態
  /// [edgeId] 辺のID
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: 建設が成功したかどうか
  bool buildRoad(GameState gameState, String edgeId, String playerId) {
    final player = gameState.players.firstWhere((p) => p.id == playerId);
    final edge = gameState.edges.firstWhere((e) => e.id == edgeId);

    // 既に道路がある場合
    if (edge.hasRoad) {
      return false;
    }

    // 道路の上限チェック（15本）
    if (player.roadsBuilt >= 15) {
      return false;
    }

    // 初期配置フェーズ以外ではコストが必要
    if (gameState.phase != GamePhase.setup) {
      if (!_resourceService.payBuildingCost(player, 'road')) {
        return false;
      }
    }

    // 道路を配置
    edge.road = Road(playerId: playerId);
    player.roadsBuilt++;

    // イベントログに追加
    gameState.logEvent(GameEvent(
      timestamp: DateTime.now(),
      playerId: playerId,
      type: GameEventType.roadPlaced,
      data: {'edgeId': edgeId},
    ));

    return true;
  }

  /// 集落を建設
  ///
  /// [gameState] ゲーム状態
  /// [vertexId] 頂点のID
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: 建設が成功したかどうか
  bool buildSettlement(GameState gameState, String vertexId, String playerId) {
    final player = gameState.players.firstWhere((p) => p.id == playerId);
    final vertex = gameState.vertices.firstWhere((v) => v.id == vertexId);

    // 既に建設物がある場合
    if (vertex.hasBuilding) {
      return false;
    }

    // 集落の上限チェック（5個）
    if (player.settlementsBuilt >= 5) {
      return false;
    }

    // 距離ルールチェック（隣接する頂点に建設物がないか）
    if (!_checkDistanceRule(gameState, vertexId)) {
      return false;
    }

    // 初期配置フェーズ以外ではコストと接続ルールが必要
    if (gameState.phase != GamePhase.setup) {
      if (!_resourceService.payBuildingCost(player, 'settlement')) {
        return false;
      }

      // 道路が接続しているか確認
      if (!_isConnectedByRoad(gameState, vertexId, playerId)) {
        return false;
      }
    }

    // 集落を配置
    vertex.building = Building(
      playerId: playerId,
      type: BuildingType.settlement,
    );
    player.settlementsBuilt++;
    player.victoryPoints = player.calculateVictoryPoints();

    // イベントログに追加
    gameState.logEvent(GameEvent(
      timestamp: DateTime.now(),
      playerId: playerId,
      type: GameEventType.buildingPlaced,
      data: {'vertexId': vertexId, 'type': 'settlement'},
    ));

    return true;
  }

  /// 都市にアップグレード
  ///
  /// [gameState] ゲーム状態
  /// [vertexId] 頂点のID
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: アップグレードが成功したかどうか
  bool upgradeToCity(GameState gameState, String vertexId, String playerId) {
    final player = gameState.players.firstWhere((p) => p.id == playerId);
    final vertex = gameState.vertices.firstWhere((v) => v.id == vertexId);

    // 自分の集落があるか確認
    if (!vertex.hasBuildingOfPlayer(playerId) ||
        vertex.building!.type != BuildingType.settlement) {
      return false;
    }

    // 都市の上限チェック（4個）
    if (player.citiesBuilt >= 4) {
      return false;
    }

    // コストを支払う
    if (!_resourceService.payBuildingCost(player, 'city')) {
      return false;
    }

    // 都市にアップグレード
    vertex.building = Building(
      playerId: playerId,
      type: BuildingType.city,
    );
    player.settlementsBuilt--;
    player.citiesBuilt++;
    player.victoryPoints = player.calculateVictoryPoints();

    // イベントログに追加
    gameState.logEvent(GameEvent(
      timestamp: DateTime.now(),
      playerId: playerId,
      type: GameEventType.buildingPlaced,
      data: {'vertexId': vertexId, 'type': 'city'},
    ));

    return true;
  }

  /// 発展カードを購入
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: 購入した発展カード（購入できない場合はnull）
  DevelopmentCard? buyDevelopmentCard(GameState gameState, String playerId) {
    final player = gameState.players.firstWhere((p) => p.id == playerId);

    // コストを支払う
    if (!_resourceService.payBuildingCost(player, 'development_card')) {
      return null;
    }

    // カードを引く
    final card = gameState.drawDevelopmentCard();
    if (card == null) {
      // カードがない場合、コストを返却
      final required = _resourceService.getRequiredResources('development_card');
      for (final entry in required.entries) {
        player.addResource(entry.key, entry.value);
      }
      return null;
    }

    // プレイヤーに追加
    player.addDevelopmentCard(card);

    // 購入を通知（同ターン使用制限のため）
    _developmentCardService.notifyCardPurchased(card);

    // 勝利点カードの場合、勝利点を更新
    if (card.type == DevelopmentCardType.victoryPoint) {
      player.victoryPoints = player.calculateVictoryPoints();
    }

    // イベントログに追加
    gameState.logEvent(GameEvent(
      timestamp: DateTime.now(),
      playerId: playerId,
      type: GameEventType.cardPurchased,
      data: {'cardType': card.type.name},
    ));

    return card;
  }

  /// ターンを開始
  ///
  /// [gameState] ゲーム状態
  void startTurn(GameState gameState) {
    _developmentCardService.startTurn();
  }

  /// ターンを終了して次のプレイヤーに進む
  ///
  /// [gameState] ゲーム状態
  void endTurn(GameState gameState) {
    gameState.nextPlayer();
    gameState.phase = GamePhase.normalPlay;
    // 次のプレイヤーのターンを開始
    startTurn(gameState);
  }

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
      final otherVertex = gameState.vertices.firstWhere((v) => v.id == otherVertexId);

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

  /// 勝利条件をチェック
  ///
  /// [gameState] ゲーム状態
  ///
  /// 戻り値: 勝者のプレイヤー（いない場合はnull）
  Player? checkVictoryCondition(GameState gameState) {
    for (final player in gameState.players) {
      // 勝利点を再計算
      player.victoryPoints = player.calculateVictoryPoints();

      // 10点以上で勝利（自分のターンのみ）
      if (player.victoryPoints >= 10 &&
          player.id == gameState.currentPlayer.id) {
        gameState.phase = GamePhase.gameOver;
        return player;
      }
    }

    return null;
  }

  /// 盗賊を移動
  ///
  /// [gameState] ゲーム状態
  /// [targetHexId] 移動先のタイルID
  ///
  /// 戻り値: 移動が成功したかどうか
  bool moveRobber(GameState gameState, String targetHexId) {
    // 現在の盗賊の位置を解除
    if (gameState.robberHexId != null) {
      final currentHex =
          gameState.board.firstWhere((h) => h.id == gameState.robberHexId);
      currentHex.hasRobber = false;
    }

    // 新しい位置に配置
    final targetHex = gameState.board.firstWhere((h) => h.id == targetHexId);
    targetHex.hasRobber = true;
    gameState.robberHexId = targetHexId;

    // イベントログに追加
    gameState.logEvent(GameEvent(
      timestamp: DateTime.now(),
      playerId: gameState.currentPlayer.id,
      type: GameEventType.robberMoved,
      data: {'hexId': targetHexId},
    ));

    return true;
  }

  /// 最長交易路を更新
  ///
  /// [gameState] ゲーム状態
  ///
  /// 戻り値: 最長交易路が変更されたかどうか
  bool updateLongestRoad(GameState gameState) {
    return _longestRoadService.updateLongestRoad(gameState);
  }

  /// プレイヤーの最長道路の長さを計算
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: 最長道路の長さ
  int calculateLongestRoadLength(GameState gameState, String playerId) {
    return _longestRoadService.calculateLongestRoad(gameState, playerId);
  }

  /// 最大騎士力を更新（廃止予定）
  ///
  /// [gameState] ゲーム状態
  ///
  /// 注: 最大騎士力の更新はDevelopmentCardServiceで自動的に行われます
  @Deprecated('Use DevelopmentCardService.playKnightCard instead')
  void updateLargestArmy(GameState gameState) {
    // 後方互換性のために残す
    int maxKnights = 0;
    Player? largestArmyPlayer;

    for (final player in gameState.players) {
      if (player.knightsPlayed >= 3 && player.knightsPlayed > maxKnights) {
        maxKnights = player.knightsPlayed;
        largestArmyPlayer = player;
      }
    }

    // 最大騎士力を更新
    for (final player in gameState.players) {
      player.hasLargestArmy = player == largestArmyPlayer;
      player.victoryPoints = player.calculateVictoryPoints();
    }
  }

  // ========== 発展カード使用メソッド ==========

  /// 騎士カードを使用
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  /// [card] 使用するカード
  /// [newRobberHexId] 盗賊の移動先タイルID
  /// [targetPlayerId] 資源を奪う対象プレイヤーID（nullの場合は奪わない）
  ///
  /// 戻り値: 使用結果
  DevelopmentCardResult playKnightCard(
    GameState gameState,
    String playerId,
    DevelopmentCard card,
    String newRobberHexId,
    String? targetPlayerId,
  ) {
    return _developmentCardService.playKnightCard(
      gameState,
      playerId,
      card,
      newRobberHexId,
      targetPlayerId,
    );
  }

  /// 街道建設カードを使用
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  /// [card] 使用するカード
  ///
  /// 戻り値: 使用結果
  DevelopmentCardResult playRoadBuildingCard(
    GameState gameState,
    String playerId,
    DevelopmentCard card,
  ) {
    return _developmentCardService.playRoadBuildingCard(
      gameState,
      playerId,
      card,
    );
  }

  /// 資源発見カードを使用
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  /// [card] 使用するカード
  /// [resource1] 獲得する資源1
  /// [resource2] 獲得する資源2
  ///
  /// 戻り値: 使用結果
  DevelopmentCardResult playYearOfPlentyCard(
    GameState gameState,
    String playerId,
    DevelopmentCard card,
    ResourceType resource1,
    ResourceType resource2,
  ) {
    return _developmentCardService.playYearOfPlentyCard(
      gameState,
      playerId,
      card,
      resource1,
      resource2,
    );
  }

  /// 資源独占カードを使用
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  /// [card] 使用するカード
  /// [resourceType] 奪う資源の種類
  ///
  /// 戻り値: 使用結果
  DevelopmentCardResult playMonopolyCard(
    GameState gameState,
    String playerId,
    DevelopmentCard card,
    ResourceType resourceType,
  ) {
    return _developmentCardService.playMonopolyCard(
      gameState,
      playerId,
      card,
      resourceType,
    );
  }

  /// プレイヤーが使用可能なカードのリストを取得
  ///
  /// [player] プレイヤー
  ///
  /// 戻り値: 使用可能なカードのリスト
  List<DevelopmentCard> getPlayableCards(Player player) {
    return _developmentCardService.getPlayableCards(player);
  }

  /// プレイヤーのカード種別ごとの枚数を取得
  ///
  /// [player] プレイヤー
  ///
  /// 戻り値: カード種別ごとの枚数マップ
  Map<DevelopmentCardType, int> getCardCounts(Player player) {
    return _developmentCardService.getCardCounts(player);
  }
}
