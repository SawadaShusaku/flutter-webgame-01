# Services Layer - カタン風ボードゲーム

このディレクトリには、カタン風ボードゲームのビジネスロジック層が実装されています。

## 実装済みサービス

### 1. BuildingService (`building_service.dart`) ⭐ NEW

**役割**: 建設物の配置管理と初期配置フェーズの実装

**主な機能**:

**初期配置フェーズ（フェーズ2）**:
- プレイヤーの順番決め（サイコロによる）
- 1巡目の配置管理（順番通り）
  - 各プレイヤーが集落1つ + 道路1本を配置
- 2巡目の配置管理（逆順）
  - 各プレイヤーが集落1つ + 道路1本を配置
  - 2巡目の集落周辺から初期資源を獲得
- 配置進行状況の追跡

**配置ルールの検証**:
- 距離ルールのチェック（隣接する頂点に建設物がないか）
- 道路接続ルールのチェック（通常プレイ時）
- 配置可能な頂点・辺の取得

**使用例**:
```dart
final buildingService = BuildingService();

// 初期配置フェーズを開始
var setupState = buildingService.startSetupPhase(gameState);

// プレイヤーが順番決めのためにサイコロを振る
for (final player in gameState.players) {
  final (newSetupState, roll) = buildingService.rollForOrder(
    setupState,
    player.id,
  );
  setupState = newSetupState;
  print('${player.name}: $roll');
}

// 配置順を確定
final (_, finalSetupState, orderedPlayerIds) =
    buildingService.finalizePlayerOrder(gameState, setupState);
setupState = finalSetupState;

// 1巡目: 集落を配置
final availableVertices = buildingService.getAvailableVertices(
  gameState,
  setupState,
);

final (_, newState1, success1) = buildingService.placeInitialSettlement(
  gameState,
  setupState,
  availableVertices.first,
  currentPlayerId,
);

// 1巡目: 道路を配置
final availableEdges = buildingService.getAvailableEdges(
  gameState,
  newState1,
);

final (_, newState2, success2) = buildingService.placeInitialRoad(
  gameState,
  newState1,
  availableEdges.first,
  currentPlayerId,
);

// 初期配置が完了したかチェック
if (buildingService.isSetupComplete(setupState)) {
  print('初期配置完了！ゲーム本編開始');
}
```

**状態管理**:
- `SetupState`: 初期配置フェーズの状態を管理
  - `SetupPhase`: 現在のフェーズ（順番決め、1巡目集落、1巡目道路、2巡目集落、2巡目道路、完了）
  - 現在のプレイヤーインデックス
  - 逆順フラグ（2巡目）
  - 最後に配置した集落のID

### 2. BoardGenerator (`board_generator.dart`)

**役割**: ゲームボードの生成

**主な機能**:
- 19枚の六角形タイルの配置（3-4-5-4-3の標準レイアウト）
- 地形タイプのランダム配置（森x4, 丘陵x3, 牧草地x4, 畑x4, 山x3, 砂漠x1）
- 数字チップ（2-12）のランダム配置
- 砂漠タイルの処理（数字チップなし、初期盗賊配置）
- 頂点（Vertex）の自動生成と隣接関係の構築
- 辺（Edge）の自動生成

**使用例**:
```dart
final generator = BoardGenerator();
final board = generator.generateBoard(randomize: true);

// 生成結果
print('タイル数: ${board.hexTiles.length}'); // 19
print('頂点数: ${board.vertices.length}');   // 54
print('辺数: ${board.edges.length}');       // 72
print('砂漠タイルID: ${board.desertHexId}');
```

### 3. ResourceService (`resource_service.dart`)

**役割**: 資源の管理と配布

**主な機能**:
- サイコロの目に応じた資源配布
  - 集落: 1枚の資源
  - 都市: 2枚の資源
  - 盗賊がいるタイルは生産しない
- 初期配置時の資源配布（2巡目の集落周辺から各1枚）
- 銀行取引（4:1レート）
- 港取引（2:1または3:1レート）
- プレイヤー間の資源交換
- 7が出た時の資源破棄処理（8枚以上で半分）
- 盗賊による資源強奪（ランダムに1枚）
- 建設コストの管理と支払い

