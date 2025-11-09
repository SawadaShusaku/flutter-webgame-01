import 'dart:math';
import 'package:test_web_app/models/game_state.dart';
import 'package:test_web_app/models/player.dart';
import 'package:test_web_app/models/enums.dart';

/// 盗賊システムを管理するサービス
/// - 盗賊の移動
/// - 隣接プレイヤーの取得
/// - 資源の強奪
class RobberService {
  /// 盗賊を移動
  ///
  /// @param state ゲーム状態
  /// @param hexId 移動先タイルID
  /// @return 移動成功したらtrue
  bool moveRobber(GameState state, String hexId) {
    // 現在と同じタイルには移動できない
    if (state.robber?.currentHexId == hexId) return false;

    // 盗賊を移動
    if (state.robber != null) {
      state.robber!.moveTo(hexId);
    }

    return true;
  }

  /// 指定タイルに隣接するプレイヤーを取得
  ///
  /// 手番プレイヤー以外で、そのタイルに建設物を持つプレイヤー
  ///
  /// @param state ゲーム状態
  /// @param hexId タイルID
  /// @param currentPlayer 手番プレイヤー
  /// @return 隣接プレイヤーのリスト
  List<Player> getAdjacentPlayers(GameState state, String hexId, Player currentPlayer) {
    final adjacentPlayers = <Player>[];

    // そのタイルの頂点を取得
    final adjacentVertices = state.vertices.where((v) =>
      v.adjacentHexIds.contains(hexId)
    );

    for (final vertex in adjacentVertices) {
      if (vertex.building != null && vertex.building!.playerId != currentPlayer.id) {
        final player = state.players.firstWhere((p) => p.id == vertex.building!.playerId);
        if (!adjacentPlayers.contains(player)) {
          adjacentPlayers.add(player);
        }
      }
    }

    return adjacentPlayers;
  }

  /// ランダムに資源を1枚奪う
  ///
  /// 資源がない場合はnullを返す
  ///
  /// @param targetPlayer 奪う対象プレイヤー
  /// @return 奪った資源タイプ（資源がない場合はnull）
  ResourceType? stealResource(Player targetPlayer) {
    // 所持資源のリストを作成
    final availableResources = <ResourceType>[];
    for (final entry in targetPlayer.resources.entries) {
      for (int i = 0; i < entry.value; i++) {
        availableResources.add(entry.key);
      }
    }

    if (availableResources.isEmpty) return null;

    // ランダムに1枚選択
    final random = Random();
    final stolenResource = availableResources[random.nextInt(availableResources.length)];

    // 資源を減らす
    targetPlayer.resources[stolenResource] = targetPlayer.resources[stolenResource]! - 1;

    return stolenResource;
  }
}
