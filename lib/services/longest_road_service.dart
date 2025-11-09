// modelsからimport
import 'package:test_web_app/models/game_state.dart';
import 'package:test_web_app/models/player.dart';
import 'package:test_web_app/models/edge.dart';
import 'package:test_web_app/models/vertex.dart';

/// 最長交易路サービス
///
/// Phase 5-6: 最長交易路の計算と管理
/// - プレイヤーの道路ネットワークを解析
/// - 深さ優先探索（DFS）で最長ルートを探索
/// - 5本以上で最長交易路ボーナス（2勝利点）を付与
class LongestRoadService {
  /// 最長交易路に必要な最小道路数
  static const int minRoadsForBonus = 5;

  /// 全プレイヤーの最長交易路を計算して更新
  ///
  /// [gameState] ゲーム状態
  ///
  /// 戻り値: 最長交易路が変更されたかどうか
  bool updateLongestRoad(GameState gameState) {
    // 各プレイヤーの最長道路数を計算
    final roadLengths = <String, int>{};
    for (final player in gameState.players) {
      roadLengths[player.id] = calculateLongestRoad(gameState, player.id);
    }

    // 現在の最長交易路保持者を取得
    Player? currentHolder;
    int currentMaxLength = minRoadsForBonus - 1;

    for (final player in gameState.players) {
      if (player.hasLongestRoad) {
        currentHolder = player;
        currentMaxLength = roadLengths[player.id] ?? 0;
        break;
      }
    }

    // 新しい最長交易路保持者を決定
    Player? newHolder;
    int newMaxLength = currentMaxLength;

    for (final player in gameState.players) {
      final length = roadLengths[player.id] ?? 0;
      if (length >= minRoadsForBonus && length > newMaxLength) {
        newMaxLength = length;
        newHolder = player;
      }
    }

    // 最長交易路が変更された場合
    bool changed = false;
    if (newHolder != null && newHolder != currentHolder) {
      // 古い保持者から剥奪
      if (currentHolder != null) {
        currentHolder.hasLongestRoad = false;
        currentHolder.victoryPoints =
            currentHolder.calculateVictoryPoints();
      }

      // 新しい保持者に付与
      newHolder.hasLongestRoad = true;
      newHolder.victoryPoints = newHolder.calculateVictoryPoints();
      changed = true;
    }

    return changed;
  }

  /// プレイヤーの最長道路を計算
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: 最長道路の長さ
  int calculateLongestRoad(GameState gameState, String playerId) {
    // プレイヤーの道路を持つ辺を取得
    final playerEdges =
        gameState.edges.where((e) => e.hasRoadOfPlayer(playerId)).toList();

    if (playerEdges.isEmpty) return 0;

    // 各辺を始点として最長パスを探索
    int maxLength = 0;

    for (final startEdge in playerEdges) {
      // 辺の両端の頂点から探索
      final length1 = _findLongestPath(
        gameState,
        playerId,
        startEdge,
        startEdge.vertex1Id,
        {},
      );
      final length2 = _findLongestPath(
        gameState,
        playerId,
        startEdge,
        startEdge.vertex2Id,
        {},
      );

      maxLength = [maxLength, length1, length2].reduce((a, b) => a > b ? a : b);
    }

    return maxLength;
  }

  /// 深さ優先探索で最長パスを探索
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  /// [currentEdge] 現在の辺
  /// [currentVertexId] 現在の頂点ID
  /// [visitedEdges] 訪問済みの辺IDセット
  ///
  /// 戻り値: 最長パスの長さ
  int _findLongestPath(
    GameState gameState,
    String playerId,
    Edge currentEdge,
    String currentVertexId,
    Set<String> visitedEdges,
  ) {
    // 現在の辺を訪問済みにマーク
    final newVisited = Set<String>.from(visitedEdges)..add(currentEdge.id);

    // 現在の頂点を取得
    final currentVertex =
        gameState.vertices.firstWhere((v) => v.id == currentVertexId);

    // この頂点で道路が途切れるかチェック
    // 他プレイヤーの集落/都市がある場合は途切れる
    if (currentVertex.hasBuilding &&
        !currentVertex.hasBuildingOfPlayer(playerId)) {
      return 1; // 現在の辺のみをカウント
    }

    // 隣接する辺を取得
    final adjacentEdges = gameState.edges.where((edge) {
      return edge.isConnectedToVertex(currentVertexId) &&
          edge.hasRoadOfPlayer(playerId) &&
          !newVisited.contains(edge.id);
    }).toList();

    // これ以上進めない場合
    if (adjacentEdges.isEmpty) {
      return 1; // 現在の辺のみをカウント
    }

    // 各隣接辺を探索して最長パスを見つける
    int maxLength = 1;

    for (final nextEdge in adjacentEdges) {
      // 次の頂点を決定（現在の頂点の反対側）
      final nextVertexId = nextEdge.vertex1Id == currentVertexId
          ? nextEdge.vertex2Id
          : nextEdge.vertex1Id;

      // 再帰的に探索
      final pathLength = _findLongestPath(
        gameState,
        playerId,
        nextEdge,
        nextVertexId,
        newVisited,
      );

      maxLength = maxLength > (1 + pathLength) ? maxLength : (1 + pathLength);
    }

    return maxLength;
  }

