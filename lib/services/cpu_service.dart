import 'dart:math';
import 'package:test_web_app/models/game_state.dart';
import 'package:test_web_app/models/player.dart';
import 'package:test_web_app/models/enums.dart';
import 'package:test_web_app/models/vertex.dart';
import 'package:test_web_app/models/edge.dart';

/// CPUプレイヤーの行動を管理するサービス
class CPUService {
  final Random _random = Random();

  /// CPUのターンを実行
  /// GameControllerから呼び出される
  Future<CPUAction?> decideCPUAction(GameState state, Player player) async {
    if (player.playerType != PlayerType.cpu) {
      return null;
    }

    // 思考時間をシミュレート
    await Future.delayed(const Duration(milliseconds: 500));

    // フェーズごとの処理
    switch (state.phase) {
      case GamePhase.setup:
        return _decideSetupAction(state, player);
      case GamePhase.normalPlay:
        return _decideNormalPlayAction(state, player);
      default:
        return null;
    }
  }

  /// 初期配置フェーズの行動決定
  CPUAction? _decideSetupAction(GameState state, Player player) {
    // ランダムに建設可能な頂点を選ぶ
    final availableVertices = state.vertices
        .where((v) => !v.hasBuilding && _isValidSetupSettlement(state, v))
        .toList();

    if (availableVertices.isNotEmpty) {
      final selectedVertex = availableVertices[_random.nextInt(availableVertices.length)];
      return CPUAction(
        type: CPUActionType.buildSettlement,
        targetId: selectedVertex.id,
      );
    }

    // 道路配置
    final availableEdges = state.edges
        .where((e) => !e.hasRoad && _isValidSetupRoad(state, e, player))
        .toList();

    if (availableEdges.isNotEmpty) {
      final selectedEdge = availableEdges[_random.nextInt(availableEdges.length)];
      return CPUAction(
        type: CPUActionType.buildRoad,
        targetId: selectedEdge.id,
      );
    }

    return null;
  }

  /// 通常プレイの行動決定
  CPUAction? _decideNormalPlayAction(GameState state, Player player) {
    final possibleActions = <CPUAction>[];

    // 集落が建てられるか
    if (_canBuildSettlement(player)) {
      final availableVertices = state.vertices
          .where((v) => !v.hasBuilding && _isValidSettlementPlacement(state, v, player))
          .toList();

      if (availableVertices.isNotEmpty) {
        final vertex = availableVertices[_random.nextInt(availableVertices.length)];
        possibleActions.add(CPUAction(
          type: CPUActionType.buildSettlement,
          targetId: vertex.id,
        ));
      }
    }

    // 道路が建てられるか
    if (_canBuildRoad(player)) {
      final availableEdges = state.edges
          .where((e) => !e.hasRoad && _isValidRoadPlacement(state, e, player))
          .toList();

      if (availableEdges.isNotEmpty) {
        final edge = availableEdges[_random.nextInt(availableEdges.length)];
        possibleActions.add(CPUAction(
          type: CPUActionType.buildRoad,
          targetId: edge.id,
        ));
      }
    }

    // 都市が建てられるか
    if (_canBuildCity(player)) {
      final availableVertices = state.vertices
          .where((v) => v.building?.type == BuildingType.settlement && v.building?.playerId == player.id)
          .toList();

      if (availableVertices.isNotEmpty) {
        final vertex = availableVertices[_random.nextInt(availableVertices.length)];
        possibleActions.add(CPUAction(
          type: CPUActionType.buildCity,
          targetId: vertex.id,
        ));
      }
    }

    // ランダムに1つ選ぶ
    if (possibleActions.isNotEmpty) {
      return possibleActions[_random.nextInt(possibleActions.length)];
    }

    // 建設できない場合はターン終了
    return CPUAction(type: CPUActionType.endTurn);
  }

  // リソースチェック
  bool _canBuildSettlement(Player player) {
    return player.resources[ResourceType.lumber]! >= 1 &&
           player.resources[ResourceType.brick]! >= 1 &&
           player.resources[ResourceType.wool]! >= 1 &&
           player.resources[ResourceType.grain]! >= 1 &&
           player.settlementsBuilt < 5;
  }

  bool _canBuildRoad(Player player) {
    return player.resources[ResourceType.lumber]! >= 1 &&
           player.resources[ResourceType.brick]! >= 1 &&
           player.roadsBuilt < 15;
  }

  bool _canBuildCity(Player player) {
    return player.resources[ResourceType.grain]! >= 2 &&
           player.resources[ResourceType.ore]! >= 3 &&
           player.citiesBuilt < 4;
  }

  // 配置可能性チェック（簡易版）
  bool _isValidSetupSettlement(GameState state, Vertex vertex) {
    // TODO: 距離ルールチェック（2マス離れているか）
    return true;  // 簡易版ではOK
  }

  bool _isValidSetupRoad(GameState state, Edge edge, Player player) {
    // 初期配置では、道路は必ず自分の集落に隣接している必要がある
    // 辺の両端の頂点を確認
    final vertex1 = state.vertices.firstWhere(
      (v) => v.id == edge.vertex1Id,
      orElse: () => state.vertices.first,
    );
    final vertex2 = state.vertices.firstWhere(
      (v) => v.id == edge.vertex2Id,
      orElse: () => state.vertices.first,
    );

    // どちらかの頂点に自分の集落があるか確認
    final hasOwnSettlement =
        (vertex1.building != null && vertex1.building!.playerId == player.id) ||
        (vertex2.building != null && vertex2.building!.playerId == player.id);

    return hasOwnSettlement;
  }

  bool _isValidSettlementPlacement(GameState state, Vertex vertex, Player player) {
    // TODO: 距離ルール + 自分の道路が接続しているか
    return true;  // 簡易版ではOK
  }

  bool _isValidRoadPlacement(GameState state, Edge edge, Player player) {
    // TODO: 自分の建設物または道路に接続しているか
    return true;  // 簡易版ではOK
  }
}

/// CPU行動の種類
enum CPUActionType {
  buildSettlement,
  buildRoad,
  buildCity,
  endTurn,
}

/// CPU行動データ
class CPUAction {
  final CPUActionType type;
  final String? targetId;  // 頂点IDまたは辺ID

  CPUAction({
    required this.type,
    this.targetId,
  });
}
