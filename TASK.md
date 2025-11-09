# Phase 3: プレイヤーハンドと建設UI

## タスク概要
プレイヤーの手札表示と建設アクションUIを実装してください。

## 実装内容

### 1. `lib/ui/widgets/player/player_hand_widget.dart` を作成
- プレイヤーの資源カード表示
- 各資源タイプごとの枚数表示
- リソースアイコン（絵文字）と数値
- コンパクトな横並びレイアウト
- 例: 🌲×3 🧱×2 🐑×1 🌾×0 ⛰️×2

### 2. `lib/ui/widgets/player/player_info_widget.dart` を作成
- プレイヤー情報カード
- 表示内容:
  - プレイヤー名とカラー
  - 勝利点数
  - 建設数（集落/都市/道路）
  - 発展カード枚数

### 3. `lib/ui/widgets/actions/build_actions_widget.dart` を作成
- 建設アクションボタンパネル
- ボタン:
  - 集落建設（コスト表示付き）
  - 都市アップグレード（コスト表示付き）
  - 道路建設（コスト表示付き）
  - 発展カード購入（コスト表示付き）
- 資源不足時はボタン無効化

### 4. `lib/ui/widgets/actions/victory_points_widget.dart` を作成
- 詳細な勝利点内訳表示

## 重要ポイント
- `constants.dart` の `BuildingCosts` を使用
- `GameColors` でプレイヤーカラー取得

完成したら commit してください。
