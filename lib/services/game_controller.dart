import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:test_web_app/models/game_state.dart';
import 'package:test_web_app/models/player.dart';
import 'package:test_web_app/models/player_config.dart';
import 'package:test_web_app/models/hex_tile.dart';
import 'package:test_web_app/models/vertex.dart';
import 'package:test_web_app/models/edge.dart';
import 'package:test_web_app/models/development_card.dart';
import 'package:test_web_app/models/robber.dart';
import 'package:test_web_app/models/enums.dart';
import 'package:test_web_app/services/board_generator.dart';
import 'package:test_web_app/services/turn_service.dart';
import 'package:test_web_app/services/resource_service.dart';
import 'package:test_web_app/services/game_service.dart';
import 'package:test_web_app/services/trade_service.dart';
import 'package:test_web_app/services/cpu_service.dart';
import 'package:test_web_app/services/resource_discard_service.dart';
import 'package:test_web_app/services/robber_service.dart';
import 'package:test_web_app/services/victory_point_service.dart';

/// ゲーム全体を管理するコントローラー
/// UIから呼び出される主要なエントリポイント
class GameController extends ChangeNotifier {
  GameState? _state;

  final BoardGenerator _boardGenerator = BoardGenerator();
  final TurnService _turnService = TurnService();
  final ResourceService _resourceService = ResourceService();
  final GameService _gameService = GameService();
  final TradeService _tradeService = TradeService();
  final CPUService _cpuService = CPUService();
  final ResourceDiscardService _discardService = ResourceDiscardService();
  final RobberService _robberService = RobberService();
  final VictoryPointService _victoryPointService = VictoryPointService();
  final Random _random = Random();

  GameState? get state => _state;
  Player? get currentPlayer => _state?.currentPlayer;
  GamePhase? get currentPhase => _state?.phase;

  // UIで使用するゲッター
  DiceRoll? get lastDiceRoll => _state?.lastDiceRoll;
  bool get hasRolledDice => _state?.lastDiceRoll != null;
  List<GameEvent> get gameLog => _state?.eventLog ?? [];

  // 建設モード管理
  BuildMode _buildMode = BuildMode.none;
  BuildMode get buildMode => _buildMode;

  /// 新しいゲームを開始
  Future<void> startNewGame(GameConfig config) async {
    // ボード生成（港を含む）
    final boardData = _boardGenerator.generateBoard(randomize: true);

    // プレイヤー作成
    final players = <Player>[];
    for (var i = 0; i < config.players.length; i++) {
      final playerConfig = config.players[i];
      players.add(Player(
        id: 'player_$i',
        name: playerConfig.name,
        color: playerConfig.color,
        playerType: playerConfig.playerType,
      ));
    }

    // 発展カードデッキ作成
    final developmentCards = _createDevelopmentCardDeck();

    // 盗賊を砂漠タイルに配置
    final robber = Robber(currentHexId: boardData.desertHexId);

    // ゲーム状態作成
    _state = GameState(
      gameId: 'game_${DateTime.now().millisecondsSinceEpoch}',
      players: players,
      board: boardData.hexTiles,
      vertices: boardData.vertices,
      edges: boardData.edges,
      harbors: boardData.harbors,
      developmentCardDeck: developmentCards,
      robber: robber,
    );

    // ゲーム初期化
    _turnService.initializeGame(_state!);

    notifyListeners();
  }

  /// サイコロを振る
  Future<void> rollDice() async {
    if (_state == null || _state!.phase != GamePhase.normalPlay) {
      return;
    }

    // 既にサイコロを振っている場合は不可
    if (_state!.lastDiceRoll != null) {
      return;
    }

    // サイコロを振る（2つの6面ダイス）
    final die1 = _random.nextInt(6) + 1;
    final die2 = _random.nextInt(6) + 1;
    final dice = DiceRoll(die1, die2);
    _state!.lastDiceRoll = dice;

    // 7が出た場合
    if (dice.total == 7) {
      await startSevenPhase();
      return;
    } else {
      // 資源生産
      _resourceService.distributeResources(dice.total, _state!);
    }

    notifyListeners();
  }