  /// プレイヤーの道路ネットワークを可視化（デバッグ用）
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: 道路の接続情報マップ
  Map<String, List<String>> getRoadNetwork(
      GameState gameState, String playerId) {
    final network = <String, List<String>>{};

    final playerEdges =
        gameState.edges.where((e) => e.hasRoadOfPlayer(playerId)).toList();

    for (final edge in playerEdges) {
      // 頂点1から頂点2への接続
      network.putIfAbsent(edge.vertex1Id, () => []).add(edge.vertex2Id);
      // 頂点2から頂点1への接続（無向グラフ）
      network.putIfAbsent(edge.vertex2Id, () => []).add(edge.vertex1Id);
    }

    return network;
  }

  /// 道路配置後に最長交易路を確認すべきかチェック
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: チェックすべきならtrue
  bool shouldCheckLongestRoad(GameState gameState, String playerId) {
    final player = gameState.players.firstWhere((p) => p.id == playerId);

    // プレイヤーの道路数が5未満なら不要
    if (player.roadsBuilt < minRoadsForBonus) {
      return false;
    }

    // 既に最長交易路を持っている場合も不要（失うことはあっても）
    // ただし、他プレイヤーの道路配置時には必要
    return true;
  }

  /// 最長交易路の詳細情報を取得
  ///
  /// [gameState] ゲーム状態
  ///
  /// 戻り値: 各プレイヤーの道路長マップ
  Map<String, int> getLongestRoadDetails(GameState gameState) {
    final details = <String, int>{};

    for (final player in gameState.players) {
      details[player.id] = calculateLongestRoad(gameState, player.id);
    }

    return details;
  }

  /// 最長交易路のパスを取得（UI表示用）
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  ///
  /// 戻り値: 最長パスを構成する辺IDのリスト
  List<String> getLongestRoadPath(GameState gameState, String playerId) {
    final playerEdges =
        gameState.edges.where((e) => e.hasRoadOfPlayer(playerId)).toList();

    if (playerEdges.isEmpty) return [];

    List<String> longestPath = [];

    for (final startEdge in playerEdges) {
      // 辺の両端から探索
      final path1 = _findLongestPathWithEdges(
        gameState,
        playerId,
        startEdge,
        startEdge.vertex1Id,
        {},
      );
      final path2 = _findLongestPathWithEdges(
        gameState,
        playerId,
        startEdge,
        startEdge.vertex2Id,
        {},
      );

      if (path1.length > longestPath.length) {
        longestPath = path1;
      }
      if (path2.length > longestPath.length) {
        longestPath = path2;
      }
    }

    return longestPath;
  }

  /// 深さ優先探索で最長パスの辺IDリストを取得
  List<String> _findLongestPathWithEdges(
    GameState gameState,
    String playerId,
    Edge currentEdge,
    String currentVertexId,
    Set<String> visitedEdges,
  ) {
    final newVisited = Set<String>.from(visitedEdges)..add(currentEdge.id);

    final currentVertex =
        gameState.vertices.firstWhere((v) => v.id == currentVertexId);

    // 他プレイヤーの建設物で途切れる
    if (currentVertex.hasBuilding &&
        !currentVertex.hasBuildingOfPlayer(playerId)) {
      return [currentEdge.id];
    }

    // 隣接する辺を取得
    final adjacentEdges = gameState.edges.where((edge) {
      return edge.isConnectedToVertex(currentVertexId) &&
          edge.hasRoadOfPlayer(playerId) &&
          !newVisited.contains(edge.id);
    }).toList();

    // これ以上進めない場合
    if (adjacentEdges.isEmpty) {
      return [currentEdge.id];
    }

    // 各隣接辺を探索して最長パスを見つける
    List<String> longestPath = [currentEdge.id];

    for (final nextEdge in adjacentEdges) {
      final nextVertexId = nextEdge.vertex1Id == currentVertexId
          ? nextEdge.vertex2Id
          : nextEdge.vertex1Id;

      final path = _findLongestPathWithEdges(
        gameState,
        playerId,
        nextEdge,
        nextVertexId,
        newVisited,
      );

      final fullPath = [currentEdge.id, ...path];
      if (fullPath.length > longestPath.length) {
        longestPath = fullPath;
      }
    }

    return longestPath;
  }
}
