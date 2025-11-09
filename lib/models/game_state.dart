import 'package:flutter/material.dart';

/// ゲームフェーズ
enum GamePhase {
  setup,       // 初期配置
  normalPlay,  // 通常プレイ
  gameOver,    // ゲーム終了
}

/// プレイヤー情報
class Player {
  final String id;
  final String name;
  final Color color;
  int victoryPoints;
  Map<String, int> resources;

  Player({
    required this.id,
    required this.name,
    required this.color,
    this.victoryPoints = 0,
    Map<String, int>? resources,
  }) : resources = resources ?? {
    '木材': 0,
    'レンガ': 0,
    '羊毛': 0,
    '小麦': 0,
    '鉱石': 0,
  };

  /// 総資源数
  int get totalResources => resources.values.fold(0, (sum, count) => sum + count);
}

/// ゲーム状態
class GameState {
  final List<Player> players;
  int currentPlayerIndex;
  int turnNumber;
  GamePhase phase;
  bool hasRolledDice;
  int? lastDiceRoll;
  List<String> gameLog;

  GameState({
    required this.players,
    this.currentPlayerIndex = 0,
    this.turnNumber = 1,
    this.phase = GamePhase.setup,
    this.hasRolledDice = false,
    this.lastDiceRoll,
    List<String>? gameLog,
  }) : gameLog = gameLog ?? [];

  Player get currentPlayer => players[currentPlayerIndex];

  /// 次のプレイヤーへ
  void nextPlayer() {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    hasRolledDice = false;
    lastDiceRoll = null;

    if (currentPlayerIndex == 0) {
      turnNumber++;
    }
  }

  /// ログを追加
  void addLog(String message) {
    final timestamp = 'T$turnNumber';
    gameLog.insert(0, '[$timestamp] $message');

    // ログが多すぎる場合は古いものを削除
    if (gameLog.length > 50) {
      gameLog = gameLog.sublist(0, 50);
    }
  }

  /// コピーを作成
  GameState copyWith({
    List<Player>? players,
    int? currentPlayerIndex,
    int? turnNumber,
    GamePhase? phase,
    bool? hasRolledDice,
    int? lastDiceRoll,
    List<String>? gameLog,
  }) {
    return GameState(
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      turnNumber: turnNumber ?? this.turnNumber,
      phase: phase ?? this.phase,
      hasRolledDice: hasRolledDice ?? this.hasRolledDice,
      lastDiceRoll: lastDiceRoll ?? this.lastDiceRoll,
      gameLog: gameLog ?? List.from(this.gameLog),
    );
  }
}
