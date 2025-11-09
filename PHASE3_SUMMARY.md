# Phase 3: 通常建設サービスと資源消費 - 実装完了

## 実装完了日
2025-11-09

## 概要
通常プレイフェーズでの建設機能を実装しました。資源の消費、ルール検証、建設実行を分離した設計で、テスト可能で拡張性の高いアーキテクチャを実現しています。

## 実装したファイル

### 1. `building_costs.dart` (137行)
**役割**: 建設コストの定義

**主な機能**:
- 各建設物のコスト定義（定数）
  - 道路: 木材x1, レンガx1
  - 集落: 木材x1, レンガx1, 羊毛x1, 小麦x1
  - 都市: 小麦x2, 鉱石x3
  - 発展カード: 羊毛x1, 小麦x1, 鉱石x1
- 建設物の上限定義
  - 集落: 5個
  - 都市: 4個
  - 道路: 15本

**使用例**:
```dart
// コストを取得
final settlementCost = BuildingCosts.settlement;
print(BuildingCosts.costToString(settlementCost));
// => "木材x1 レンガx1 羊毛x1 小麦x1"

// 建設可能かチェック
if (BuildingLimits.canBuild(player.roadsBuilt, BuildingLimits.maxRoads)) {
  // 道路を建設可能
}
```

### 2. `resource_manager.dart` (273行)
**役割**: 資源の消費・追加・チェック

**主な機能**:
- 資源の消費: `consumeResources(Player, Map<ResourceType, int>)`
- 資源の追加: `addResources(Player, Map<ResourceType, int>)`
- 資源チェック: `hasEnoughResources(Player, Map<ResourceType, int>)`
- 資源交換: `exchangeResources()`
- 銀行取引: `bankTrade()`
- 不足資源の計算: `getMissingResources()`

**使用例**:
```dart
final resourceManager = ResourceManager();

// 資源を消費
final success = resourceManager.consumeResources(
  player,
  BuildingCosts.settlement,
);

// 不足している資源を確認
final missing = resourceManager.getMissingResources(
  player,
  BuildingCosts.city,
);
```

### 3. `validation_service.dart` (342行)
**役割**: 建設ルールの検証

**主な機能**:
- 集落配置の検証
  - 距離ルール（隣接頂点に建設物がないか）
  - 道路接続ルール
  - 資源チェック
  - 建設上限チェック
- 都市アップグレードの検証
- 道路配置の検証
- 発展カード購入の検証

**使用例**:
```dart
final validationService = ValidationService();

// 集落を建設できるか検証
final result = validationService.validateSettlementPlacement(
  gameState,
  vertexId,
  playerId,
);

if (result.isValid) {
  // 建設可能
} else {
  print(result.errorMessage); // エラーメッセージ
}
```

### 4. `construction_service.dart` (386行)
**役割**: 通常フェーズでの建設ロジック

**主な機能**:
- 集落建設: `buildSettlementNormalPhase()`
- 都市アップグレード: `upgradeToCity()`
- 道路建設: `buildRoadNormalPhase()`
- 発展カード購入: `buyDevelopmentCard()`
- 建設可能な場所の取得:
  - `getAvailableSettlementLocations()`
  - `getAvailableRoadLocations()`
  - `getUpgradeableSettlements()`

**使用例**:
```dart
final constructionService = ConstructionService();

// 集落を建設
final result = constructionService.buildSettlementNormalPhase(
  gameState,
  vertexId,
  playerId,
);

if (result.success) {
  print('建設成功: ${result.data}');
} else {
  print('建設失敗: ${result.errorMessage}');
}

// 建設可能な場所を取得
final availableLocations = constructionService.getAvailableSettlementLocations(
  gameState,
  playerId,
);
```

## アーキテクチャ設計

### 責任の分離

```
┌─────────────────────┐
│ ConstructionService │  ← メインロジック
└──────────┬──────────┘
           │
           ├─→ ValidationService  ← ルール検証
           │
           └─→ ResourceManager    ← 資源管理
```

1. **ConstructionService**: 建設の実行とオーケストレーション
2. **ValidationService**: ルールの検証
3. **ResourceManager**: 資源の操作
4. **BuildingCosts**: コスト定義（定数）

### 処理フロー

```
建設リクエスト
  ↓
ValidationService
  ├─ ルール検証
  ├─ 資源チェック
  └─ 上限チェック
  ↓
ResourceManager
  └─ 資源消費
  ↓
ConstructionService
  ├─ 建設物配置
  ├─ カウント更新
  ├─ 勝利点更新
  └─ イベントログ記録
  ↓
結果を返す
```

## 技術的な特徴

### 1. Result型パターン
```dart
class ConstructionResult {
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic>? data;
}
```
- 成功/失敗を明示的に扱う
- エラーメッセージを含む
- 追加データを柔軟に返せる