  /// ターン終了
  Future<void> endTurn() async {
    if (_state == null || !_turnService.canEndTurn(_state!)) {
      return;
    }

    // 勝利判定
    checkGameOver();
    if (_state!.phase == GamePhase.gameOver) {
      notifyListeners();
      return;
    }

    // 次のプレイヤーへ
    _state!.lastDiceRoll = null; // サイコロリセット
    _turnService.nextTurn(_state!);

    notifyListeners();

    // 次のプレイヤーがCPUなら自動実行
    if (_state!.currentPlayer.playerType == PlayerType.cpu) {
      await Future.delayed(const Duration(milliseconds: 300)); // UI更新待ち
      await _executeCPUTurn();
    }
  }

  /// 集落を建設
  Future<bool> buildSettlement(String vertexId) async {
    if (_state == null) return false;

    final success = _gameService.buildSettlement(
      _state!,
      vertexId,
      _state!.currentPlayer.id,
    );

    if (success) {
      updateVictoryPoints();
      notifyListeners();
    }

    return success;
  }

  /// 道路を建設
  Future<bool> buildRoad(String edgeId) async {
    if (_state == null) return false;

    final success = _gameService.buildRoad(
      _state!,
      edgeId,
      _state!.currentPlayer.id,
    );

    if (success) {
      notifyListeners();
    }

    return success;
  }

  /// 銀行交易を実行
  Future<bool> executeBankTrade(
    ResourceType giving,
    ResourceType receiving,
  ) async {
    if (_state == null) return false;

    final success = _tradeService.executeBankTrade(
      _state!.currentPlayer,
      giving,
      receiving,
    );

    if (success) {
      notifyListeners();
    }

    return success;
  }

  /// プレイヤー間交易を提案
  Future<void> proposePlayerTrade(
    Map<ResourceType, int> offering,
    Map<ResourceType, int> requesting,
  ) async {
    if (_state == null) return;

    final offer = _tradeService.createTradeOffer(
      _state!.currentPlayer.id,
      offering,
      requesting,
    );

    _state!.currentTradeOffer = offer;
    notifyListeners();
  }

  /// 交易提案を承認
  Future<bool> acceptTrade(String acceptorId) async {
    if (_state == null || _state!.currentTradeOffer == null) return false;

    final offer = _state!.currentTradeOffer!;
    final proposer = _state!.players.firstWhere((p) => p.id == offer.proposerId);
    final acceptor = _state!.players.firstWhere((p) => p.id == acceptorId);

    final success = _tradeService.executePlayerTrade(offer, proposer, acceptor);

    if (success) {
      _state!.currentTradeOffer = null;
      notifyListeners();
    }

    return success;
  }

  /// 交易提案をキャンセル
  Future<void> cancelTrade() async {
    if (_state == null) return;

    _state!.currentTradeOffer = null;
    notifyListeners();
  }

  /// 発展カードデッキを作成
  List<DevelopmentCard> _createDevelopmentCardDeck() {
    final cards = <DevelopmentCard>[];

    // 騎士（14枚）
    for (var i = 0; i < 14; i++) {
      cards.add(DevelopmentCard(type: DevelopmentCardType.knight));
    }

    // 勝利点（5枚）
    for (var i = 0; i < 5; i++) {
      cards.add(DevelopmentCard(type: DevelopmentCardType.victoryPoint));
    }

    // 街道建設（2枚）
    for (var i = 0; i < 2; i++) {
      cards.add(DevelopmentCard(type: DevelopmentCardType.roadBuilding));
    }

    // 資源発見（2枚）
    for (var i = 0; i < 2; i++) {
      cards.add(DevelopmentCard(type: DevelopmentCardType.yearOfPlenty));
    }

    // 資源独占（2枚）
    for (var i = 0; i < 2; i++) {
      cards.add(DevelopmentCard(type: DevelopmentCardType.monopoly));
    }

    // シャッフル
    cards.shuffle();

    return cards;
  }

