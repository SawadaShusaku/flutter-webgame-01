import 'package:test_web_app/models/game_state.dart';
import 'package:test_web_app/models/player.dart';
import 'package:test_web_app/models/enums.dart';

/// ターン管理サービス
class TurnService {
  /// 次のプレイヤーに進む
  void nextTurn(GameState state) {
    state.nextPlayer();

    // イベントログに記録
    state.logEvent(GameEvent(
      timestamp: DateTime.now(),
      playerId: state.currentPlayer.id,
      type: GameEventType.diceRolled, // TODO: ターン開始イベントを追加
      data: {'turn': state.turnNumber},
    ));
  }

  /// ターン終了可能か確認
  bool canEndTurn(GameState state) {
    // 通常プレイフェーズのみターン終了可能
    if (state.phase != GamePhase.normalPlay) {
      return false;
    }

    // サイコロを振っていない場合は終了不可
    if (state.lastDiceRoll == null) {
      return false;
    }

    return true;
  }

  /// 初期配置フェーズのターン進行
  void nextSetupTurn(GameState state, {required bool isFirstRound}) {
    final playerCount = state.players.length;

    if (isFirstRound) {
      // 1巡目: 順番通り
      if (state.currentPlayerIndex < playerCount - 1) {
        state.currentPlayerIndex++;
      } else {
        // 1巡目終了、2巡目開始
        // 2巡目は逆順なので、最後のプレイヤーから
        // currentPlayerIndexはそのまま（最後のプレイヤー）
      }
    } else {
      // 2巡目: 逆順
      if (state.currentPlayerIndex > 0) {
        state.currentPlayerIndex--;
      } else {
        // 2巡目終了、通常プレイへ
        state.phase = GamePhase.normalPlay;
        state.currentPlayerIndex = 0; // 最初のプレイヤーから開始
        state.lastDiceRoll = null; // サイコロリセット
      }
    }
  }

  /// 勝利判定
  Player? checkVictory(GameState state) {
    for (var player in state.players) {
      final points = player.calculateVictoryPoints();
      player.victoryPoints = points;

      // 自分の手番で10点以上で勝利
      if (points >= 10 && state.currentPlayer.id == player.id) {
        return player;
      }
    }
    return null;
  }

  /// ゲーム開始時の初期化
  void initializeGame(GameState state) {
    // 初期配置フェーズに設定
    state.phase = GamePhase.setup;
    state.currentPlayerIndex = 0;
    state.turnNumber = 0;

    // 砂漠タイルに盗賊がいる場合、hasRobberフラグを設定
    if (state.robber != null) {
      final robberHexId = state.robber!.currentHexId;
      final robberTile = state.board.firstWhere(
        (tile) => tile.id == robberHexId,
        orElse: () => state.board.firstWhere(
          (tile) => tile.terrain == TerrainType.desert,
        ),
      );
      robberTile.hasRobber = true;
    }

    // 開始ログ
    state.logEvent(GameEvent(
      timestamp: DateTime.now(),
      playerId: state.currentPlayer.id,
      type: GameEventType.diceRolled, // TODO: ゲーム開始イベント
      data: {'message': 'ゲーム開始'},
    ));
  }
}
