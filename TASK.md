# Services担当タスク

## 役割
ビジネスロジックの実装

## フェーズ1の担当タスク

### 1. BoardGenerator (services/board_generator.dart)
- 19枚の六角形タイルを配置
- 数字チップ（2-12）をランダムに配置
- 砂漠タイルの処理
- 頂点（Vertex）と辺（Edge）の生成

### 2. ResourceService (services/resource_service.dart)
- 資源の配布ロジック
- サイコロの目に応じた資源生産
- 資源の譲渡・交換処理

### 3. GameService (services/game_service.dart)
- ゲーム全体の管理
- ターン管理
- ゲーム状態の更新

## 依存関係
- models/ のデータモデルに依存
- HexTile, Vertex, Edge, Player, ResourceType などを使用

## 成果物
- lib/services/board_generator.dart
- lib/services/resource_service.dart
- lib/services/game_service.dart

## 完了条件
- 六角形ボードが正しく生成される
- 資源配布ロジックが動作する
- ゲーム状態を管理できる
