import 'package:test_web_app/models/game_state.dart';
import 'package:test_web_app/models/player.dart';

/// 勝利点計算サービス
class VictoryPointService {
  /// プレイヤーの勝利点を計算
  ///
  /// 計算対象:
  /// - 集落: 1点/個
  /// - 都市: 2点/個
  ///
  /// 計算対象外（今回のMVPでは未実装）:
  /// - 最長交易路: 2点
  /// - 最大騎士力: 2点
  /// - 発展カード（勝利点）: 1点/枚
  int calculateVictoryPoints(GameState state, Player player) {
    int points = 0;

    // 集落（1点）
    points += player.settlementsBuilt * 1;

    // 都市（2点）
    points += player.citiesBuilt * 2;

    // MVP未実装: 最長交易路、最大騎士力、発展カードの勝利点
    // これらは将来の拡張として実装される

    return points;
  }

  /// 全プレイヤーの勝利点を再計算
  void updateAllVictoryPoints(GameState state) {
    for (final player in state.players) {
      player.victoryPoints = calculateVictoryPoints(state, player);
    }
  }

  /// 勝利条件を満たしているかチェック
  /// 10勝利点以上で勝利
  bool checkVictoryCondition(Player player) {
    return player.victoryPoints >= 10;
  }

  /// 勝者を取得（いない場合はnull）
  Player? getWinner(GameState state) {
    for (final player in state.players) {
      if (checkVictoryCondition(player)) {
        return player;
      }
    }
    return null;
  }
}
