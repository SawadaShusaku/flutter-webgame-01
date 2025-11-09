import 'package:flutter/foundation.dart';
import 'package:test_web_app/services/victory_service.dart';
import 'package:test_web_app/services/game_state_manager.dart';
import 'package:test_web_app/ui/widgets/log/game_log_widget.dart';

/// 勝利判定統合の使用例
///
/// ゲームフローに勝利判定を統合する方法を示すサンプルコード
class VictoryIntegrationExample {
  final VictoryService victoryService;
  final GameStateManager gameStateManager;

  /// ゲームログエントリのリスト
  final List<GameLogEntry> gameLog = [];

  VictoryIntegrationExample({
    VictoryService? victoryService,
    GameStateManager? gameStateManager,
  })  : victoryService = victoryService ?? VictoryService(),
        gameStateManager = gameStateManager ?? GameStateManager();

  /// ターン終了時の処理例
  ///
  /// ゲームのターン終了時に呼び出し、勝利判定を実行する
  ///
  /// [gameState] 現在のゲーム状態
  /// [currentPlayerId] 現在のプレイヤーID
  ///
  /// 戻り値: 勝利判定結果（勝者がいる場合はVictoryCheckResult）
  Future<VictoryCheckResult?> onTurnEnd({
    required Map<String, dynamic> gameState,
    required String currentPlayerId,
  }) async {
    debugPrint('Turn ended for player: $currentPlayerId');

    // 1. 勝利判定を実行
    final victoryResult = victoryService.checkVictory(
      players: gameState['players'] as List<dynamic>,
      currentPlayerId: currentPlayerId,
      vertices: gameState['vertices'] as List<dynamic>?,
      edges: gameState['edges'] as List<dynamic>?,
    );

    // 2. ログに記録
    _addLog(GameLogEntry(
      id: _generateLogId(),
      eventType: GameLogEventType.turnEnd,
      message: 'Player $currentPlayerId ended their turn',
      playerId: currentPlayerId,
    ));

    // 3. 勝者が決定した場合
    if (victoryResult.hasWinner) {
      final winner = victoryResult.winnerBreakdown!;

      _addLog(GameLogEntry(
        id: _generateLogId(),
        eventType: GameLogEventType.victory,
        message:
            'Player ${winner.playerId} wins with ${winner.totalPoints} points!',
        playerId: winner.playerId,
        data: winner.toJson(),
      ));

      debugPrint('VICTORY! Player ${winner.playerId} wins!');
      debugPrint('Victory breakdown: $winner');

      return victoryResult;
    }

    // 4. オートセーブを実行
    await gameStateManager.autoSave(gameState);

    // 5. 全プレイヤーの現在の得点をログに記録（デバッグ用）
    for (final breakdown in victoryResult.allPlayerPoints) {
      debugPrint(
          'Player ${breakdown.playerId}: ${breakdown.totalPoints} points');
    }

    return null;
  }

  /// 建設物を建てた時の処理例
  ///
  /// [gameState] 現在のゲーム状態
  /// [playerId] プレイヤーID
  /// [buildingType] 建設物の種類（'settlement' または 'city'）
  void onBuildingConstructed({
    required Map<String, dynamic> gameState,
    required String playerId,
    required String buildingType,
  }) {
    // ログに記録
    final eventType = buildingType == 'settlement'
        ? GameLogEventType.buildSettlement
        : GameLogEventType.buildCity;

    _addLog(GameLogEntry(
      id: _generateLogId(),
      eventType: eventType,
      message: 'Player $playerId built a $buildingType',
      playerId: playerId,
    ));

    // 現在の勝利点を計算して表示（UIに反映する場合に使用）
    final breakdown = victoryService.calculateVictoryPoints(
      player: _getPlayer(gameState, playerId),
      players: gameState['players'] as List<dynamic>,
      vertices: gameState['vertices'] as List<dynamic>?,
      edges: gameState['edges'] as List<dynamic>?,
    );

    debugPrint(
        'Player $playerId now has ${breakdown.totalPoints} victory points');

    // 10点に到達している場合、警告ログ
    if (breakdown.hasWon) {
      debugPrint(
          'WARNING: Player $playerId has reached ${breakdown.totalPoints} points! They can win on their next turn.');
    }
  }

  /// 発展カードを使用した時の処理例
  ///
  /// [gameState] 現在のゲーム状態
  /// [playerId] プレイヤーID
  /// [cardType] カードの種類
  void onDevelopmentCardUsed({
    required Map<String, dynamic> gameState,
    required String playerId,
    required String cardType,
  }) {
    // ログに記録
    _addLog(GameLogEntry(
      id: _generateLogId(),
      eventType: GameLogEventType.useCard,
      message: 'Player $playerId used a $cardType card',
      playerId: playerId,
      data: {'cardType': cardType},
    ));

    // 騎士カードの場合、最大騎士力をチェック
    if (cardType == 'knight') {
      final breakdown = victoryService.calculateVictoryPoints(
        player: _getPlayer(gameState, playerId),
        players: gameState['players'] as List<dynamic>,
        vertices: gameState['vertices'] as List<dynamic>?,
        edges: gameState['edges'] as List<dynamic>?,
      );

      if (breakdown.largestArmyPoints > 0) {
        _addLog(GameLogEntry(
          id: _generateLogId(),
          eventType: GameLogEventType.system,
          message: 'Player $playerId has the Largest Army! (+2 points)',
          playerId: playerId,
        ));
      }
    }
  }

