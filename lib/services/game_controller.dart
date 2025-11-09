import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/player_config.dart';
import '../models/hex_tile.dart';
import '../models/vertex.dart';
import '../models/edge.dart';
import '../models/development_card.dart';
import '../models/enums.dart';
import 'board_generator.dart';
import 'turn_service.dart';
import 'resource_service.dart';
import 'game_service.dart';
import 'trade_service.dart';

/// ゲーム全体を管理するコントローラー
/// UIから呼び出される主要なエントリポイント
class GameController extends ChangeNotifier {
  GameState? _state;

  final BoardGenerator _boardGenerator = BoardGenerator();
  final TurnService _turnService = TurnService();
  final ResourceService _resourceService = ResourceService();
  final GameService _gameService = GameService();
  final TradeService _tradeService = TradeService();

  GameState? get state => _state;
  Player? get currentPlayer => _state?.currentPlayer;
  GamePhase? get currentPhase => _state?.phase;

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
      ));
    }

    // 発展カードデッキ作成
    final developmentCards = _createDevelopmentCardDeck();

    // ゲーム状態作成
    _state = GameState(
      gameId: 'game_${DateTime.now().millisecondsSinceEpoch}',
      players: players,
      board: boardData.hexTiles,
      vertices: boardData.vertices,
      edges: boardData.edges,
      harbors: boardData.harbors,
      developmentCardDeck: developmentCards,
      robberHexId: boardData.desertHexId,
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

    final dice = _gameService.rollDice();
    _state!.lastDiceRoll = dice;

    // 7が出た場合
    if (dice.total == 7) {
      // TODO: 資源破棄フェーズへ
      _state!.phase = GamePhase.robberPlacement;
    } else {
      // 資源生産
      _resourceService.produceResources(_state!, dice.total);
    }

    notifyListeners();
  }

  /// ターン終了
  Future<void> endTurn() async {
    if (_state == null || !_turnService.canEndTurn(_state!)) {
      return;
    }

    // 勝利判定
    final winner = _turnService.checkVictory(_state!);
    if (winner != null) {
      _state!.phase = GamePhase.gameOver;
      notifyListeners();
      return;
    }

    // 次のプレイヤーへ
    _state!.lastDiceRoll = null; // サイコロリセット
    _turnService.nextTurn(_state!);

    notifyListeners();
  }

  /// 集落を建設
  Future<bool> buildSettlement(String vertexId) async {
    if (_state == null) return false;

    final success = await _gameService.buildSettlement(
      _state!,
      _state!.currentPlayer,
      vertexId,
    );

    if (success) {
      notifyListeners();
    }

    return success;
  }

  /// 道路を建設
  Future<bool> buildRoad(String edgeId) async {
    if (_state == null) return false;

    final success = await _gameService.buildRoad(
      _state!,
      _state!.currentPlayer,
      edgeId,
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
}
