import 'dart:math';
import 'package:flutter/foundation.dart';

// TODO: 統合時に正しいimportパスに変更
// 現在はプレースホルダーとして動的型を使用

/// 盗賊サービス
/// - 盗賊の移動ロジック
/// - 資源を奪う処理
/// - 7が出た時の処理
class RobberService extends ChangeNotifier {
  final Random _random = Random();

  /// 盗賊を移動
  ///
  /// [gameState] ゲーム状態
  /// [hexId] 移動先のタイルID
  ///
  /// 戻り値: 移動に成功したかどうか
  ///
  /// ルール:
  /// - 現在盗賊がいるタイルには移動できない
  bool moveRobber(dynamic gameState, String hexId) {
    try {
      // 盗賊の現在位置を取得
      final robber = _getProperty(gameState, 'robber');
      if (robber == null) {
        debugPrint('Error: Robber not found in game state');
        return false;
      }

      final currentHexId = _getProperty(robber, 'currentHexId') as String?;

      // 現在いるタイルには移動できない
      if (currentHexId == hexId) {
        debugPrint('Cannot move robber to the same hex');
        return false;
      }

      // 古いタイルから盗賊フラグを削除
      if (currentHexId != null) {
        final oldHex = _findHexById(gameState, currentHexId);
        if (oldHex != null) {
          _setProperty(oldHex, 'hasRobber', false);
        }
      }

      // 新しいタイルに盗賊フラグを設定
      final newHex = _findHexById(gameState, hexId);
      if (newHex != null) {
        _setProperty(newHex, 'hasRobber', true);
      }

      // 盗賊の位置を更新
      _callMethod(robber, 'moveTo', [hexId]);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error moving robber: $e');
      return false;
    }
  }

  /// 対象プレイヤーから資源を1枚ランダムに奪う
  ///
  /// [target] 奪われるプレイヤー
  /// [thief] 奪うプレイヤー
  ///
  /// 戻り値: 奪った資源のタイプ名（nullの場合は奪えなかった）
  String? stealResourceFrom(dynamic target, dynamic thief) {
    try {
      // 対象プレイヤーの資源を取得
      final targetResources = _getProperty(target, 'resources') as Map?;
      if (targetResources == null || targetResources.isEmpty) {
        debugPrint('Target has no resources to steal');
        return null;
      }

      // 資源があるタイプのリストを作成
      final availableResources = <String>[];
      for (final entry in targetResources.entries) {
        final resourceType = entry.key.toString();
        final count = entry.value as int? ?? 0;

        // このタイプの資源の数だけリストに追加
        for (int i = 0; i < count; i++) {
          availableResources.add(resourceType);
        }
      }

      if (availableResources.isEmpty) {
        debugPrint('Target has no resources to steal');
        return null;
      }

      // ランダムに1つ選択
      final stolenResourceType =
          availableResources[_random.nextInt(availableResources.length)];

      // 対象プレイヤーから資源を減らす
      final resourceTypeName = _extractResourceTypeName(stolenResourceType);
      _callMethod(target, 'removeResource', [
        _parseResourceType(stolenResourceType),
        1,
      ]);

      // 奪うプレイヤーに資源を追加
      _callMethod(thief, 'addResource', [
        _parseResourceType(stolenResourceType),
        1,
      ]);

      notifyListeners();
      return resourceTypeName;
    } catch (e) {
      debugPrint('Error stealing resource: $e');
      return null;
    }
  }

