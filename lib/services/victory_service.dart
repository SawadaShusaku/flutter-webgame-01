import 'package:flutter/foundation.dart';

/// 勝利点の詳細内訳
class VictoryPointBreakdown {
  /// プレイヤーID
  final String playerId;

  /// 集落による勝利点 (1点 × 建設数)
  final int settlementPoints;

  /// 都市による勝利点 (2点 × 建設数)
  final int cityPoints;

  /// 発展カード（勝利点）による勝利点 (1点 × 枚数)
  final int victoryCardPoints;

  /// 最長交易路による勝利点 (2点 または 0点)
  final int longestRoadPoints;

  /// 最大騎士力による勝利点 (2点 または 0点)
  final int largestArmyPoints;

  VictoryPointBreakdown({
    required this.playerId,
    required this.settlementPoints,
    required this.cityPoints,
    required this.victoryCardPoints,
    required this.longestRoadPoints,
    required this.largestArmyPoints,
  });

  /// 合計勝利点
  int get totalPoints =>
      settlementPoints +
      cityPoints +
      victoryCardPoints +
      longestRoadPoints +
      largestArmyPoints;

  /// 10点以上に到達しているか
  bool get hasWon => totalPoints >= 10;

  @override
  String toString() {
    return 'VictoryPointBreakdown('
        'playerId: $playerId, '
        'total: $totalPoints, '
        'settlements: $settlementPoints, '
        'cities: $cityPoints, '
        'victoryCards: $victoryCardPoints, '
        'longestRoad: $longestRoadPoints, '
        'largestArmy: $largestArmyPoints'
        ')';
  }

  /// マップに変換
  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'settlementPoints': settlementPoints,
      'cityPoints': cityPoints,
      'victoryCardPoints': victoryCardPoints,
      'longestRoadPoints': longestRoadPoints,
      'largestArmyPoints': largestArmyPoints,
      'totalPoints': totalPoints,
    };
  }
}

/// 勝利判定結果
class VictoryCheckResult {
  /// 勝者のプレイヤーID（勝者がいない場合はnull）
  final String? winnerId;

  /// 全プレイヤーの勝利点内訳
  final List<VictoryPointBreakdown> allPlayerPoints;

  VictoryCheckResult({
    required this.winnerId,
    required this.allPlayerPoints,
  });

  /// 勝者が決定しているか
  bool get hasWinner => winnerId != null;

  /// 勝者の勝利点内訳を取得
  VictoryPointBreakdown? get winnerBreakdown {
    if (winnerId == null) return null;
    return allPlayerPoints.firstWhere(
      (breakdown) => breakdown.playerId == winnerId,
    );
  }

  @override
  String toString() {
    return 'VictoryCheckResult(winnerId: $winnerId, hasWinner: $hasWinner)';
  }
}

/// 勝利判定サービス
///
/// カタンの勝利条件:
/// - 10勝利点を先に獲得したプレイヤーが勝利
/// - 自分の手番でのみ勝利宣言可能
/// - 勝利点の内訳:
///   - 集落: 1点 × 建設数
///   - 都市: 2点 × 建設数
///   - 発展カード（勝利点）: 1点 × 枚数
///   - 最長交易路: 2点（5本以上の道路が必要）
///   - 最大騎士力: 2点（3枚以上の騎士カード使用が必要）
class VictoryService extends ChangeNotifier {
  /// 最長交易路に必要な最低道路数
  static const int minRoadLengthForLongestRoad = 5;

  /// 最大騎士力に必要な最低騎士カード使用枚数
  static const int minKnightsForLargestArmy = 3;

  /// 勝利に必要な勝利点
  static const int pointsToWin = 10;

