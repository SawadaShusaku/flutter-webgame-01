import 'dart:math';
import 'package:flutter/foundation.dart';

/// サイコロを振る結果
class DiceRollResult {
  final int die1;
  final int die2;
  final DateTime timestamp;

  DiceRollResult({
    required this.die1,
    required this.die2,
    DateTime? timestamp,
  })  : assert(die1 >= 1 && die1 <= 6, 'サイコロの目は1-6です'),
        assert(die2 >= 1 && die2 <= 6, 'サイコロの目は1-6です'),
        timestamp = timestamp ?? DateTime.now();

  /// 合計値（2-12）
  int get total => die1 + die2;

  /// 7が出たか
  bool get isSeven => total == 7;

  @override
  String toString() => 'DiceRollResult(die1: $die1, die2: $die2, total: $total)';
}

/// サイコロの状態
enum DiceState {
  idle,      // 待機中
  rolling,   // 振っている最中
  finished,  // 振り終わった
}

/// サイコロサービス
/// サイコロを振る機能とアニメーション用の状態管理を提供
class DiceService extends ChangeNotifier {
  final Random _random = Random();

  DiceState _state = DiceState.idle;
  DiceRollResult? _lastRoll;

  /// 現在のサイコロの状態
  DiceState get state => _state;

  /// 最後のロール結果
  DiceRollResult? get lastRoll => _lastRoll;

  /// サイコロを振っているか
  bool get isRolling => _state == DiceState.rolling;

  /// サイコロを振る
  ///
  /// [duration] アニメーション時間（デフォルト: 1秒）
  /// 戻り値: サイコロの結果
  Future<DiceRollResult> rollDice({
    Duration duration = const Duration(milliseconds: 1000),
  }) async {
    if (_state == DiceState.rolling) {
      throw Exception('サイコロは既に振られています');
    }

    // 状態を「振っている最中」に変更
    _state = DiceState.rolling;
    notifyListeners();

    // アニメーション時間待機
    await Future.delayed(duration);

    // サイコロの目を生成（1-6）
    final die1 = _random.nextInt(6) + 1;
    final die2 = _random.nextInt(6) + 1;

    // 結果を保存
    _lastRoll = DiceRollResult(die1: die1, die2: die2);

    // 状態を「完了」に変更
    _state = DiceState.finished;
    notifyListeners();

    return _lastRoll!;
  }

  /// サイコロをリセット（次のロールの準備）
  void reset() {
    _state = DiceState.idle;
    notifyListeners();
  }

  /// 特定の目を出す（テスト用）
  Future<DiceRollResult> rollWithValues(
    int die1,
    int die2, {
    Duration duration = const Duration(milliseconds: 1000),
  }) async {
    if (_state == DiceState.rolling) {
      throw Exception('サイコロは既に振られています');
    }

    assert(die1 >= 1 && die1 <= 6, 'サイコロの目は1-6です');
    assert(die2 >= 1 && die2 <= 6, 'サイコロの目は1-6です');

    // 状態を「振っている最中」に変更
    _state = DiceState.rolling;
    notifyListeners();

    // アニメーション時間待機
    await Future.delayed(duration);

    // 結果を保存
    _lastRoll = DiceRollResult(die1: die1, die2: die2);

    // 状態を「完了」に変更
    _state = DiceState.finished;
    notifyListeners();

    return _lastRoll!;
  }

  /// サイコロの履歴をクリア
  void clearHistory() {
    _lastRoll = null;
    _state = DiceState.idle;
    notifyListeners();
  }
}
