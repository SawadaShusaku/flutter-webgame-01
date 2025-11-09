// BuildingServiceの使用例

import 'package:test_web_app/services/building_service.dart';
import 'package:test_web_app/services/game_service.dart';
import 'package:test_web_app/models/enums.dart';

/// 初期配置フェーズの完全な流れの例
void exampleInitialSetup() {
  // サービスのインスタンスを作成
  final gameService = GameService();
  final buildingService = BuildingService();

  // ゲームを開始
  final gameState = gameService.startNewGame(
    gameId: 'game_001',
    playerNames: ['Alice', 'Bob', 'Charlie', 'Diana'],
    playerColors: [
      PlayerColor.red,
      PlayerColor.blue,
      PlayerColor.green,
      PlayerColor.yellow,
    ],
  );

  print('=== ゲーム開始 ===');
  print('プレイヤー数: ${gameState.players.length}');

  // ステップ1: 初期配置フェーズを開始
  var setupState = buildingService.startSetupPhase(gameState);
  print('\n=== フェーズ1: 順番決め ===');

  // ステップ2: 各プレイヤーがサイコロを振って順番を決める
  for (final player in gameState.players) {
    final (newSetupState, roll) = buildingService.rollForOrder(setupState, player.id);
    setupState = newSetupState;
    print('${player.name}: サイコロの出目 = $roll');
  }

  // ステップ3: 配置順を確定
  final (updatedGameState, finalSetupState, orderedPlayerIds) =
      buildingService.finalizePlayerOrder(gameState, setupState);
  setupState = finalSetupState;

  print('\n配置順:');
  for (int i = 0; i < orderedPlayerIds.length; i++) {
    final player = gameState.players.firstWhere((p) => p.id == orderedPlayerIds[i]);
    print('  ${i + 1}. ${player.name}');
  }

  print('\n=== フェーズ2: 初期配置（1巡目） ===');

  // ステップ4: 1巡目 - 各プレイヤーが集落と道路を配置
  for (int i = 0; i < gameState.players.length; i++) {
    final playerId = orderedPlayerIds[setupState.currentPlayerIndex];
    final player = gameState.players.firstWhere((p) => p.id == playerId);

    print('\n${player.name}のターン:');

    // 配置可能な頂点を取得
    final availableVertices = buildingService.getAvailableVertices(gameState, setupState);
    print('  配置可能な頂点: ${availableVertices.length}個');

    // 集落を配置（例: 最初の頂点）
    if (availableVertices.isNotEmpty) {
      final vertexId = availableVertices.first;
      final (_, newSetupState, success) = buildingService.placeInitialSettlement(
        gameState,
        setupState,
        vertexId,
        playerId,
      );

      if (success) {
        setupState = newSetupState;
        print('  集落を配置: $vertexId');

        // 配置可能な辺を取得
        final availableEdges = buildingService.getAvailableEdges(gameState, setupState);
        print('  配置可能な辺: ${availableEdges.length}個');

        // 道路を配置（例: 最初の辺）
        if (availableEdges.isNotEmpty) {
          final edgeId = availableEdges.first;
          final (_, finalSetupState, roadSuccess) = buildingService.placeInitialRoad(
            gameState,
            setupState,
            edgeId,
            playerId,
          );

          if (roadSuccess) {
            setupState = finalSetupState;
            print('  道路を配置: $edgeId');
          }
        }
      }
    }

    // 進行状況を表示
    final (current, total) = buildingService.getSetupProgress(setupState, gameState.players.length);
    print('  進行状況: $current/$total');
  }

  print('\n=== フェーズ3: 初期配置（2巡目・逆順） ===');

  // ステップ5: 2巡目 - 逆順で配置
  for (int i = 0; i < gameState.players.length; i++) {
    final playerId = orderedPlayerIds[setupState.currentPlayerIndex];
    final player = gameState.players.firstWhere((p) => p.id == playerId);

    print('\n${player.name}のターン:');

    // 配置可能な頂点を取得
    final availableVertices = buildingService.getAvailableVertices(gameState, setupState);

    // 集落を配置
    if (availableVertices.isNotEmpty) {
      final vertexId = availableVertices.first;
      final (_, newSetupState, success) = buildingService.placeInitialSettlement(
        gameState,
        setupState,
        vertexId,
        playerId,
      );

      if (success) {
        setupState = newSetupState;
        print('  集落を配置: $vertexId');

        // 配置可能な辺を取得
        final availableEdges = buildingService.getAvailableEdges(gameState, setupState);

        // 道路を配置
        if (availableEdges.isNotEmpty) {
          final edgeId = availableEdges.first;
          final (_, finalSetupState, roadSuccess) = buildingService.placeInitialRoad(
            gameState,
            setupState,
            edgeId,
            playerId,
          );

          if (roadSuccess) {
            setupState = finalSetupState;
            print('  道路を配置: $edgeId');

            // 2巡目では初期資源を獲得
            print('  初期資源を獲得:');
            for (final entry in player.resources.entries) {
              if (entry.value > 0) {
                print('    ${entry.key.name}: ${entry.value}枚');
              }
            }
          }
        }
      }
    }

    // 進行状況を表示
    final (current, total) = buildingService.getSetupProgress(setupState, gameState.players.length);
    print('  進行状況: $current/$total');
  }

  // ステップ6: 初期配置完了確認
  if (buildingService.isSetupComplete(setupState)) {
    print('\n=== 初期配置完了 ===');
    print('ゲームフェーズ: ${gameState.phase.name}');

    // 各プレイヤーの状態を表示
    print('\n各プレイヤーの状態:');
    for (final player in gameState.players) {
      print('  ${player.name}:');
      print('    集落: ${player.settlementsBuilt}個');
      print('    道路: ${player.roadsBuilt}本');
      print('    資源: ${player.totalResources}枚');
    }

    print('\nゲーム本編を開始できます！');
  }
}

/// 配置ルール検証の例
void examplePlacementValidation() {
  final gameService = GameService();
  final buildingService = BuildingService();

  final gameState = gameService.startNewGame(
    gameId: 'validation_test',
    playerNames: ['Alice', 'Bob'],
    playerColors: [PlayerColor.red, PlayerColor.blue],
  );

  final setupState = buildingService.startSetupPhase(gameState);

  print('=== 配置ルール検証の例 ===\n');

  // 例1: 距離ルールのチェック
  print('1. 距離ルールのチェック:');
  final vertexId1 = gameState.vertices.first.id;
  final canPlace1 = buildingService.checkDistanceRule(gameState, vertexId1);
  print('   頂点 $vertexId1: ${canPlace1 ? "配置可能" : "配置不可"}');

  // 例2: 道路接続のチェック
  print('\n2. 道路接続のチェック:');
  final playerId = gameState.players.first.id;
  final isConnected = buildingService.isConnectedByRoad(gameState, vertexId1, playerId);
  print('   頂点 $vertexId1: ${isConnected ? "道路接続あり" : "道路接続なし"}');

  // 例3: 配置可能な場所の取得
  print('\n3. 配置可能な場所の取得:');
  final availableVertices = buildingService.getAvailableVertices(gameState, setupState);
  print('   配置可能な頂点数: ${availableVertices.length}');

  // 例4: 現在の配置タイプの取得
  print('\n4. 現在の配置タイプ:');
  final placementType = buildingService.getCurrentPlacementType(setupState);
  print('   配置すべきもの: $placementType');
}

void main() {
  print('BuildingService使用例\n');
  print('==========================================\n');

  // 例1: 初期配置フェーズの完全な流れ
  // exampleInitialSetup();

  // 例2: 配置ルール検証
  examplePlacementValidation();
}
