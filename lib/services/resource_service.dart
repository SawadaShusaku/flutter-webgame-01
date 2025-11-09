// modelsからimport
import '../models/player.dart';
import '../models/hex_tile.dart';
import '../models/vertex.dart';
import '../models/game_state.dart';
import '../models/enums.dart';

/// 資源管理サービス
/// - 資源の配布ロジック
/// - サイコロの目に応じた資源生産
/// - 資源の譲渡・交換処理
class ResourceService {
  /// サイコロの目に応じて資源を配布
  ///
  /// [diceTotal] サイコロの合計値
  /// [gameState] ゲーム状態
  ///
  /// 戻り値: 各プレイヤーが獲得した資源のマップ
  Map<String, Map<ResourceType, int>> distributeResources(
    int diceTotal,
    GameState gameState,
  ) {
    final resourcesGained = <String, Map<ResourceType, int>>{};

    // プレイヤーごとの資源獲得マップを初期化
    for (final player in gameState.players) {
      resourcesGained[player.id] = {
        for (final resourceType in ResourceType.values) resourceType: 0,
      };
    }

    // 7が出た場合は資源配布なし（盗賊イベント）
    if (diceTotal == 7) {
      return resourcesGained;
    }

    // サイコロの目に一致するタイルを探す
    for (final hexTile in gameState.board) {
      // 数字チップが一致し、盗賊がいないタイル
      if (hexTile.number == diceTotal && !hexTile.hasRobber) {
        final resourceType = hexTile.resourceType;
        if (resourceType == null) continue; // 砂漠は資源なし

        // このタイルに隣接する頂点を探す
        for (final vertex in gameState.vertices) {
          if (vertex.adjacentHexIds.contains(hexTile.id) && vertex.hasBuilding) {
            final building = vertex.building!;
            final playerId = building.playerId;

            // 集落は1枚、都市は2枚の資源を獲得
            final amount = building.type == BuildingType.settlement ? 1 : 2;

            resourcesGained[playerId]![resourceType] =
                (resourcesGained[playerId]![resourceType] ?? 0) + amount;
          }
        }
      }
    }

    // プレイヤーに資源を実際に追加
    for (final player in gameState.players) {
      final gained = resourcesGained[player.id]!;
      for (final entry in gained.entries) {
        if (entry.value > 0) {
          player.addResource(entry.key, entry.value);
        }
      }
    }

    return resourcesGained;
  }

  /// 初期配置時の資源配布
  /// 2巡目の集落配置時に、その集落周辺のタイルから資源を1枚ずつ獲得
  ///
  /// [vertexId] 集落を配置した頂点のID
  /// [player] プレイヤー
  /// [gameState] ゲーム状態
  void distributeInitialResources(
    String vertexId,
    Player player,
    GameState gameState,
  ) {
    final vertex = gameState.vertices.firstWhere((v) => v.id == vertexId);

    // この頂点に隣接するタイルから資源を獲得
    for (final hexId in vertex.adjacentHexIds) {
      final hexTile = gameState.board.firstWhere((h) => h.id == hexId);
      final resourceType = hexTile.resourceType;

      if (resourceType != null) {
        player.addResource(resourceType, 1);
      }
    }
  }

  /// 銀行取引（4:1レート）
  ///
  /// [player] プレイヤー
  /// [giving] 渡す資源
  /// [receiving] 受け取る資源
  ///
  /// 戻り値: 取引が成功したかどうか
  bool bankTrade(
    Player player,
    ResourceType giving,
    ResourceType receiving,
  ) {
    // 4枚の資源を持っているか確認
    if (!player.hasResources({giving: 4})) {
      return false;
    }

    // 取引実行
    player.removeResource(giving, 4);
    player.addResource(receiving, 1);

    return true;
  }

  /// 港取引（3:1または2:1レート）
  ///
  /// [player] プレイヤー
  /// [giving] 渡す資源
  /// [receiving] 受け取る資源
  /// [rate] 取引レート（2または3）
  ///
  /// 戻り値: 取引が成功したかどうか
  bool harborTrade(
    Player player,
    ResourceType giving,
    ResourceType receiving,
    int rate,
  ) {
    assert(rate == 2 || rate == 3, '港取引レートは2または3である必要があります');

    // 必要な資源を持っているか確認
    if (!player.hasResources({giving: rate})) {
      return false;
    }

    // 取引実行
    player.removeResource(giving, rate);
    player.addResource(receiving, 1);

    return true;
  }

