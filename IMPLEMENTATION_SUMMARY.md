# Services Layer 実装サマリー

## 実装完了日

2025-11-09

## 実装したサービス

### ✅ フェーズ1: 基盤構築（完了）

1. **BoardGenerator** (`lib/services/board_generator.dart`)
   - 19枚の六角形タイル配置
   - 数字チップのランダム配置
   - 砂漠タイルの処理
   - 54個の頂点と72本の辺の自動生成

2. **ResourceService** (`lib/services/resource_service.dart`)
   - サイコロの目に応じた資源配布
   - 初期資源の配布
   - 銀行取引（4:1）
   - 港取引（2:1, 3:1）
   - プレイヤー間取引
   - 資源破棄処理
   - 盗賊による資源強奪

3. **GameService** (`lib/services/game_service.dart`)
   - 新規ゲーム開始
   - 発展カードデッキ生成
   - サイコロを振る
   - 建設物配置
   - ターン管理
   - 勝利条件判定
   - 最長交易路・最大騎士力の更新

### ✅ フェーズ2: 初期配置（完了）

4. **BuildingService** (`lib/services/building_service.dart`)
   - 初期配置フェーズの完全実装
     - プレイヤー順番決め
     - 1巡目の配置管理（順番通り）
     - 2巡目の配置管理（逆順）
     - 初期資源の自動配布
   - 配置ルール検証
     - 距離ルールチェック
     - 道路接続ルールチェック
   - 配置可能な場所の自動判定

## ファイル構成

```
lib/services/
├── board_generator.dart          # ボード生成
├── resource_service.dart         # 資源管理
├── game_service.dart            # ゲーム全体管理
├── building_service.dart        # 建設物配置・初期配置 ⭐ NEW
├── building_service_example.dart # 使用例 ⭐ NEW
├── services.dart                # エクスポート用
└── README.md                    # ドキュメント
```

## 使用方法

### 基本的な流れ

```dart
import 'lib/services/services.dart';

// 1. サービスのインスタンス作成
final gameService = GameService();
final buildingService = BuildingService();

// 2. ゲーム開始
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

// 3. 初期配置フェーズ
var setupState = buildingService.startSetupPhase(gameState);

// 3-1. 順番決め
for (final player in gameState.players) {
  final (newState, roll) = buildingService.rollForOrder(setupState, player.id);
  setupState = newState;
}

final (_, finalSetupState, orderedPlayerIds) =
    buildingService.finalizePlayerOrder(gameState, setupState);
setupState = finalSetupState;

// 3-2. 各プレイヤーが集落と道路を配置（1巡目 + 2巡目）
while (!buildingService.isSetupComplete(setupState)) {
  final playerId = orderedPlayerIds[setupState.currentPlayerIndex];

  // 集落配置
  final vertices = buildingService.getAvailableVertices(gameState, setupState);
  final (_, state1, _) = buildingService.placeInitialSettlement(
    gameState, setupState, vertices.first, playerId,
  );

  // 道路配置
  final edges = buildingService.getAvailableEdges(gameState, state1);
  final (_, state2, _) = buildingService.placeInitialRoad(
    gameState, state1, edges.first, playerId,
  );

  setupState = state2;
}

// 4. ゲーム本編開始
final diceRoll = gameService.rollDice(gameState);
// ...
```

## 技術的な特徴

### 1. 不変性と純粋関数

すべてのサービスメソッドは、状態を直接変更せず、新しい状態を返します：

```dart
// ❌ 悪い例（状態を直接変更）
void placeSettlement(GameState state, String vertexId) {
  state.vertices[0].building = Building(...);
}

// ✅ 良い例（新しい状態を返す）
(GameState, SetupState, bool) placeInitialSettlement(
  GameState gameState,
  SetupState setupState,
  String vertexId,
  String playerId,
) {
  // ... 処理
  return (updatedGameState, updatedSetupState, success);
}
```

### 2. レコード型による複数戻り値

Dart 3の新機能を活用：

```dart
final (gameState, setupState, success) = buildingService.placeInitialSettlement(
  gameState,
  setupState,
  vertexId,
  playerId,
);
```

### 3. 責任の分離

各サービスは単一の責任を持ちます：

- **BuildingService**: 配置ルールと初期配置フェーズ
- **ResourceService**: 資源の管理と配布
- **GameService**: ゲーム全体の進行
- **BoardGenerator**: ボード生成のみ

## テスト可能性

すべてのサービスは依存性注入に対応しており、テストが容易です：

```dart
// テスト用に固定シード付きのRandomを注入
final testService = BuildingService(
  random: Random(42),
);

// モックのResourceServiceを注入
final mockResourceService = MockResourceService();
final testBuildingService = BuildingService(
  resourceService: mockResourceService,
);
```

## 完了条件チェックリスト

### フェーズ1: 基盤構築
- [x] 六角形ボードが正しく生成される
- [x] 資源配布ロジックが動作する
- [x] ゲーム状態を管理できる

### フェーズ2: 初期配置
- [x] 集落・道路の配置ルール検証が動作する
  - [x] 距離ルールのチェック
  - [x] 道路接続ルールのチェック
- [x] 初期配置フェーズのロジックが動作する
  - [x] プレイヤー順番決め
  - [x] 1巡目の配置（順番通り）
  - [x] 2巡目の配置（逆順）
- [x] 初期資源の配布が動作する
  - [x] 2巡目の集落周辺から自動配布

## 次のステップ

### フェーズ3: ゲーム本編（未実装）
- [ ] サイコロを振って資源生産
- [ ] 建設メニュー（道路、集落、都市）
- [ ] ターン管理の詳細化

### フェーズ4: 交易システム（未実装）
- [ ] 銀行交易UI連携
- [ ] 港の実装
- [ ] プレイヤー間交渉UI

### フェーズ5以降
- [ ] 発展カードの効果実装
- [ ] 盗賊と7の処理
- [ ] AI（CPU）プレイヤー

## 参考ファイル

- **使用例**: `building_service_example.dart`
- **詳細ドキュメント**: `README.md`
- **ゲーム設計**: `../docs/catan-game-plan.md`

## 依存関係

```
models/ (データ層)
  ↓
services/ (ビジネスロジック層) ← 今ここ
  ├── BoardGenerator
  ├── ResourceService
  ├── GameService
  └── BuildingService ⭐ NEW
  ↓
repositories/ (永続化層) ← 未実装
  ↓
ui/ (プレゼンテーション層) ← 未実装
```
