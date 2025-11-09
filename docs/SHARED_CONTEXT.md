# Phase B + C 並列開発 - 共有コンテキスト

## 最終更新
2025-11-09 (開始前)

---

## 🎯 今回の並列開発の目標

### Pane 1: Phase B（サイコロ機能）
**担当**: サイコロ、資源生産、7の処理

### Pane 2: Phase C（建設インタラクション）
**担当**: タップ検出、建設モード、ハイライト表示

---

## 📋 共通インターフェース（変更禁止）

### GameController（既存）
以下のメソッドは**既に実装済み**。変更禁止。

```dart
// サイコロ関連
Future<void> rollDice();
DiceRoll? get lastDiceRoll;
bool get hasRolledDice;

// 建設関連
Future<bool> buildSettlement(String vertexId);
Future<bool> buildRoad(String edgeId);
Future<bool> buildCity(String vertexId);
bool canBuildSettlement();
bool canBuildCity();
bool canBuildRoad();

// ゲーム状態
GameState? get state;
Player? get currentPlayer;
```

### GameState（既存）
以下の構造は**確定済み**。変更禁止。

```dart
class GameState {
  final List<HexTile> board;
  final List<Vertex> vertices;
  final List<Edge> edges;
  final List<Player> players;
  DiceRoll? lastDiceRoll;
  Robber? robber;
  GamePhase phase;
  // ...
}
```

### Vertex（既存）
```dart
class Vertex {
  final String id;
  final Offset position;
  String? playerId;
  BuildingType? buildingType;
  // ...
}
```

### Edge（既存）
```dart
class Edge {
  final String id;
  final String vertex1Id;
  final String vertex2Id;
  String? playerId;
  // ...
}
```

---

## 🚫 禁止事項

### 全ペイン共通
1. **モデルの構造変更禁止**
   - GameState, Player, Vertex, Edge, HexTile の public プロパティを変更しない

2. **GameControllerの既存メソッドのシグネチャ変更禁止**
   - 戻り値の型を変更しない
   - 引数を追加/削除しない

3. **相対importの使用禁止**
   - 全て `package:test_web_app/...` 形式を使用

### Pane 1専用の禁止事項
- Vertex, Edge, GameBoardWidget を直接編集しない

### Pane 2専用の禁止事項
- DiceRoller, ResourceService を直接編集しない

---

## ✅ 追加して良いもの

### Pane 1（サイコロ機能）
- GameController に新しいメソッドを追加（既存メソッドは変更禁止）
- DiceRollerウィジェットの改修
- 新しいサービスクラス（DiceAnimationService など）

### Pane 2（建設インタラクション）
- GameController に新しいメソッドを追加（既存メソッドは変更禁止）
- VertexWidget/EdgeWidget にタップ検出を追加
- 新しいenum（BuildMode など）

---

## 📡 ペイン間通信プロトコル

### ステータスファイル: `/tmp/pane_status.json`

各ペインは作業の進捗をこのファイルに記録します。

#### 初期状態
```json
{
  "pane_b_dice": {
    "status": "pending",
    "timestamp": "2025-11-09T10:00:00",
    "progress": 0,
    "changes": [],
    "warnings": []
  },
  "pane_c_building": {
    "status": "pending",
    "timestamp": "2025-11-09T10:00:00",
    "progress": 0,
    "changes": [],
    "warnings": []
  }
}
```

#### ステータスの種類
- `pending`: 開始前
- `in_progress`: 実装中
- `testing`: テスト中
- `completed`: 完了
- `blocked`: 他ペインの完了待ち

### 更新タイミング

#### 作業開始時
```bash
# 最新の共有情報を確認
cat /tmp/pane_status.json
cat /root/test_web_app/docs/SHARED_CONTEXT.md

# 自分のステータスを更新
jq '.pane_b_dice.status = "in_progress" | .pane_b_dice.timestamp = now | .pane_b_dice.progress = 10' /tmp/pane_status.json > /tmp/pane_status.tmp && mv /tmp/pane_status.tmp /tmp/pane_status.json
```

#### 重要な変更を行った時
```bash
# 変更を記録
jq '.pane_b_dice.changes += ["GameControllerにanimateRollDice()追加"]' /tmp/pane_status.json > /tmp/pane_status.tmp && mv /tmp/pane_status.tmp /tmp/pane_status.json
```

#### 警告事項がある時
```bash
# 警告を記録
jq '.pane_b_dice.warnings += ["DiceRollerウィジェットのonRollコールバックを変更しました"]' /tmp/pane_status.json > /tmp/pane_status.tmp && mv /tmp/pane_status.tmp /tmp/pane_status.json
```

#### 作業完了時
```bash
# 完了を記録
jq '.pane_b_dice.status = "completed" | .pane_b_dice.progress = 100 | .pane_b_dice.timestamp = now' /tmp/pane_status.json > /tmp/pane_status.tmp && mv /tmp/pane_status.tmp /tmp/pane_status.json
```

---

## 📝 変更履歴

### 2025-11-09 10:00 - 開始前
- 共有コンテキスト作成
- ステータスファイル初期化

### [各ペインはここに変更を記録]

**フォーマット**:
```
### YYYY-MM-DD HH:MM - [Pane名] - [変更内容]
- 変更したファイル
- 追加したメソッド/プロパティ
- 影響範囲
```

---

## 🔍 検証チェックリスト

各ペインは完了前に以下を確認：

### Pane 1（サイコロ機能）
- [ ] `cat /tmp/pane_status.json` でPane 2の状態を確認
- [ ] GameControllerの既存メソッドを変更していないか
- [ ] 相対importを使用していないか
- [ ] `/tmp/pane_status.json`に変更を記録したか

### Pane 2（建設インタラクション）
- [ ] `cat /tmp/pane_status.json` でPane 1の状態を確認
- [ ] GameControllerの既存メソッドを変更していないか
- [ ] 相対importを使用していないか
- [ ] `/tmp/pane_status.json`に変更を記録したか

---

## 🎯 成功基準

### 統合時に以下が全て動作すること
1. サイコロを振ると資源が生産される
2. タップで建設位置を選択できる
3. ビルドエラーが0件
4. 両方の機能が同時に動作する

### 統合手順
1. Pane 1のブランチをmainにマージ
2. ビルド確認
3. Pane 2のブランチをmainにマージ
4. ビルド確認
5. 統合テスト

---

## 📞 コミュニケーション方法

### 緊急時（ブロッカー発生）
1. `/tmp/pane_status.json`のstatusを`blocked`に変更
2. `warnings`フィールドに詳細を記載
3. メインエージェントに報告

### 質問がある時
1. SHARED_CONTEXT.mdを再確認
2. `/tmp/pane_status.json`を確認
3. それでも不明な場合はメインエージェントに質問

---

## 📚 参考ドキュメント

- [開発計画書](./catan-game-plan.md)
- [並列開発の教訓](./lessons-learned-parallel-development.md)
- [次フェーズ計画](./next-phase-plan.md)