  /// 特定のタイルに建設物を持つプレイヤーを取得
  ///
  /// [gameState] ゲーム状態
  /// [hexId] タイルID
  ///
  /// 戻り値: 建設物を持つプレイヤーのリスト
  List<dynamic> getPlayersOnHex(dynamic gameState, String hexId) {
    final playersOnHex = <dynamic>[];

    try {
      // タイルに隣接する頂点を検索
      final vertices = _getProperty(gameState, 'vertices') as List? ?? [];

      for (final vertex in vertices) {
        final adjacentHexIds =
            _getProperty(vertex, 'adjacentHexIds') as List? ?? [];

        // このタイルに隣接しているか確認
        if (adjacentHexIds.contains(hexId)) {
          final building = _getProperty(vertex, 'building');
          if (building != null) {
            final playerId = _getProperty(building, 'playerId') as String?;
            if (playerId != null) {
              // このプレイヤーを取得
              final players = _getProperty(gameState, 'players') as List? ?? [];
              final player = players.firstWhere(
                (p) => _getProperty(p, 'id') == playerId,
                orElse: () => null,
              );

              if (player != null && !playersOnHex.contains(player)) {
                playersOnHex.add(player);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting players on hex: $e');
    }

    return playersOnHex;
  }

  /// 7が出た時の処理
  ///
  /// [gameState] ゲーム状態
  ///
  /// 戻り値: 資源を破棄する必要があるプレイヤーIDのリスト
  ///
  /// ルール:
  /// 1. 8枚以上の資源を持つプレイヤーを検出
  /// 2. それらのプレイヤーは半分（切り捨て）を破棄する必要がある
  List<String> handleSevenRolled(dynamic gameState) {
    final playersNeedingDiscard = <String>[];

    try {
      final players = _getProperty(gameState, 'players') as List? ?? [];

      for (final player in players) {
        final totalResources = _getTotalResources(player);
        final playerId = _getProperty(player, 'id') as String?;

        if (totalResources >= 8 && playerId != null) {
          playersNeedingDiscard.add(playerId);
        }
      }
    } catch (e) {
      debugPrint('Error handling seven rolled: $e');
    }

    return playersNeedingDiscard;
  }

  // ===== ヘルパーメソッド =====

  /// タイルIDからタイルを検索
  dynamic _findHexById(dynamic gameState, String hexId) {
    try {
      final board = _getProperty(gameState, 'board') as List? ?? [];
      for (final hex in board) {
        if (_getProperty(hex, 'id') == hexId) {
          return hex;
        }
      }
    } catch (e) {
      debugPrint('Error finding hex: $e');
    }
    return null;
  }

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

  /// 文字列から資源タイプのenumを解析
  dynamic _parseResourceType(String resourceTypeString) {
    // 実際のenumオブジェクトを返す必要があるが、
    // 動的型を使用しているため、文字列をそのまま返す
    return resourceTypeString;
  }

  /// オブジェクトのプロパティを取得
  dynamic _getProperty(dynamic object, String propertyName) {
    if (object == null) return null;

    try {
      switch (propertyName) {
        case 'robber':
          return object.robber;
        case 'currentHexId':
          return object.currentHexId;
        case 'board':
          return object.board;
        case 'vertices':
          return object.vertices;
        case 'players':
          return object.players;
        case 'id':
          return object.id;
        case 'hasRobber':
          return object.hasRobber;
        case 'adjacentHexIds':
          return object.adjacentHexIds;
        case 'building':
          return object.building;
        case 'playerId':
          return object.playerId;
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

  /// オブジェクトのプロパティを設定
  void _setProperty(dynamic object, String propertyName, dynamic value) {
    if (object == null) return;

    try {
      switch (propertyName) {
        case 'hasRobber':
          object.hasRobber = value;
          break;
        default:
          debugPrint('Unknown property: $propertyName');
      }
    } catch (e) {
      debugPrint('Error setting property $propertyName: $e');
    }
  }

  /// オブジェクトのメソッドを呼び出し
  dynamic _callMethod(dynamic object, String methodName, List<dynamic> args) {
    if (object == null) return null;

    try {
      switch (methodName) {
        case 'moveTo':
          return object.moveTo(args[0]);
        case 'removeResource':
          return object.removeResource(args[0], args[1]);
        case 'addResource':
          return object.addResource(args[0], args[1]);
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