**使用例**:
```dart
final service = ResourceService();

// サイコロの目に応じた資源配布
final resourcesGained = service.distributeResources(8, gameState);

// 銀行取引（木材4枚→小麦1枚）
final success = service.bankTrade(
  player,
  ResourceType.lumber,
  ResourceType.grain,
);

// プレイヤー間取引
service.playerTrade(
  proposer,
  target,
  {ResourceType.lumber: 2},  // 提供
  {ResourceType.brick: 1},   // 要求
);
```

### 4. GameService (`game_service.dart`)

**役割**: ゲーム全体の進行管理

**主な機能**:
- 新しいゲームの開始（2-4人プレイヤー対応）
- 発展カードデッキの生成（計25枚）
- サイコロを振る処理
- 建設物の配置
  - 道路（木材1+レンガ1）
  - 集落（木材1+レンガ1+羊毛1+小麦1）
  - 都市（小麦2+鉱石3）
- 発展カードの購入（羊毛1+小麦1+鉱石1）
- ターン管理
- 距離ルールのチェック（集落間は道路2本分以上離れる）
- 道路接続のチェック
- 勝利条件の判定（10勝利点）
- 盗賊の移動
- 最長交易路の更新
- 最大騎士力の更新
- ゲームイベントのログ記録

**使用例**:
```dart
final gameService = GameService();

// 新しいゲームを開始
final gameState = gameService.startNewGame(
  gameId: 'game_001',
  playerNames: ['Alice', 'Bob', 'Charlie', 'Diana'],
  playerColors: [
    PlayerColor.red,
    PlayerColor.blue,
    PlayerColor.green,
    PlayerColor.yellow,
  ],
  randomizeBoard: true,
);

// サイコロを振る
final diceRoll = gameService.rollDice(gameState);
print('出目: ${diceRoll.total}');

// 集落を建設
final success = gameService.buildSettlement(
  gameState,
  'v_10',
  'player_1',
);

// ターン終了
gameService.endTurn(gameState);

// 勝利条件チェック
final winner = gameService.checkVictoryCondition(gameState);
if (winner != null) {
  print('勝者: ${winner.name}');
}
```

## モデル依存関係

このservices層は、`/root/worktrees/models/lib/models/` のデータモデルに依存しています：

- `enums.dart`: ResourceType, TerrainType, PlayerColor, BuildingType, GamePhase等
- `hex_tile.dart`: 六角形タイル
- `vertex.dart`: 頂点
- `edge.dart`: 辺
- `building.dart`: 建設物
- `road.dart`: 道路
- `player.dart`: プレイヤー
- `game_state.dart`: ゲーム状態
- `development_card.dart`: 発展カード

## アーキテクチャ

```
models (データ層)
  ↓
services (ビジネスロジック層) ← 今ここ
  ↓
repositories (永続化層)
  ↓
ui (プレゼンテーション層)
```

## 完了条件チェックリスト

- [x] 六角形ボードが正しく生成される
  - 19枚のタイル配置
  - 数字チップのランダム配置
  - 頂点と辺の自動生成
- [x] 資源配布ロジックが動作する
  - サイコロの目に応じた配布
  - 集落/都市の区別
  - 盗賊による生産停止
- [x] ゲーム状態を管理できる
  - ターン管理
  - 建設物の配置
  - 勝利条件の判定

## 今後の拡張予定

- [ ] より正確な最長交易路の計算アルゴリズム（深さ優先探索）
- [ ] 発展カードの効果実装
- [ ] AI（CPU）プレイヤーの実装
- [ ] セーブ/ロード機能との連携

## テスト

各サービスは単体テストが可能な設計になっています：

```dart
// テスト例
void main() {
  group('BoardGenerator', () {
    test('19枚のタイルを生成する', () {
      final generator = BoardGenerator();
      final board = generator.generateBoard();
      expect(board.hexTiles.length, 19);
    });
  });
}
```
