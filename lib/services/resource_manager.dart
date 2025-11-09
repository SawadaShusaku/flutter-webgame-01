// modelsからimport
import '../models/player.dart';
import '../models/enums.dart';

/// 資源管理サービス
///
/// プレイヤーの資源の消費・追加・チェックを管理します。
/// resource_service.dartとは異なり、純粋な資源操作のみを扱います。
class ResourceManager {
  /// 資源を消費する
  ///
  /// [player] プレイヤー
  /// [resources] 消費する資源のマップ
  ///
  /// 戻り値: 消費に成功したかどうか
  ///
  /// 例外:
  /// - 資源が不足している場合、消費は行われず false を返す
  bool consumeResources(Player player, Map<ResourceType, int> resources) {
    // まず資源が十分にあるかチェック
    if (!hasEnoughResources(player, resources)) {
      return false;
    }

    // 資源を消費
    for (final entry in resources.entries) {
      if (entry.value > 0) {
        final success = player.removeResource(entry.key, entry.value);
        if (!success) {
          // これは通常起こらないはずだが、安全のため
          _rollbackConsumption(player, resources, entry.key);
          return false;
        }
      }
    }

    return true;
  }

  /// 資源を追加する
  ///
  /// [player] プレイヤー
  /// [resources] 追加する資源のマップ
  void addResources(Player player, Map<ResourceType, int> resources) {
    for (final entry in resources.entries) {
      if (entry.value > 0) {
        player.addResource(entry.key, entry.value);
      }
    }
  }

  /// 単一の資源を追加する
  ///
  /// [player] プレイヤー
  /// [resourceType] 資源タイプ
  /// [amount] 数量
  void addResource(Player player, ResourceType resourceType, int amount) {
    if (amount > 0) {
      player.addResource(resourceType, amount);
    }
  }

  /// 単一の資源を消費する
  ///
  /// [player] プレイヤー
  /// [resourceType] 資源タイプ
  /// [amount] 数量
  ///
  /// 戻り値: 消費に成功したかどうか
  bool consumeResource(Player player, ResourceType resourceType, int amount) {
    if (amount <= 0) {
      return true; // 0以下の場合は成功とみなす
    }

    if (!hasEnoughResource(player, resourceType, amount)) {
      return false;
    }

    return player.removeResource(resourceType, amount);
  }

  /// 十分な資源を持っているかチェック
  ///
  /// [player] プレイヤー
  /// [required] 必要な資源のマップ
  ///
  /// 戻り値: 十分な資源を持っているか
  bool hasEnoughResources(Player player, Map<ResourceType, int> required) {
    return player.hasResources(required);
  }

  /// 単一の資源を十分に持っているかチェック
  ///
  /// [player] プレイヤー
  /// [resourceType] 資源タイプ
  /// [amount] 必要な数量
  ///
  /// 戻り値: 十分に持っているか
  bool hasEnoughResource(
    Player player,
    ResourceType resourceType,
    int amount,
  ) {
    final currentAmount = player.resources[resourceType] ?? 0;
    return currentAmount >= amount;
  }

  /// プレイヤーの資源総数を取得
  ///
  /// [player] プレイヤー
  ///
  /// 戻り値: 資源の総数
  int getTotalResourceCount(Player player) {
    return player.totalResources;
  }

  /// 特定の資源タイプの所持数を取得
  ///
  /// [player] プレイヤー
  /// [resourceType] 資源タイプ
  ///
  /// 戻り値: 所持数
  int getResourceCount(Player player, ResourceType resourceType) {
    return player.resources[resourceType] ?? 0;
  }

  /// 資源を全て削除（テスト用）
  ///
  /// [player] プレイヤー
  void clearAllResources(Player player) {
    for (final resourceType in ResourceType.values) {
      player.resources[resourceType] = 0;
    }
  }

  /// 資源の消費をロールバック（内部使用）
  ///
  /// [player] プレイヤー
  /// [resources] 消費しようとした資源
  /// [failedAt] 失敗した資源タイプ
  void _rollbackConsumption(
    Player player,
    Map<ResourceType, int> resources,
    ResourceType failedAt,
  ) {
    // 失敗した資源の前までロールバック
    for (final entry in resources.entries) {
      if (entry.key == failedAt) {
        break;
      }
      if (entry.value > 0) {
        player.addResource(entry.key, entry.value);
      }
    }
  }

  /// 資源の差分を計算
  ///
  /// [current] 現在の資源
  /// [target] 目標の資源
  ///
  /// 戻り値: 不足している資源のマップ（正の値）
  Map<ResourceType, int> calculateResourceDeficit(
    Map<ResourceType, int> current,
    Map<ResourceType, int> target,
  ) {
    final deficit = <ResourceType, int>{};

    for (final entry in target.entries) {
      final currentAmount = current[entry.key] ?? 0;
      final targetAmount = entry.value;
      final difference = targetAmount - currentAmount;

      if (difference > 0) {
        deficit[entry.key] = difference;
      }
    }

    return deficit;
  }

  /// 資源が不足しているかチェック
  ///
  /// [player] プレイヤー
  /// [required] 必要な資源
  ///
  /// 戻り値: 不足している資源のマップ（空なら十分）
  Map<ResourceType, int> getMissingResources(
    Player player,
    Map<ResourceType, int> required,
  ) {
    return calculateResourceDeficit(player.resources, required);
  }

  /// 資源を交換する（プレイヤー間取引用）
  ///
  /// [fromPlayer] 資源を渡すプレイヤー
  /// [toPlayer] 資源を受け取るプレイヤー
  /// [fromResources] 渡す資源
  /// [toResources] 受け取る資源
  ///
  /// 戻り値: 交換に成功したかどうか
  bool exchangeResources(
    Player fromPlayer,
    Player toPlayer,
    Map<ResourceType, int> fromResources,
    Map<ResourceType, int> toResources,
  ) {
    // 両者とも十分な資源を持っているかチェック
    if (!hasEnoughResources(fromPlayer, fromResources)) {
      return false;
    }
    if (!hasEnoughResources(toPlayer, toResources)) {
      return false;
    }

    // fromPlayerから資源を消費
    if (!consumeResources(fromPlayer, fromResources)) {
      return false;
    }

    // toPlayerに資源を追加
    addResources(fromPlayer, toResources);

    // toPlayerから資源を消費
    if (!consumeResources(toPlayer, toResources)) {
      // ロールバック
      addResources(fromPlayer, fromResources);
      consumeResources(fromPlayer, toResources);
      return false;
    }

    // fromPlayerに資源を追加
    addResources(toPlayer, fromResources);

    return true;
  }

  /// 銀行取引（N:1交換）
  ///
  /// [player] プレイヤー
  /// [giving] 渡す資源タイプ
  /// [givingAmount] 渡す数量
  /// [receiving] 受け取る資源タイプ
  /// [receivingAmount] 受け取る数量（通常は1）
  ///
  /// 戻り値: 取引に成功したかどうか
  bool bankTrade(
    Player player,
    ResourceType giving,
    int givingAmount,
    ResourceType receiving,
    int receivingAmount,
  ) {
    // 渡す資源を持っているかチェック
    if (!hasEnoughResource(player, giving, givingAmount)) {
      return false;
    }

    // 資源を消費
    if (!consumeResource(player, giving, givingAmount)) {
      return false;
    }

    // 資源を追加
    addResource(player, receiving, receivingAmount);

    return true;
  }
}