  /// 道路を建設した時の処理例
  ///
  /// [gameState] 現在のゲーム状態
  /// [playerId] プレイヤーID
  void onRoadConstructed({
    required Map<String, dynamic> gameState,
    required String playerId,
  }) {
    // ログに記録
    _addLog(GameLogEntry(
      id: _generateLogId(),
      eventType: GameLogEventType.buildRoad,
      message: 'Player $playerId built a road',
      playerId: playerId,
    ));

    // 最長交易路をチェック
    final breakdown = victoryService.calculateVictoryPoints(
      player: _getPlayer(gameState, playerId),
      players: gameState['players'] as List<dynamic>,
      vertices: gameState['vertices'] as List<dynamic>?,
      edges: gameState['edges'] as List<dynamic>?,
    );

    if (breakdown.longestRoadPoints > 0) {
      _addLog(GameLogEntry(
        id: _generateLogId(),
        eventType: GameLogEventType.system,
        message: 'Player $playerId has the Longest Road! (+2 points)',
        playerId: playerId,
      ));
    }
  }

  /// サイコロを振った時の処理例
  ///
  /// [diceTotal] サイコロの合計値
  /// [playerId] プレイヤーID
  void onDiceRolled({
    required int diceTotal,
    required String playerId,
  }) {
    _addLog(GameLogEntry(
      id: _generateLogId(),
      eventType: GameLogEventType.diceRoll,
      message: 'Player $playerId rolled a $diceTotal',
      playerId: playerId,
      data: {'diceTotal': diceTotal},
    ));
  }

  /// 資源を生産した時の処理例
  ///
  /// [playerId] プレイヤーID
  /// [resources] 生産した資源（Map<ResourceType, count>）
  void onResourcesProduced({
    required String playerId,
    required Map<String, int> resources,
  }) {
    if (resources.isEmpty) return;

    final resourceStr = resources.entries
        .map((e) => '${e.value}x ${e.key}')
        .join(', ');

    _addLog(GameLogEntry(
      id: _generateLogId(),
      eventType: GameLogEventType.resourceProduction,
      message: 'Player $playerId received: $resourceStr',
      playerId: playerId,
      data: {'resources': resources},
    ));
  }

  /// ゲーム状態を保存する例
  ///
  /// [gameState] 現在のゲーム状態
  /// [saveId] セーブID（オプション）
  Future<void> saveGame({
    required Map<String, dynamic> gameState,
    String? saveId,
  }) async {
    try {
      // ゲームログも一緒に保存
      gameState['gameLog'] = gameLog.map((entry) => entry.toJson()).toList();

      final metadata = await gameStateManager.saveGame(
        gameState: gameState,
        saveId: saveId,
      );

      _addLog(GameLogEntry(
        id: _generateLogId(),
        eventType: GameLogEventType.system,
        message: 'Game saved: ${metadata.id}',
      ));

      debugPrint('Game saved successfully: ${metadata.id}');
    } catch (e) {
      debugPrint('Failed to save game: $e');
      _addLog(GameLogEntry(
        id: _generateLogId(),
        eventType: GameLogEventType.system,
        message: 'Failed to save game: $e',
      ));
    }
  }

  /// ゲーム状態を読み込む例
  ///
  /// [saveId] セーブID
  ///
  /// 戻り値: ゲーム状態（存在しない場合はnull）
  Future<Map<String, dynamic>?> loadGame(String saveId) async {
    try {
      final saveData = await gameStateManager.loadGame(saveId);

      if (saveData == null) {
        debugPrint('Save not found: $saveId');
        return null;
      }

      // ゲームログを復元
      final logData = saveData.gameState['gameLog'] as List?;
      if (logData != null) {
        gameLog.clear();
        gameLog.addAll(
          logData.map((entry) => GameLogEntry.fromJson(entry as Map<String, dynamic>)),
        );
      }

      _addLog(GameLogEntry(
        id: _generateLogId(),
        eventType: GameLogEventType.system,
        message: 'Game loaded: ${saveData.metadata.id}',
      ));

      debugPrint('Game loaded successfully: $saveId');
      return saveData.gameState;
    } catch (e) {
      debugPrint('Failed to load game: $e');
      return null;
    }
  }

  /// ログエントリを追加
  void _addLog(GameLogEntry entry) {
    gameLog.add(entry);
    debugPrint('[LOG] ${entry.message}');
  }

  /// ログIDを生成
  String _generateLogId() {
    return 'log_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// プレイヤーを取得
  dynamic _getPlayer(Map<String, dynamic> gameState, String playerId) {
    final players = gameState['players'] as List<dynamic>;
    return players.firstWhere(
      (p) => (p as dynamic).id == playerId,
      orElse: () => null,
    );
  }
}

/// 使用例
///
/// ```dart
/// void exampleUsage() {
///   final integration = VictoryIntegrationExample();
///
///   // ゲーム状態（例）
///   final gameState = {
///     'turnNumber': 10,
///     'currentPlayerId': 'player1',
///     'players': [...],
///     'vertices': [...],
///     'edges': [...],
///   };
///
///   // ターン終了時の処理
///   final victoryResult = await integration.onTurnEnd(
///     gameState: gameState,
///     currentPlayerId: 'player1',
///   );
///
///   if (victoryResult != null && victoryResult.hasWinner) {
///     // 勝利画面に遷移
///     Navigator.push(
///       context,
///       MaterialPageRoute(
///         builder: (context) => GameOverScreen(
///           victoryResult: victoryResult,
///         ),
///       ),
///     );
///   }
/// }
/// ```
