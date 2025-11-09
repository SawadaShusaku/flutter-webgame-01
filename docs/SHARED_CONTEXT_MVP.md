# MVP並列開発 - 共有コンテキスト

## 最終更新
2025-11-09 (MVP開発開始)

---

## 🎯 今回の並列開発の目標

### MVP = 完全にプレイ可能な最小構成

**4ペイン同時起動、推定時間: 4-5時間（並列実行）**

| ペイン | 担当機能 | 推定時間 |
|-------|---------|---------|
| **Pane G** | 勝利点計算+ゲーム終了判定 | 90分 |
| **Pane I** | 資源破棄フェーズUI | 60分 |
| **Pane J** | 盗賊移動+資源強奪 | 2.5時間 |
| **Pane L** | 銀行交易UI+ロジック | 2時間 |

**並列実行**: 最長タスク基準で2.5時間

---

## 📋 共通インターフェース（必読）

**最重要ドキュメント**: `/root/test_web_app/docs/MVP_INTERFACES.md`

このファイルに以下が定義されています：
- 既存モデル（変更禁止）
- 各ペインが追加するメソッド
- GameControllerへの追加メソッド仕様
- 禁止事項・追加して良いもの

**作業開始前に必ず読んでください**

---

## 🚫 禁止事項（全ペイン共通）

### 1. 既存メソッドのシグネチャ変更禁止
以下のメソッドは変更禁止：
- `buildSettlement`, `buildRoad`, `buildCity`
- `rollDice`, `endTurn`
- `setBuildMode`, `onVertexTapped`, `onEdgeTapped`

**新規メソッド追加はOK**

### 2. 既存モデルのフィールド変更禁止
- `Player`, `GameState`, `Vertex`, `Edge`の既存フィールド変更禁止
- 新規フィールド追加はOK

### 3. 相対importの使用禁止
- 全て `package:test_web_app/...` 形式

### 4. 他ペイン担当ファイルの編集禁止

#### Pane G専用
- `lib/services/victory_point_service.dart` (新規作成)
- `lib/ui/screens/game_over_screen.dart` (新規作成)

#### Pane I専用
- `lib/services/resource_discard_service.dart` (新規作成)
- `lib/ui/widgets/resource_discard_dialog.dart` (新規作成)

#### Pane J専用
- `lib/services/robber_service.dart` (新規作成)
- `lib/ui/widgets/robber_placement_overlay.dart` (新規作成)

#### Pane L専用
- `lib/ui/widgets/bank_trade_dialog.dart` (新規作成)
- `lib/services/trade_service.dart` (メソッド追加のみ、既存は変更禁止)

### 5. GameControllerへのメソッド追加は末尾に
全ペインがGameControllerにメソッドを追加するため、必ず**ファイル末尾**に追加

**追加順序**:
1. Pane G: `updateVictoryPoints()`, `checkGameOver()`
2. Pane I: `startSevenPhase()`, `executeDiscard()`
3. Pane J: `moveRobber()`, `stealFromPlayer()`, `getRobberTargets()`
4. Pane L: `executeBankTrade()`, `canBankTrade()`, `getTradeableResources()`

---

## ✅ 追加して良いもの

### 全ペイン
- GameControllerに新規メソッド追加（MVP_INTERFACES.md準拠）
- 新規サービスクラス作成
- 新規Widgetクラス作成
- GameEventにイベント追加

---

## 📡 ペイン間通信プロトコル

### ステータスファイル: `/tmp/pane_status_mvp.json`

各ペインは作業の進捗をこのファイルに記録します。

#### 初期状態
```json
{
  "pane_g_victory": {
    "status": "pending",
    "timestamp": "2025-11-09T00:00:00Z",
    "progress": 0,
    "message": "",
    "changes": [],
    "warnings": []
  },
  "pane_i_discard": {
    "status": "pending",
    "timestamp": "2025-11-09T00:00:00Z",
    "progress": 0,
    "message": "",
    "changes": [],
    "warnings": []
  },
  "pane_j_robber": {
    "status": "pending",
    "timestamp": "2025-11-09T00:00:00Z",
    "progress": 0,
    "message": "",
    "changes": [],
    "warnings": []
  },
  "pane_l_bank_trade": {
    "status": "pending",
    "timestamp": "2025-11-09T00:00:00Z",
    "progress": 0,
    "message": "",
    "changes": [],
    "warnings": []
  }
}
```