  /// セットアップ完了後、通常プレイを開始
  void startNormalPlay() {
    if (_state != null) {
      _state!.phase = GamePhase.normalPlay;
      _state!.currentPlayerIndex = 0;
      _state!.lastDiceRoll = null;
      notifyListeners();
    }
  }

  /// 集落を建設できるか
  bool canBuildSettlement() {
    if (_state == null || currentPlayer == null) return false;
    // TODO: 資源チェック、配置ルールチェック
    return true;
  }

  /// 都市を建設できるか
  bool canBuildCity() {
    if (_state == null || currentPlayer == null) return false;
    // TODO: 資源チェック、集落の存在チェック
    return true;
  }

  /// 道路を建設できるか
  bool canBuildRoad() {
    if (_state == null || currentPlayer == null) return false;
    // TODO: 資源チェック、配置ルールチェック
    return true;
  }

  /// 都市を建設（集落からアップグレード）
  Future<bool> buildCity(String vertexId) async {
    if (_state == null) return false;

    final success = _gameService.upgradeToCity(
      _state!,
      vertexId,
      _state!.currentPlayer.id,
    );

    if (success) {
      updateVictoryPoints();
      notifyListeners();
    }

    return success;
  }

  /// デバッグ用: 資源を追加
  void addDebugResources() {
    if (currentPlayer == null) return;

    currentPlayer!.addResource(ResourceType.lumber, 2);
    currentPlayer!.addResource(ResourceType.brick, 2);
    currentPlayer!.addResource(ResourceType.wool, 2);
    currentPlayer!.addResource(ResourceType.grain, 2);
    currentPlayer!.addResource(ResourceType.ore, 2);

    notifyListeners();
  }

  /// 建設モードを設定
  void setBuildMode(BuildMode mode) {
    _buildMode = mode;
    notifyListeners();
  }

  /// 頂点がタップされた時の処理
  Future<void> onVertexTapped(String vertexId) async {
    if (_buildMode == BuildMode.settlement) {
      final success = await buildSettlement(vertexId);
      if (success) {
        _buildMode = BuildMode.none;
        notifyListeners();
      }
    } else if (_buildMode == BuildMode.city) {
      final success = await buildCity(vertexId);
      if (success) {
        _buildMode = BuildMode.none;
        notifyListeners();
      }
    }
  }

  /// 辺がタップされた時の処理
  Future<void> onEdgeTapped(String edgeId) async {
    if (_buildMode == BuildMode.road) {
      final success = await buildRoad(edgeId);
      if (success) {
        _buildMode = BuildMode.none;
        notifyListeners();
      }
    }
  }