  /// プレイヤー間の資源交換
  ///
  /// [proposer] 提案者
  /// [target] 交渉相手
  /// [offering] 提供する資源
  /// [requesting] 要求する資源
  ///
  /// 戻り値: 交換が成功したかどうか
  bool playerTrade(
    Player proposer,
    Player target,
    Map<ResourceType, int> offering,
    Map<ResourceType, int> requesting,
  ) {
    // 両者とも必要な資源を持っているか確認
    if (!proposer.hasResources(offering)) {
      return false;
    }
    if (!target.hasResources(requesting)) {
      return false;
    }

    // 提案者が資源を渡す
    for (final entry in offering.entries) {
      if (entry.value > 0) {
        proposer.removeResource(entry.key, entry.value);
        target.addResource(entry.key, entry.value);
      }
    }

    // 相手が資源を渡す
    for (final entry in requesting.entries) {
      if (entry.value > 0) {
        target.removeResource(entry.key, entry.value);
        proposer.addResource(entry.key, entry.value);
      }
    }

    return true;
  }

  /// 7が出た時の資源破棄処理
  /// 8枚以上の資源を持っているプレイヤーは半分（切り捨て）を捨てる
  ///
  /// [player] プレイヤー
  /// [resourcesToDiscard] 破棄する資源
  ///
  /// 戻り値: 破棄が成功したかどうか
  bool discardResources(
    Player player,
    Map<ResourceType, int> resourcesToDiscard,
  ) {
    final totalResources = player.totalResources;

    // 8枚未満の場合は破棄不要
    if (totalResources < 8) {
      return false;
    }

    // 破棄する枚数が正しいか確認（総数の半分、切り捨て）
    final requiredDiscardCount = totalResources ~/ 2;
    final discardCount = resourcesToDiscard.values.fold(0, (sum, count) => sum + count);

    if (discardCount != requiredDiscardCount) {
      return false;
    }

    // 資源を持っているか確認
    if (!player.hasResources(resourcesToDiscard)) {
      return false;
    }

    // 破棄実行
    for (final entry in resourcesToDiscard.entries) {
      if (entry.value > 0) {
        player.removeResource(entry.key, entry.value);
      }
    }

    return true;
  }

  /// 盗賊による資源強奪
  /// ランダムに1枚の資源を奪う
  ///
  /// [victim] 奪われるプレイヤー
  /// [robber] 奪うプレイヤー
  ///
  /// 戻り値: 奪った資源のタイプ（資源がない場合はnull）
  ResourceType? stealResource(Player victim, Player robber) {
    final availableResources = <ResourceType>[];

    // 所持している資源をリストアップ
    for (final entry in victim.resources.entries) {
      for (int i = 0; i < entry.value; i++) {
        availableResources.add(entry.key);
      }
    }

    // 資源がない場合
    if (availableResources.isEmpty) {
      return null;
    }

    // ランダムに1枚選択
    availableResources.shuffle();
    final stolenResource = availableResources.first;

    // 資源を移動
    victim.removeResource(stolenResource, 1);
    robber.addResource(stolenResource, 1);

    return stolenResource;
  }

  /// 建設に必要な資源を確認
  ///
  /// [type] 建設物のタイプまたは"road"、"development_card"
  ///
  /// 戻り値: 必要な資源のマップ
  Map<ResourceType, int> getRequiredResources(String type) {
    switch (type) {
      case 'road':
        return {
          ResourceType.lumber: 1,
          ResourceType.brick: 1,
        };
      case 'settlement':
        return {
          ResourceType.lumber: 1,
          ResourceType.brick: 1,
          ResourceType.wool: 1,
          ResourceType.grain: 1,
        };
      case 'city':
        return {
          ResourceType.grain: 2,
          ResourceType.ore: 3,
        };
      case 'development_card':
        return {
          ResourceType.wool: 1,
          ResourceType.grain: 1,
          ResourceType.ore: 1,
        };
      default:
        return {};
    }
  }

  /// 建設コストを支払う
  ///
  /// [player] プレイヤー
  /// [type] 建設物のタイプ
  ///
  /// 戻り値: 支払いが成功したかどうか
  bool payBuildingCost(Player player, String type) {
    final required = getRequiredResources(type);

    if (!player.hasResources(required)) {
      return false;
    }

    // コストを支払う
    for (final entry in required.entries) {
      player.removeResource(entry.key, entry.value);
    }

    return true;
  }
}