### ヘルパースクリプト

#### `/tmp/update_pane_status.sh`
```bash
/tmp/update_pane_status.sh <pane_name> <status> <progress> <message>

# 例
/tmp/update_pane_status.sh pane_g_victory in_progress 50 "VictoryPointService実装完了"
```

#### `/tmp/add_pane_change.sh`
```bash
/tmp/add_pane_change.sh <pane_name> <change_description>

# 例
/tmp/add_pane_change.sh pane_g_victory "GameController.updateVictoryPoints()追加"
```

#### `/tmp/add_pane_warning.sh`
```bash
/tmp/add_pane_warning.sh <pane_name> <warning_description>

# 例
/tmp/add_pane_warning.sh pane_g_victory "Player.victoryPointsフィールドを使用開始"
```

---

## 🔍 検証チェックリスト

### 各ペイン完了時

#### Pane G（勝利点計算+ゲーム終了）
- [ ] VictoryPointService作成
- [ ] GameOverScreen作成
- [ ] GameController.updateVictoryPoints()追加
- [ ] GameController.checkGameOver()追加
- [ ] 相対importなし
- [ ] `/tmp/pane_status_mvp.json`に進捗記録
- [ ] ビルドエラー0件

#### Pane I（資源破棄フェーズ）
- [ ] ResourceDiscardService作成
- [ ] ResourceDiscardDialog作成
- [ ] GameController.startSevenPhase()追加
- [ ] GameController.executeDiscard()追加
- [ ] 相対importなし
- [ ] `/tmp/pane_status_mvp.json`に進捗記録
- [ ] ビルドエラー0件

#### Pane J（盗賊システム）
- [ ] RobberService作成
- [ ] RobberPlacementOverlay作成
- [ ] GameController.moveRobber()追加
- [ ] GameController.stealFromPlayer()追加
- [ ] GameController.getRobberTargets()追加
- [ ] 相対importなし
- [ ] `/tmp/pane_status_mvp.json`に進捗記録
- [ ] ビルドエラー0件

#### Pane L（銀行交易）
- [ ] BankTradeDialog作成
- [ ] TradeService.executeBankTrade()追加
- [ ] GameController.executeBankTrade()追加
- [ ] GameController.canBankTrade()追加
- [ ] GameController.getTradeableResources()追加
- [ ] 相対importなし
- [ ] `/tmp/pane_status_mvp.json`に進捗記録
- [ ] ビルドエラー0件

---

## 🎯 成功基準

### 統合時に以下が全て動作すること
1. ✅ 勝利点が正しく計算される
2. ✅ 10勝利点で GamePhase.gameOver に遷移
3. ✅ GameOverScreenが表示される
4. ✅ 7が出たら資源破棄フェーズに遷移
5. ✅ 資源8枚以上のプレイヤーが半分破棄できる
6. ✅ 盗賊を移動できる
7. ✅ 隣接プレイヤーから資源を奪える
8. ✅ 銀行交易（4:1）ができる
9. ✅ ビルドエラー0件
10. ✅ CPU自動行動が継続して動作

### 統合手順
1. Pane Gの変更をマージ → ビルド確認
2. Pane Iの変更をマージ → ビルド確認
3. Pane Jの変更をマージ → ビルド確認
4. Pane Lの変更をマージ → ビルド確認
5. 統合テスト

---

## 📞 コミュニケーション方法

### 緊急時（ブロッカー発生）
1. `/tmp/pane_status_mvp.json`のstatusを`blocked`に変更
2. `warnings`フィールドに詳細を記載
3. メインエージェントに報告

### 質問がある時
1. `/root/test_web_app/docs/MVP_INTERFACES.md`を再確認
2. `/root/test_web_app/docs/SHARED_CONTEXT_MVP.md`を再確認
3. それでも不明な場合はメインエージェントに質問

---

## 📚 参考ドキュメント

- **[MVP共通インターフェース](./MVP_INTERFACES.md)** - 最重要
- [開発計画書](./catan-game-plan.md)
- [並列開発戦略](./parallel-development-strategy.md)
- [前回の並列開発](./SHARED_CONTEXT.md)
