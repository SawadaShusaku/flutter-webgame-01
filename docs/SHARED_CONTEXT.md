# 設計リファクタリング - 共有コンテキスト

## 最終更新
2025-11-09 (設計リファクタリング開始)

---

## 🎯 今回の並列開発の目標

### Pane D: PlayerType追加とモデル拡張（30分）
**担当**: PlayerType enum, Player/PlayerConfigクラス拡張

### Pane E: 簡易CPU実装（1時間）
**担当**: CPUService作成、ランダム行動ロジック、GameController統合

### Pane F: 画面統合（1.5時間）
**担当**: GameScreen統合、SetupPhaseWidget分離、フェーズ切り替え

### メイン: GitHub Actions修正とテスト
**担当**: リリースモード変更、統合テスト

---

## 📋 共通インターフェース（変更禁止）

### GameController（既存）
以下のメソッドは**既に実装済み**。Pane D/E/Fは既存メソッドのシグネチャを変更しない。

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
GamePhase? get currentPhase;

// ターン管理
Future<void> endTurn();

// 建設モード（Phase Cで追加済み）
BuildMode get buildMode;
void setBuildMode(BuildMode mode);
Future<void> onVertexTapped(String vertexId);
Future<void> onEdgeTapped(String edgeId);
```

### GameState（既存）
以下の構造は**確定済み**。変更禁止。

```dart
class GameState {
  final String gameId;
  final List<Player> players;
  final List<HexTile> board;
  final List<Vertex> vertices;
  final List<Edge> edges;
  final List<Harbor> harbors;
  final List<DevelopmentCard> developmentCardDeck;
  final Robber robber;

  // 可変状態
  GamePhase phase;
  int currentPlayerIndex;
  DiceRoll? lastDiceRoll;
  List<GameEvent> eventLog;
  // ...
}
```

### Player（既存 - Pane Dが拡張）
**既存フィールド（変更禁止）**:
```dart
class Player {
  final String id;
  final String name;
  final PlayerColor color;
  Map<ResourceType, int> resources;
  List<DevelopmentCard> developmentCards;
  int victoryPoints;
  int settlementsBuilt;
  int citiesBuilt;
  int roadsBuilt;
  bool hasLongestRoad;
  bool hasLargestArmy;
  int knightsPlayed;
  // ...
}
```

**Pane Dが追加するフィールド**:
```dart
  final PlayerType playerType;  // 新規追加
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
1. **モデルの既存フィールド変更禁止**
   - Player, GameState, Vertex, Edge の既存 public プロパティを変更しない
   - 新規フィールド追加はOK（Pane DのPlayerType追加など）

2. **GameControllerの既存メソッドのシグネチャ変更禁止**
   - 戻り値の型を変更しない
   - 引数を追加/削除しない
   - 新規メソッド追加はOK

3. **相対importの使用禁止**
   - 全て `package:test_web_app/...` 形式を使用

4. **Phase B/Cの成果物を壊さない**
   - DiceRoller, BuildMode, onVertexTapped, onEdgeTapped は既に実装済み
   - これらを削除・変更しない

### Pane D専用の禁止事項
- GameController, CPUService, 画面系ファイルを編集しない
- モデルファイル（Player, PlayerConfig, enums）のみ編集

### Pane E専用の禁止事項
- 画面ファイル（*_screen.dart, *_widget.dart）を直接編集しない
- GameControllerには新規メソッド追加のみ（既存メソッド変更禁止）

### Pane F専用の禁止事項
- Player, PlayerConfig, enums.dart を編集しない
- CPUService を編集しない（使用のみ）
- GameControllerには新規メソッド追加のみ（既存メソッド変更禁止）

---

## ✅ 追加して良いもの

### Pane D（PlayerType追加）
- `lib/models/enums.dart` に PlayerType enum追加
- `lib/models/player.dart` に playerType フィールド追加
- `lib/models/player_config.dart` に playerType フィールド追加

### Pane E（簡易CPU実装）
- `lib/services/cpu_service.dart` 新規作成
- `lib/services/game_controller.dart` に以下を追加：
  - `final CPUService _cpuService = CPUService();`
  - `endTurn()` メソッド内でCPU自動実行
  - `rollDice()` メソッド内でCPU自動続行