  /// CPUのターンを実行（内部メソッド）
  Future<void> _executeCPUTurn() async {
    if (_state == null || _state!.currentPlayer.playerType != PlayerType.cpu) {
      return;
    }

    // 通常プレイフェーズならサイコロを振る
    if (_state!.phase == GamePhase.normalPlay) {
      await rollDice();
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    // CPU行動を決定
    final action = await _cpuService.decideCPUAction(_state!, _state!.currentPlayer);

    if (action == null) {
      return;
    }

    // 行動を実行
    switch (action.type) {
      case CPUActionType.buildSettlement:
        if (action.targetId != null) {
          await buildSettlement(action.targetId!);
        }
        break;
      case CPUActionType.buildRoad:
        if (action.targetId != null) {
          await buildRoad(action.targetId!);
        }
        break;
      case CPUActionType.buildCity:
        if (action.targetId != null) {
          await buildCity(action.targetId!);
        }
        break;
      case CPUActionType.endTurn:
        await endTurn();
        break;
    }

    notifyListeners();
  }

  // ===== Pane L: 銀行交易メソッド =====

  /// 銀行交易実行（UIから呼ばれる）
  ///
  /// @param give 提供する資源（4枚）
  /// @param receive 受け取る資源（1枚）
  /// @return 成功したらtrue
  Future<bool> executeBankTrade(ResourceType give, ResourceType receive) async {
    if (_state == null || _state!.phase != GamePhase.normalPlay) {
      return false;
    }

    final success = _tradeService.executeBankTrade(_state!.currentPlayer, give, receive);
    if (success) {
      notifyListeners();
    }

    return success;
  }

  /// 銀行交易可能か
  ///
  /// @param give 提供する資源
  /// @return 4枚以上所持していればtrue
  bool canBankTrade(ResourceType give) {
    if (_state == null) return false;
    return _tradeService.canBankTrade(_state!.currentPlayer, give);
  }

  /// 交易可能な資源リスト
  ///
  /// @return 4枚以上所持している資源のリスト
  List<ResourceType> getTradeableResources() {
    if (_state == null) return [];
    return _tradeService.getTradeableResources(_state!.currentPlayer);
  }

  // ===== Pane I: 資源破棄フェーズメソッド =====

  /// 7が出た時の処理開始
  Future<void> startSevenPhase() async {
    if (_state == null) return;

    // 資源破棄が必要なプレイヤーを確認
    final needDiscard = _discardService.getPlayersNeedingDiscard(_state!);

    if (needDiscard.isNotEmpty) {
      _state!.phase = GamePhase.resourceDiscard;
      notifyListeners();
    } else {
      // 破棄不要なら盗賊配置へ
      _state!.phase = GamePhase.robberPlacement;
      notifyListeners();
    }
  }

  /// 資源破棄実行（UIから呼ばれる）
  Future<bool> executeDiscard(Player player, Map<ResourceType, int> resources) async {
    if (_state == null) return false;

    final success = _discardService.discardResources(player, resources);
    if (success) {
      notifyListeners();

      // 全員の破棄が完了したか確認
      final stillNeedDiscard = _discardService.getPlayersNeedingDiscard(_state!);
      if (stillNeedDiscard.isEmpty) {
        _state!.phase = GamePhase.robberPlacement;
        notifyListeners();
      }
    }

    return success;
  }

  // ===== Pane J: 盗賊移動+資源強奪メソッド =====

  /// 盗賊移動（UIから呼ばれる）
  ///
  /// @param hexId 移動先タイルID
  /// @return 成功したらtrue
  Future<bool> moveRobber(String hexId) async {
    if (_state == null || _state!.phase != GamePhase.robberPlacement) {
      return false;
    }

    final success = _robberService.moveRobber(_state!, hexId);
    if (success) {
      notifyListeners();
    }

    return success;
  }

  /// 資源を奪う（盗賊移動後に呼ばれる）
  ///
  /// @param targetPlayerId 奪う対象プレイヤーのID
  /// @return 奪った資源タイプ（資源がない場合はnull）
  Future<ResourceType?> stealFromPlayer(String targetPlayerId) async {
    if (_state == null) return null;

    final targetPlayer = _state!.players.firstWhere((p) => p.id == targetPlayerId);
    final stolenResource = _robberService.stealResource(targetPlayer);

    if (stolenResource != null) {
      // 手番プレイヤーに資源を追加
      _state!.currentPlayer.resources[stolenResource] =
        _state!.currentPlayer.resources[stolenResource]! + 1;

      notifyListeners();
    }

    // 盗賊フェーズ終了、通常プレイに戻る
    _state!.phase = GamePhase.normalPlay;
    notifyListeners();

    return stolenResource;
  }

  /// 盗賊配置可能なプレイヤーを取得
  ///
  /// @param hexId タイルID
  /// @return 隣接プレイヤーのリスト
  List<Player> getRobberTargets(String hexId) {
    if (_state == null) return [];
    return _robberService.getAdjacentPlayers(_state!, hexId, _state!.currentPlayer);
  }

  // ===== Pane G: 勝利点計算とゲーム終了判定 =====

  /// 勝利点を再計算（建設後に自動実行）
  void updateVictoryPoints() {
    if (_state == null) return;
    _victoryPointService.updateAllVictoryPoints(_state!);
    notifyListeners();
  }

  /// 勝利条件チェック（ターン終了時に自動実行）
  void checkGameOver() {
    if (_state == null) return;

    final winner = _victoryPointService.getWinner(_state!);
    if (winner != null) {
      _state!.phase = GamePhase.gameOver;
      notifyListeners();
    }
  }
}
