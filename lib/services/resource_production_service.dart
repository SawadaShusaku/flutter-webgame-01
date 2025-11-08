import 'package:flutter/foundation.dart';

// TODO: modelsパッケージから正式にimportする
// 現在は型定義のみ使用

/// 資源生産の結果
class ResourceProductionResult {
  /// プレイヤーIDごとの資源獲得マップ
  /// key: playerId, value: Map<ResourceType, int>
  final Map<String, Map<String, int>> playerResources;

  /// 7が出たかどうか
  final bool isSeven;

  /// サイコロの合計値
  final int diceTotal;

  ResourceProductionResult({
    required this.playerResources,
    required this.isSeven,
    required this.diceTotal,
  });

  /// 特定のプレイヤーが獲得した資源の総数
  int getTotalResourcesForPlayer(String playerId) {
    final resources = playerResources[playerId];
    if (resources == null) return 0;
    return resources.values.fold(0, (sum, count) => sum + count);
  }

  @override
  String toString() {
    return 'ResourceProductionResult(diceTotal: $diceTotal, isSeven: $isSeven, playerResources: $playerResources)';
  }
}

/// 資源生産サービス
///
/// サイコロの目に応じた資源生産ロジックを提供
/// カタンのルール:
/// - サイコロの目に対応するタイルが資源を生産
/// - 集落 = 1枚、都市 = 2枚の資源を獲得
/// - 盗賊がいるタイルは資源を生産しない
/// - 7が出た場合は資源生産なし（特別処理）
class ResourceProductionService extends ChangeNotifier {
  /// サイコロの目に応じて資源を生産
  ///
  /// [diceTotal] サイコロの合計値（2-12）
  /// [tiles] ゲームボード上の全タイル
  /// [vertices] ゲームボード上の全頂点（建設物情報含む）
  /// [robberHexId] 盗賊がいるタイルのID（nullの場合は盗賊なし）
  ///
  /// 戻り値: 資源生産の結果
  ResourceProductionResult produceResources({
    required int diceTotal,
    required List<dynamic> tiles, // List<HexTile>
    required List<dynamic> vertices, // List<Vertex>
    String? robberHexId,
  }) {
    assert(diceTotal >= 2 && diceTotal <= 12, 'サイコロの合計は2-12である必要があります');

    // 7が出た場合は資源生産なし
    if (diceTotal == 7) {
      return ResourceProductionResult(
        playerResources: {},
        isSeven: true,
        diceTotal: diceTotal,
      );
    }

    // プレイヤーIDごとの資源獲得マップ
    // key: playerId, value: Map<resourceTypeName, count>
    final Map<String, Map<String, int>> playerResources = {};

    // サイコロの目に対応するタイルを検索
    for (final tile in tiles) {
      // 動的アクセス（型安全性を確保するため、実際のデプロイ時は適切なキャストが必要）
      final tileNumber = _getProperty(tile, 'number') as int?;
      final tileId = _getProperty(tile, 'id') as String?;
      final hasRobber = _getProperty(tile, 'hasRobber') as bool? ?? false;
      final resourceType = _getProperty(tile, 'resourceType');

      // タイルの数字がサイコロの目と一致しない場合はスキップ
      if (tileNumber != diceTotal) continue;

      // 盗賊がいるタイルは資源を生産しない
      if (hasRobber || tileId == robberHexId) continue;

      // 資源タイプがnull（砂漠）の場合はスキップ
      if (resourceType == null) continue;

      // このタイルに隣接する頂点を検索
      final adjacentVertices = _findAdjacentVertices(tileId!, vertices);

      for (final vertex in adjacentVertices) {
        final building = _getProperty(vertex, 'building');
        if (building == null) continue;

        final playerId = _getProperty(building, 'playerId') as String?;
        final buildingType = _getProperty(building, 'type');

        if (playerId == null) continue;

        // 建設物のタイプに応じた資源数を計算
        // settlement = 1, city = 2
        final resourceCount = _getBuildingResourceCount(buildingType);

        // 資源タイプ名を取得（enum.toString()から名前部分を抽出）
        final resourceTypeName = _getResourceTypeName(resourceType);

        // プレイヤーの資源マップを初期化（必要な場合）
        playerResources.putIfAbsent(playerId, () => {});

        // 資源を追加
        final currentCount =
            playerResources[playerId]![resourceTypeName] ?? 0;
        playerResources[playerId]![resourceTypeName] =
            currentCount + resourceCount;
      }
    }

    return ResourceProductionResult(
      playerResources: playerResources,
      isSeven: false,
      diceTotal: diceTotal,
    );
  }