### Pane F（画面統合）
- `lib/ui/screens/game_screen.dart` 新規作成（統合画面）
- `lib/ui/widgets/phases/setup_phase_widget.dart` 新規作成
- `lib/ui/widgets/phases/normal_play_phase_widget.dart` 新規作成
- `lib/ui/screens/title_screen.dart` の遷移先変更

---

## 📡 ペイン間通信プロトコル

### ステータスファイル: `/tmp/pane_status.json`

各ペインは作業の進捗をこのファイルに記録します。

#### 初期状態
```json
{
  "pane_d_player_type": {
    "status": "pending",
    "timestamp": "2025-11-09T00:00:00Z",
    "progress": 0,
    "message": "",
    "changes": [],
    "warnings": []
  },
  "pane_e_cpu": {
    "status": "pending",
    "timestamp": "2025-11-09T00:00:00Z",
    "progress": 0,
    "message": "",
    "changes": [],
    "warnings": []
  },
  "pane_f_screen": {
    "status": "pending",
    "timestamp": "2025-11-09T00:00:00Z",
    "progress": 0,
    "message": "",
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

### ヘルパースクリプト

#### `/tmp/update_pane_status.sh`
```bash
/tmp/update_pane_status.sh <pane_name> <status> <progress> <message>

# 例
/tmp/update_pane_status.sh pane_d_player_type in_progress 50 "PlayerType enum追加完了"
```

#### `/tmp/add_pane_change.sh`
```bash
/tmp/add_pane_change.sh <pane_name> <change_description>

# 例
/tmp/add_pane_change.sh pane_d_player_type "Player.playerTypeフィールド追加"
```

#### `/tmp/add_pane_warning.sh`
```bash
/tmp/add_pane_warning.sh <pane_name> <warning_description>

# 例
/tmp/add_pane_warning.sh pane_e_cpu "GameController.endTurn()メソッドを変更しました"
```

### 定期チェック（30分ごと）
```bash
# 他ペインの状態確認
cat /tmp/pane_status.json | jq '.'

# 特定ペインの変更確認
cat /tmp/pane_status.json | jq '.pane_d_player_type.changes'
cat /tmp/pane_status.json | jq '.pane_e_cpu.warnings'
```

---

## 📝 変更履歴

### 2025-11-09 00:00 - 開始前
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

### Pane D（PlayerType追加）
- [ ] PlayerType enumを追加
- [ ] Player.playerTypeフィールド追加
- [ ] PlayerConfig.playerTypeフィールド追加
- [ ] 相対importを使用していないか
- [ ] `/tmp/pane_status.json`に変更を記録したか
- [ ] ビルドエラー0件

### Pane E（簡易CPU実装）
- [ ] CPUServiceクラス作成
- [ ] GameController.endTurn()にCPU自動実行追加
- [ ] GameController.rollDice()にCPU自動続行追加
- [ ] Pane Dの完了を待ってから開始（PlayerType依存）
- [ ] 相対importを使用していないか
- [ ] `/tmp/pane_status.json`に変更を記録したか
- [ ] ビルドエラー0件

### Pane F（画面統合）
- [ ] GameScreen作成
- [ ] SetupPhaseWidget作成
- [ ] NormalPlayPhaseWidget作成（既存のNormalPlayScreenを活用）
- [ ] TitleScreenの遷移先変更
- [ ] Pane D, Eの完了を待ってから開始
- [ ] 相対importを使用していないか
- [ ] `/tmp/pane_status.json`に変更を記録したか
- [ ] ビルドエラー0件

---

## 🎯 成功基準

### 統合時に以下が全て動作すること
1. プレイヤー1は人間操作できる
2. プレイヤー2-4はCPUが自動行動する
3. 初期配置フェーズ→通常プレイフェーズが連続する
4. サイコロ、建設機能が引き続き動作する
5. ビルドエラーが0件
6. リリースビルドが成功する

### 統合手順
1. Pane Dの変更をコミット
2. Pane Eの変更をコミット（Pane D完了後）
3. Pane Fの変更をコミット（Pane D/E完了後）
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
3. 設計ドキュメント（`docs/design-refactoring-plan.md`）を確認
4. それでも不明な場合はメインエージェントに質問

---

## 📚 参考ドキュメント

- [設計リファクタリング計画](./design-refactoring-plan.md) - **必読**
- [開発計画書](./catan-game-plan.md)
- [並列開発の教訓](./lessons-learned-parallel-development.md)