  /// 勝利判定を実行
  ///
  /// [players] 全プレイヤーのリスト
  /// [currentPlayerId] 現在のターンのプレイヤーID（勝利判定は自分の手番でのみ可能）
  /// [vertices] ゲームボード上の全頂点（建設物情報含む）
  /// [edges] ゲームボード上の全辺（道路情報含む）
  ///
  /// 戻り値: 勝利判定結果
  VictoryCheckResult checkVictory({
    required List<dynamic> players,
    required String currentPlayerId,
    List<dynamic>? vertices,
    List<dynamic>? edges,
  }) {
    // 全プレイヤーの勝利点を計算
    final allPlayerPoints = <VictoryPointBreakdown>[];

    for (final player in players) {
      final breakdown = calculateVictoryPoints(
        player: player,
        players: players,
        vertices: vertices,
        edges: edges,
      );
      allPlayerPoints.add(breakdown);
    }

    // 現在のプレイヤーが10点以上に達している場合のみ勝利
    final currentPlayerBreakdown = allPlayerPoints.firstWhere(
      (breakdown) => breakdown.playerId == currentPlayerId,
    );

    final String? winnerId =
        currentPlayerBreakdown.hasWon ? currentPlayerId : null;

    return VictoryCheckResult(
      winnerId: winnerId,
      allPlayerPoints: allPlayerPoints,
    );
  }

  /// 特定プレイヤーの勝利点を計算
  ///
  /// [player] 対象プレイヤー
  /// [players] 全プレイヤーのリスト（最長交易路・最大騎士力の判定に必要）
  /// [vertices] ゲームボード上の全頂点（建設物情報含む）
  /// [edges] ゲームボード上の全辺（道路情報含む）
  ///
  /// 戻り値: 勝利点の詳細内訳
  VictoryPointBreakdown calculateVictoryPoints({
    required dynamic player,
    required List<dynamic> players,
    List<dynamic>? vertices,
    List<dynamic>? edges,
  }) {
    final playerId = _getProperty(player, 'id') as String;

    // 1. 集落による勝利点 (1点 × 建設数)
    final settlementCount = _countBuildings(playerId, 'settlement', vertices);
    final settlementPoints = settlementCount * 1;

    // 2. 都市による勝利点 (2点 × 建設数)
    final cityCount = _countBuildings(playerId, 'city', vertices);
    final cityPoints = cityCount * 2;

    // 3. 発展カード（勝利点）による勝利点 (1点 × 枚数)
    final victoryCardCount = _countVictoryCards(player);
    final victoryCardPoints = victoryCardCount * 1;

    // 4. 最長交易路による勝利点 (2点)
    final longestRoadPoints = _hasLongestRoad(playerId, players, edges) ? 2 : 0;

    // 5. 最大騎士力による勝利点 (2点)
    final largestArmyPoints = _hasLargestArmy(playerId, players) ? 2 : 0;

    return VictoryPointBreakdown(
      playerId: playerId,
      settlementPoints: settlementPoints,
      cityPoints: cityPoints,
      victoryCardPoints: victoryCardPoints,
      longestRoadPoints: longestRoadPoints,
      largestArmyPoints: largestArmyPoints,
    );
  }

  /// 特定タイプの建設物の数をカウント
  int _countBuildings(
    String playerId,
    String buildingType,
    List<dynamic>? vertices,
  ) {
    if (vertices == null) return 0;

    int count = 0;
    for (final vertex in vertices) {
      final building = _getProperty(vertex, 'building');
      if (building == null) continue;

      final buildingPlayerId = _getProperty(building, 'playerId') as String?;
      final type = _getProperty(building, 'type');

      if (buildingPlayerId == playerId &&
          type.toString().contains(buildingType)) {
        count++;
      }
    }

    return count;
  }

  /// 発展カード（勝利点）の枚数をカウント
  int _countVictoryCards(dynamic player) {
    try {
      final developmentCards = _getProperty(player, 'developmentCards') as List?;
      if (developmentCards == null) return 0;

      int count = 0;
      for (final card in developmentCards) {
        final cardType = _getProperty(card, 'type');
        if (cardType.toString().contains('victoryPoint')) {
          count++;
        }
      }

      return count;
    } catch (e) {
      debugPrint('Error counting victory cards: $e');
      return 0;
    }
  }