### 2. Validation型パターン
```dart
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
}
```
- 検証結果を明確に表現
- ユーザーフレンドリーなエラーメッセージ

### 3. 依存性注入
```dart
ConstructionService({
  ResourceManager? resourceManager,
  ValidationService? validationService,
})
```
- テスト時にモックを注入可能
- サービス間の疎結合

### 4. 定数クラスによるコスト管理
```dart
class BuildingCosts {
  BuildingCosts._(); // インスタンス化不可
  static const Map<ResourceType, int> settlement = {...};
}
```
- 変更を防ぐ
- 一箇所でコストを管理

## コード統計

```
合計: 2,987行（前回: 1,819行）
追加: 1,168行

新規ファイル:
├── building_costs.dart:        137行
├── resource_manager.dart:      273行
├── validation_service.dart:    342行
└── construction_service.dart:  386行
```

## 完了条件チェック

- [x] `construction_service.dart` を作成
  - [x] 通常フェーズでの建設ロジック
  - [x] 集落建設: `buildSettlementNormalPhase()`
  - [x] 都市アップグレード: `upgradeToCity()`
  - [x] 道路建設: `buildRoadNormalPhase()`
  - [x] 資源消費処理を含める

- [x] `resource_manager.dart` を作成
  - [x] 資源の消費: `consumeResources()`
  - [x] 資源の追加: `addResources()`
  - [x] 資源チェック: `hasEnoughResources()`

- [x] `validation_service.dart` を作成
  - [x] ルール検証機能
  - [x] `BuildingCosts` から正確なコストを取得
  - [x] プレイヤーの建設数制限をチェック
  - [x] 都市アップグレード時は集落数を-1、都市数を+1

## 使用例

### 完全な建設フロー

```dart
import 'lib/services/services.dart';

// サービスのインスタンス作成
final constructionService = ConstructionService();

// 1. 建設可能な場所をチェック
final availableLocations = constructionService.getAvailableSettlementLocations(
  gameState,
  currentPlayerId,
);

print('建設可能な場所: ${availableLocations.length}個');

// 2. 集落を建設
if (availableLocations.isNotEmpty) {
  final result = constructionService.buildSettlementNormalPhase(
    gameState,
    availableLocations.first,
    currentPlayerId,
  );

  if (result.success) {
    print('集落建設成功！');
    print('勝利点: ${result.data!['victoryPoints']}');
  } else {
    print('失敗: ${result.errorMessage}');
  }
}

// 3. 都市にアップグレード
final upgradeableSettlements = constructionService.getUpgradeableSettlements(
  gameState,
  currentPlayerId,
);

if (upgradeableSettlements.isNotEmpty) {
  final result = constructionService.upgradeToCity(
    gameState,
    upgradeableSettlements.first,
    currentPlayerId,
  );

  if (result.success) {
    print('都市アップグレード成功！');
    print('都市数: ${result.data!['citiesBuilt']}');
    print('勝利点: ${result.data!['victoryPoints']}');
  }
}

// 4. 発展カードを購入
final cardResult = constructionService.buyDevelopmentCard(
  gameState,
  currentPlayerId,
);

if (cardResult.success) {
  print('発展カード購入: ${cardResult.data!['cardType']}');
}
```

## 既存サービスとの関係

### 移行パス

**従来** (game_service.dart):
```dart
gameService.buildSettlement(gameState, vertexId, playerId);
gameService.upgradeToCity(gameState, vertexId, playerId);
```

**Phase 3** (construction_service.dart):
```dart
constructionService.buildSettlementNormalPhase(gameState, vertexId, playerId);
constructionService.upgradeToCity(gameState, vertexId, playerId);
```

### 統合方法

今後、`game_service.dart` の建設メソッドを `construction_service.dart` に委譲することで、コードの重複を解消できます。

```dart
// game_service.dart (リファクタリング後)
class GameService {
  final ConstructionService _constructionService;

  bool buildSettlement(GameState gameState, String vertexId, String playerId) {
    final result = _constructionService.buildSettlementNormalPhase(
      gameState, vertexId, playerId,
    );
    return result.success;
  }
}
```

## 次のステップ

### Phase 4: 交易システム（予定）
- [ ] 銀行交易UI連携
- [ ] 港の実装
- [ ] プレイヤー間交渉UI

### リファクタリング（推奨）
- [ ] `game_service.dart` の建設メソッドを `construction_service.dart` に委譲
- [ ] `resource_service.dart` の一部機能を `resource_manager.dart` に統合

## 参考

- **タスク**: `TASK.md`
- **ゲーム設計**: `docs/catan-game-plan.md`
- **実装サマリー**: `IMPLEMENTATION_SUMMARY.md`
