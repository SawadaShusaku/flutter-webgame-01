# Phase 3: 通常建設サービスと資源消費

## タスク概要
通常プレイフェーズでの建設機能を実装してください。

## 実装内容

### 1. `lib/services/construction_service.dart` を作成
- 通常フェーズでの建設ロジック
- 集落建設: `buildSettlementNormalPhase()`
- 都市アップグレード: `upgradeToCity()`
- 道路建設: `buildRoadNormalPhase()`
- 資源消費処理を含める

### 2. `lib/services/resource_manager.dart` を作成
- 資源の消費: `consumeResources(Player, Map<ResourceType, int>)`
- 資源の追加: `addResources(Player, Map<ResourceType, int>)`
- 資源チェック: `hasEnoughResources(Player, Map<ResourceType, int>)`

### 3. 既存の `game_controller.dart` を拡張
- `upgradeToCity(String vertexId)` メソッド追加
- 通常フェーズの建設を `construction_service` に委譲

## 重要ポイント
- `validation_service.dart` を使ってルール検証
- `BuildingCosts` から正確なコストを取得
- プレイヤーの建設数制限をチェック
- 都市アップグレード時は集落数を-1、都市数を+1

完成したら commit してください。
