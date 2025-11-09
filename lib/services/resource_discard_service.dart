import 'package:test_web_app/models/game_state.dart';
import 'package:test_web_app/models/player.dart';
import 'package:test_web_app/models/enums.dart';

/// 資源破棄フェーズ管理サービス
/// 7が出た時に、8枚以上所持するプレイヤーが半分破棄する処理を担当
class ResourceDiscardService {
  /// 資源破棄が必要なプレイヤーを取得
  /// 8枚以上所持しているプレイヤーが対象
  List<Player> getPlayersNeedingDiscard(GameState state) {
    return state.players.where((p) {
      final total = p.resources.values.fold(0, (a, b) => a + b);
      return total >= 8;
    }).toList();
  }

  /// 破棄すべき枚数を計算（総数の半分、切り捨て）
  int getDiscardCount(Player player) {
    final total = player.resources.values.fold(0, (a, b) => a + b);
    return total ~/ 2;
  }

  /// 資源を破棄
  bool discardResources(Player player, Map<ResourceType, int> resourcesToDiscard) {
    // バリデーション: 指定枚数が正しいか
    final totalDiscard = resourcesToDiscard.values.fold(0, (a, b) => a + b);
    final requiredDiscard = getDiscardCount(player);
    if (totalDiscard != requiredDiscard) return false;

    // バリデーション: 所持数を超えていないか
    for (final entry in resourcesToDiscard.entries) {
      if (player.resources[entry.key]! < entry.value) return false;
    }

    // 破棄実行
    for (final entry in resourcesToDiscard.entries) {
      player.resources[entry.key] = player.resources[entry.key]! - entry.value;
    }

    return true;
  }
}
