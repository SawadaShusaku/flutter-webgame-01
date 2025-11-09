# Phase 4: 盗賊システム基礎

## タスク概要
盗賊（robber）システムの基礎を実装してください。

## 実装内容

### 1. `lib/models/robber.dart` を作成
- Robber クラス
- 現在位置（HexTile ID）

### 2. `lib/services/robber_service.dart` を作成
- 盗賊移動ロジック: `moveRobber(GameState, String hexId)`
- 資源を奪う: `stealResourceFrom(Player target, Player thief)`
- 対象プレイヤー取得: `getPlayersOnHex(GameState, String hexId)`
- 7が出た時の処理: `handleSevenRolled(GameState)`

### 3. `lib/services/discard_service.dart` を作成
- 資源破棄処理
- 8枚以上持っているプレイヤーを検出
- 半分の枚数を破棄させる

### 4. `lib/ui/widgets/robber/robber_widget.dart` を作成
- 盗賊アイコンの表示
- 現在いるタイルに表示

### 5. GameState に robber フィールド追加
- `game_state.dart` を更新
- `Robber? robber` フィールド追加
- 初期位置は砂漠タイル

## 重要ポイント
- 盗賊は資源を生産しないタイルに配置
- 盗賊がいるタイルは資源生産されない
- 7が出たら:
  1. 8枚以上のプレイヤーは半分破棄
  2. 現在プレイヤーが盗賊を移動
  3. 対象プレイヤーから1枚ランダムに奪う

完成したら commit してください。