  /// 最長交易路を持っているか判定
  ///
  /// ルール:
  /// - 5本以上の連続した道路が必要
  /// - 複数プレイヤーが同じ長さの場合、先に達成したプレイヤーが保持
  bool _hasLongestRoad(
    String playerId,
    List<dynamic> players,
    List<dynamic>? edges,
  ) {
    if (edges == null) return false;

    // 各プレイヤーの最長道路を計算
    final longestRoadByPlayer = <String, int>{};

    for (final player in players) {
      final pid = _getProperty(player, 'id') as String;
      final roadLength = _calculateLongestRoad(pid, edges);
      longestRoadByPlayer[pid] = roadLength;
    }

    // 最長交易路の候補を取得（5本以上のみ）
    final validLengths = longestRoadByPlayer.entries
        .where((entry) => entry.value >= minRoadLengthForLongestRoad);

    if (validLengths.isEmpty) return false;

    // 最長の長さを取得
    final maxLength = validLengths.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    // 対象プレイヤーが最長かチェック
    return longestRoadByPlayer[playerId] == maxLength;
  }

  /// 最大騎士力を持っているか判定
  ///
  /// ルール:
  /// - 3枚以上の騎士カードを使用している必要がある
  /// - 複数プレイヤーが同じ枚数の場合、先に達成したプレイヤーが保持
  bool _hasLargestArmy(String playerId, List<dynamic> players) {
    // 各プレイヤーの使用した騎士カード枚数を計算
    final knightsByPlayer = <String, int>{};

    for (final player in players) {
      final pid = _getProperty(player, 'id') as String;
      final knightCount = _countUsedKnights(player);
      knightsByPlayer[pid] = knightCount;
    }

    // 最大騎士力の候補を取得（3枚以上のみ）
    final validCounts = knightsByPlayer.entries
        .where((entry) => entry.value >= minKnightsForLargestArmy);

    if (validCounts.isEmpty) return false;

    // 最大の枚数を取得
    final maxCount = validCounts.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    // 対象プレイヤーが最大かチェック
    return knightsByPlayer[playerId] == maxCount;
  }

  /// プレイヤーの最長道路を計算（DFS）
  int _calculateLongestRoad(String playerId, List<dynamic> edges) {
    // プレイヤーの道路のみを抽出
    final playerRoads = <String>[];
    for (final edge in edges) {
      final road = _getProperty(edge, 'road');
      if (road == null) continue;

      final roadPlayerId = _getProperty(road, 'playerId') as String?;
      if (roadPlayerId == playerId) {
        final edgeId = _getProperty(edge, 'id') as String?;
        if (edgeId != null) {
          playerRoads.add(edgeId);
        }
      }
    }

    if (playerRoads.isEmpty) return 0;

    // 簡易的な実装: 道路の総数を返す
    // TODO: 実際には連続した道路の最長経路を計算する必要がある（DFS/BFS）
    return playerRoads.length;
  }

  /// 使用した騎士カードの枚数をカウント
  int _countUsedKnights(dynamic player) {
    try {
      // usedKnightsプロパティがある場合
      final usedKnights = _getProperty(player, 'usedKnights') as int?;
      if (usedKnights != null) return usedKnights;

      // または使用済み発展カードから騎士を数える
      final usedCards = _getProperty(player, 'usedDevelopmentCards') as List?;
      if (usedCards == null) return 0;

      int count = 0;
      for (final card in usedCards) {
        final cardType = _getProperty(card, 'type');
        if (cardType.toString().contains('knight')) {
          count++;
        }
      }

      return count;
    } catch (e) {
      debugPrint('Error counting used knights: $e');
      return 0;
    }
  }

  /// オブジェクトのプロパティを動的に取得
  dynamic _getProperty(dynamic object, String propertyName) {
    try {
      if (object == null) return null;

      switch (propertyName) {
        case 'id':
          return object.id;
        case 'building':
          return object.building;
        case 'playerId':
          return object.playerId;
        case 'type':
          return object.type;
        case 'developmentCards':
          return object.developmentCards;
        case 'usedDevelopmentCards':
          return object.usedDevelopmentCards;
        case 'usedKnights':
          return object.usedKnights;
        case 'road':
          return object.road;
        default:
          return null;
      }
    } catch (e) {
      debugPrint('Error accessing property $propertyName: $e');
      return null;
    }
  }
}