  /// タイルに隣接する頂点を検索
  List<dynamic> _findAdjacentVertices(String tileId, List<dynamic> vertices) {
    final adjacentVertices = <dynamic>[];

    for (final vertex in vertices) {
      final adjacentHexIds =
          _getProperty(vertex, 'adjacentHexIds') as List<dynamic>?;
      if (adjacentHexIds != null && adjacentHexIds.contains(tileId)) {
        adjacentVertices.add(vertex);
      }
    }

    return adjacentVertices;
  }

  /// 建設物のタイプに応じた資源数を取得
  int _getBuildingResourceCount(dynamic buildingType) {
    if (buildingType == null) return 0;

    // BuildingType.settlement = 1, BuildingType.city = 2
    final typeString = buildingType.toString();
    if (typeString.contains('settlement')) {
      return 1;
    } else if (typeString.contains('city')) {
      return 2;
    }

    return 0;
  }

  /// 資源タイプから名前を取得（enum.toString()から）
  String _getResourceTypeName(dynamic resourceType) {
    final typeString = resourceType.toString();
    // "ResourceType.lumber" -> "lumber"
    final parts = typeString.split('.');
    return parts.length > 1 ? parts[1] : typeString;
  }

  /// オブジェクトのプロパティを動的に取得（リフレクション的な処理）
  dynamic _getProperty(dynamic object, String propertyName) {
    try {
      // Dartのリフレクションは制限があるため、
      // 実際の実装では適切なキャストや型チェックが必要
      // ここでは簡易的にnoSuchMethodを使用
      if (object == null) return null;

      // プロパティ名に基づいてgetterを呼び出し
      // 注: これは型安全ではないため、本番環境では適切な型定義を使用すべき
      switch (propertyName) {
        case 'id':
          return object.id;
        case 'number':
          return object.number;
        case 'hasRobber':
          return object.hasRobber;
        case 'resourceType':
          return object.resourceType;
        case 'building':
          return object.building;
        case 'playerId':
          return object.playerId;
        case 'type':
          return object.type;
        case 'adjacentHexIds':
          return object.adjacentHexIds;
        default:
          return null;
      }
    } catch (e) {
      debugPrint('Error accessing property $propertyName: $e');
      return null;
    }
  }

  /// 7が出た場合の資源破棄処理
  ///
  /// [players] 全プレイヤーのリスト
  /// 戻り値: 資源を破棄する必要があるプレイヤーIDのリスト
  List<String> getPlayersNeedingDiscard(List<dynamic> players) {
    final playersNeedingDiscard = <String>[];

    for (final player in players) {
      final totalResources = _getTotalResources(player);
      final playerId = _getProperty(player, 'id') as String?;

      // 資源が8枚以上の場合、半分（切り捨て）を破棄
      if (totalResources >= 8 && playerId != null) {
        playersNeedingDiscard.add(playerId);
      }
    }

    return playersNeedingDiscard;
  }

  /// プレイヤーが破棄する必要がある資源数を計算
  ///
  /// [player] プレイヤーオブジェクト
  /// 戻り値: 破棄する資源数（総資源数の半分、切り捨て）
  int getDiscardCount(dynamic player) {
    final totalResources = _getTotalResources(player);
    return totalResources ~/ 2; // 切り捨て除算
  }

  /// プレイヤーの総資源数を取得
  int _getTotalResources(dynamic player) {
    try {
      final resources = _getProperty(player, 'resources') as Map?;
      if (resources == null) return 0;

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
}
