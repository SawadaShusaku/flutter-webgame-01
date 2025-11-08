import 'package:flutter/foundation.dart';

/// 資源破棄サービス
///
/// 7が出た時の資源破棄処理を管理
///
/// ルール:
/// - 資源を8枚以上持っているプレイヤーは半分（切り捨て）を破棄
/// - プレイヤーが破棄する資源を選択
class DiscardService extends ChangeNotifier {
  /// 資源を8枚以上持っているプレイヤーを検出
  ///
  /// [players] プレイヤーのリスト
  ///
  /// 戻り値: 破棄が必要なプレイヤーのIDと破棄枚数のマップ
  Map<String, int> getPlayersNeedingDiscard(List<dynamic> players) {
    final playersNeedingDiscard = <String, int>{};

    try {
      for (final player in players) {
        final totalResources = _getTotalResources(player);
        final playerId = _getProperty(player, 'id') as String?;

        if (totalResources >= 8 && playerId != null) {
          final discardCount = totalResources ~/ 2; // 切り捨て除算
          playersNeedingDiscard[playerId] = discardCount;
        }
      }
    } catch (e) {
      debugPrint('Error getting players needing discard: $e');
    }

    return playersNeedingDiscard;
  }

  /// プレイヤーが破棄すべき資源数を計算
  ///
  /// [player] プレイヤーオブジェクト
  ///
  /// 戻り値: 破棄する資源数（総資源数の半分、切り捨て）
  int getDiscardCount(dynamic player) {
    final totalResources = _getTotalResources(player);
    return totalResources ~/ 2; // 切り捨て除算
  }

  /// 資源を破棄
  ///
  /// [player] プレイヤーオブジェクト
  /// [resourcesToDiscard] 破棄する資源のマップ（ResourceType → count）
  ///
  /// 戻り値: 破棄に成功したかどうか
  ///
  /// 検証:
  /// - 破棄する資源の合計が必要な枚数と一致するか
  /// - プレイヤーがその資源を持っているか
  bool discardResources(
    dynamic player,
    Map<dynamic, int> resourcesToDiscard,
  ) {
    try {
      final requiredDiscardCount = getDiscardCount(player);

      // 破棄する資源の合計を計算
      final totalDiscard =
          resourcesToDiscard.values.fold<int>(0, (sum, count) => sum + count);

      // 必要な枚数と一致するか確認
      if (totalDiscard != requiredDiscardCount) {
        debugPrint(
            'Discard count mismatch: expected $requiredDiscardCount, got $totalDiscard');
        return false;
      }

      // プレイヤーが各資源を持っているか確認
      final playerResources = _getProperty(player, 'resources') as Map? ?? {};

      for (final entry in resourcesToDiscard.entries) {
        final resourceType = entry.key;
        final discardCount = entry.value;

        final currentCount = playerResources[resourceType] as int? ?? 0;

        if (currentCount < discardCount) {
          debugPrint(
              'Player does not have enough resources: $resourceType (has $currentCount, trying to discard $discardCount)');
          return false;
        }
      }

      // 資源を破棄
      for (final entry in resourcesToDiscard.entries) {
        final resourceType = entry.key;
        final discardCount = entry.value;

        _callMethod(player, 'removeResource', [resourceType, discardCount]);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error discarding resources: $e');
      return false;
    }
  }

  /// プレイヤーの資源情報を取得
  ///
  /// [player] プレイヤーオブジェクト
  ///
  /// 戻り値: 資源タイプ名と枚数のマップ
  Map<String, int> getPlayerResources(dynamic player) {
    final resourceMap = <String, int>{};

    try {
      final resources = _getProperty(player, 'resources') as Map? ?? {};

      for (final entry in resources.entries) {
        final resourceTypeName = _extractResourceTypeName(entry.key.toString());
        final count = entry.value as int? ?? 0;

        if (count > 0) {
          resourceMap[resourceTypeName] = count;
        }
      }
    } catch (e) {
      debugPrint('Error getting player resources: $e');
    }

    return resourceMap;
  }

  /// 破棄が完了したかを確認
  ///
  /// [players] プレイヤーのリスト
  ///
  /// 戻り値: 全てのプレイヤーが破棄を完了したかどうか
  bool isDiscardPhaseComplete(List<dynamic> players) {
    final playersNeedingDiscard = getPlayersNeedingDiscard(players);
    return playersNeedingDiscard.isEmpty;
  }

  // ===== ヘルパーメソッド =====

  /// プレイヤーの総資源数を取得
  int _getTotalResources(dynamic player) {
    try {
      final resources = _getProperty(player, 'resources') as Map? ?? {};
      int total = 0;
      for (final value in resources.values) {
        if (value is int) {
          total += value;
        }
      }
      return total;
    } catch (e) {
      debugPrint('Error getting total resources: $e');
      return 0;
    }
  }

  /// 資源タイプ名を抽出（"ResourceType.lumber" → "lumber"）
  String _extractResourceTypeName(String resourceTypeString) {
    final parts = resourceTypeString.split('.');
    return parts.length > 1 ? parts[1] : resourceTypeString;
  }

  /// オブジェクトのプロパティを取得
  dynamic _getProperty(dynamic object, String propertyName) {
    if (object == null) return null;

    try {
      switch (propertyName) {
        case 'id':
          return object.id;
        case 'resources':
          return object.resources;
        default:
          return null;
      }
    } catch (e) {
      debugPrint('Error accessing property $propertyName: $e');
      return null;
    }
  }

  /// オブジェクトのメソッドを呼び出し
  dynamic _callMethod(dynamic object, String methodName, List<dynamic> args) {
    if (object == null) return null;

    try {
      switch (methodName) {
        case 'removeResource':
          return object.removeResource(args[0], args[1]);
        default:
          debugPrint('Unknown method: $methodName');
          return null;
      }
    } catch (e) {
      debugPrint('Error calling method $methodName: $e');
      return null;
    }
  }
}
