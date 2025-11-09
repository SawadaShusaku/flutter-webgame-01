import 'package:flutter/material.dart';
import 'dart:math';
import '../models/game_state.dart';

class GameController extends ChangeNotifier {
  late GameState _state;

  GameController() {
    _initializeGame();
  }

  GameState get state => _state;
  Player get currentPlayer => _state.currentPlayer;
  bool get hasRolledDice => _state.hasRolledDice;
  int? get lastDiceRoll => _state.lastDiceRoll;
  List<String> get gameLog => _state.gameLog;

  void _initializeGame() {
    _state = GameState(
      players: [
        Player(id: '1', name: 'プレイヤー1', color: Colors.red),
        Player(id: '2', name: 'プレイヤー2', color: Colors.blue),
        Player(id: '3', name: 'プレイヤー3', color: Colors.green),
        Player(id: '4', name: 'プレイヤー4', color: Colors.orange),
      ],
      phase: GamePhase.setup,
    );
    _state.addLog('ゲームを開始しました');
  }

  /// 初期配置完了後、通常プレイへ移行
  void startNormalPlay() {
    _state.phase = GamePhase.normalPlay;
    _state.currentPlayerIndex = 0;
    _state.turnNumber = 1;
    _state.addLog('通常プレイを開始します');
    notifyListeners();
  }

  /// サイコロを振る
  void rollDice() {
    if (_state.hasRolledDice) return;

    final random = Random();
    final dice1 = random.nextInt(6) + 1;
    final dice2 = random.nextInt(6) + 1;
    final total = dice1 + dice2;

    _state.lastDiceRoll = total;
    _state.hasRolledDice = true;

    _state.addLog('${currentPlayer.name}がサイコロを振りました: $dice1 + $dice2 = $total');

    // 資源を配布（簡易実装）
    if (total != 7) {
      _distributeResources(total);
    } else {
      _state.addLog('盗賊が現れました！');
    }

    notifyListeners();
  }

  void _distributeResources(int diceNumber) {
    // 簡易実装：ランダムに資源を配布
    final resourceTypes = ['木材', 'レンガ', '羊毛', '小麦', '鉱石'];
    final random = Random();

    for (var player in _state.players) {
      if (random.nextBool()) {
        final resourceType = resourceTypes[random.nextInt(resourceTypes.length)];
        player.resources[resourceType] = (player.resources[resourceType] ?? 0) + 1;
        _state.addLog('${player.name}が$resourceTypeを獲得');
      }
    }
  }

  /// 集落を建設
  void buildSettlement() {
    if (!_canBuildSettlement()) return;

    currentPlayer.resources['木材'] = currentPlayer.resources['木材']! - 1;
    currentPlayer.resources['レンガ'] = currentPlayer.resources['レンガ']! - 1;
    currentPlayer.resources['羊毛'] = currentPlayer.resources['羊毛']! - 1;
    currentPlayer.resources['小麦'] = currentPlayer.resources['小麦']! - 1;

    currentPlayer.victoryPoints += 1;

    _state.addLog('${currentPlayer.name}が集落を建設しました');
    notifyListeners();
  }

  bool _canBuildSettlement() {
    return currentPlayer.resources['木材']! >= 1 &&
           currentPlayer.resources['レンガ']! >= 1 &&
           currentPlayer.resources['羊毛']! >= 1 &&
           currentPlayer.resources['小麦']! >= 1;
  }

  /// 都市を建設
  void buildCity() {
    if (!_canBuildCity()) return;

    currentPlayer.resources['小麦'] = currentPlayer.resources['小麦']! - 2;
    currentPlayer.resources['鉱石'] = currentPlayer.resources['鉱石']! - 3;

    currentPlayer.victoryPoints += 1; // 集落から都市への昇格で+1

    _state.addLog('${currentPlayer.name}が都市を建設しました');
    notifyListeners();
  }

  bool _canBuildCity() {
    return currentPlayer.resources['小麦']! >= 2 &&
           currentPlayer.resources['鉱石']! >= 3;
  }

  /// 道路を建設
  void buildRoad() {
    if (!_canBuildRoad()) return;

    currentPlayer.resources['木材'] = currentPlayer.resources['木材']! - 1;
    currentPlayer.resources['レンガ'] = currentPlayer.resources['レンガ']! - 1;

    _state.addLog('${currentPlayer.name}が道路を建設しました');
    notifyListeners();
  }

  bool _canBuildRoad() {
    return currentPlayer.resources['木材']! >= 1 &&
           currentPlayer.resources['レンガ']! >= 1;
  }

  /// 建設可能かチェック
  bool canBuildSettlement() => _canBuildSettlement();
  bool canBuildCity() => _canBuildCity();
  bool canBuildRoad() => _canBuildRoad();

  /// ターン終了
  void endTurn() {
    _state.addLog('${currentPlayer.name}のターンが終了しました');
    _state.nextPlayer();
    _state.addLog('${currentPlayer.name}のターンです');

    // 勝利条件チェック
    if (currentPlayer.victoryPoints >= 10) {
      _state.phase = GamePhase.gameOver;
      _state.addLog('${currentPlayer.name}が勝利しました！');
    }

    notifyListeners();
  }

  /// デバッグ用：資源を追加
  void addDebugResources() {
    for (var resourceType in currentPlayer.resources.keys) {
      currentPlayer.resources[resourceType] =
          (currentPlayer.resources[resourceType] ?? 0) + 2;
    }
    _state.addLog('${currentPlayer.name}に資源を追加しました（デバッグ）');
    notifyListeners();
  }
}
