# Phase 7: 勝利判定とゲーム終了 - 実装完了

## 実装内容

### 1. VictoryService (`victory_service.dart`)

勝利点の計算と勝利判定を行うサービス。

**主な機能:**
- 勝利点の詳細計算
  - 集落: 1点 × 建設数
  - 都市: 2点 × 建設数
  - 発展カード（勝利点）: 1点 × 枚数
  - 最長交易路: 2点（5本以上の道路が必要）
  - 最大騎士力: 2点（3枚以上の騎士カード使用が必要）
- 10点到達の判定
- 勝者の決定（自分の手番でのみ勝利）

**主なクラス:**
- `VictoryService`: 勝利判定ロジック
- `VictoryPointBreakdown`: 勝利点の詳細内訳
- `VictoryCheckResult`: 勝利判定結果

**使用例:**
```dart
final victoryService = VictoryService();

final result = victoryService.checkVictory(
  players: gameState.players,
  currentPlayerId: currentPlayerId,
  vertices: gameState.vertices,
  edges: gameState.edges,
);

if (result.hasWinner) {
  print('Winner: ${result.winnerId}');
  print('Points: ${result.winnerBreakdown!.totalPoints}');
}
```

### 2. GameOverScreen (`ui/screens/game_over_screen.dart`)

ゲーム終了時の画面。

**主な機能:**
- 勝者の発表
- 全プレイヤーの最終スコア表示
- 各プレイヤーの得点内訳
- ゲーム統計の表示（オプション）
- 新規ゲーム・メニューに戻るボタン

**表示内容:**
- 勝利宣言（トロフィーアイコン付き）
- スコアボード（ランキング順）
- 得点内訳（集落、都市、カード、最長交易路、最大騎士力）
- ゲーム統計（ターン数、プレイ時間、建設数など）

**使用例:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => GameOverScreen(
      victoryResult: victoryResult,
      statistics: GameStatistics(
        totalTurns: 50,
        duration: '45:30',
        totalRoadsBuilt: 35,
        totalSettlementsBuilt: 12,
        totalCitiesBuilt: 8,
        developmentCardsUsed: 15,
      ),
      onNewGame: () => startNewGame(),
      onBackToMenu: () => Navigator.popUntil(context, (route) => route.isFirst),
    ),
  ),
);
```

### 3. GameStateManager (`game_state_manager.dart`)

ゲーム状態の保存・読み込みを管理するサービス。

**主な機能:**
- ゲーム状態のJSON保存
- ゲーム状態の読み込み
- セーブデータ一覧管理
- オートセーブ機能
- セーブデータの削除

**使用例:**
```dart
final gameStateManager = GameStateManager();

// ゲームを保存
await gameStateManager.saveGame(
  gameState: gameState.toJson(),
  saveId: 'manual_save_1',
  description: 'Before final turn',
);

// オートセーブ（ターン終了時など）
await gameStateManager.autoSave(gameState.toJson());

// ゲームを読み込み
final saveData = await gameStateManager.loadGame('manual_save_1');
if (saveData != null) {
  // ゲーム状態を復元
  gameState = GameState.fromJson(saveData.gameState);
}

// セーブ一覧を取得
final saves = await gameStateManager.listSaves();
for (final save in saves) {
  print('${save.id}: Turn ${save.turnNumber}, saved at ${save.savedAt}');
}
```

### 4. GameLogWidget (`ui/widgets/log/game_log_widget.dart`)

ゲームログを表示するウィジェット。

**主な機能:**
- イベントタイプごとのアイコン表示
- フィルタリング機能（イベント種別、プレイヤー）
- タイムスタンプ表示
- 自動スクロール
- 色分け表示

**イベント種別:**
- サイコロ (🎲)
- 資源生産 (🌾)
- 資源破棄 (🗑️)
- 道路建設 (🛣️)
- 集落建設 (🏠)
- 都市建設 (🏙️)
- 発展カード購入/使用 (🎁)
- 交易 (↔️)
- 盗賊移動/資源強奪 (🦹)
- 勝利 (🏆)
- ターン開始/終了

**使用例:**
```dart
final logEntries = <GameLogEntry>[
  GameLogEntry(
    id: 'log_1',
    eventType: GameLogEventType.diceRoll,
    message: 'Player 1 rolled a 7',
    playerId: 'player1',
  ),
  // ... more entries
];

GameLogWidget(
  entries: logEntries,
  maxEntries: 100,
  autoScroll: true,
  enableFiltering: true,
  showTimestamp: true,
)
```

### 5. VictoryIntegrationExample (`victory_integration_example.dart`)

勝利判定をゲームフローに統合する方法を示すサンプルコード。

**主な機能:**
- ターン終了時の勝利判定
- 建設物建設時の得点チェック
- 発展カード使用時の処理
- ゲームログの記録
- 自動保存の実行

## 統合ガイド

### ゲームフローへの統合

1. **ターン終了時に勝利判定を実行**

```dart
final victoryResult = victoryService.checkVictory(
  players: gameState.players,
  currentPlayerId: gameState.currentPlayerId,
  vertices: gameState.vertices,
  edges: gameState.edges,
);

if (victoryResult.hasWinner) {
  // ゲーム終了画面に遷移
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => GameOverScreen(
        victoryResult: victoryResult,
      ),
    ),
  );
}
```

2. **建設物建設後に得点を更新**

```dart
void onBuildingBuilt(String playerId, BuildingType type) {
  // 建設物を追加
  gameState.addBuilding(playerId, type, vertex);

  // 勝利点を再計算（UI更新用）
  final breakdown = victoryService.calculateVictoryPoints(
    player: gameState.getPlayer(playerId),
    players: gameState.players,
    vertices: gameState.vertices,
    edges: gameState.edges,
  );

  // UI更新
  notifyListeners();

  // 10点到達の警告
  if (breakdown.hasWon) {
    showWarning('$playerId has ${breakdown.totalPoints} points!');
  }
}
```

3. **オートセーブの設定**

```dart
// 初期化時
gameStateManager.setAutoSaveEnabled(true);
gameStateManager.setAutoSaveInterval(1); // 毎ターン

// ターン終了時
await gameStateManager.autoSave(gameState.toJson());
```

## 依存関係

- `path_provider: ^2.1.5` - セーブデータの保存先ディレクトリを取得

## テスト

各サービスは独立してテスト可能です:

```dart
void testVictoryService() {
  final victoryService = VictoryService();

  // テストデータ
  final players = [...];
  final vertices = [...];
  final edges = [...];

  // 勝利判定をテスト
  final result = victoryService.checkVictory(
    players: players,
    currentPlayerId: 'player1',
    vertices: vertices,
    edges: edges,
  );

  assert(result.hasWinner == true);
  assert(result.winnerId == 'player1');
}
```

## 今後の改善点

1. **最長交易路の計算**: 現在は道路の総数を返していますが、実際には連続した道路の最長経路を計算する必要があります（DFS/BFS）。

2. **アニメーション**: 勝利画面への遷移時にアニメーションを追加。

3. **クラウドセーブ**: オンラインストレージへの保存機能。

4. **統計の詳細化**: より詳細なゲーム統計（最も生産された資源、最も使われたカードなど）。

5. **リプレイ機能**: ゲームログからゲームの流れを再生する機能。

## ファイル一覧

```
lib/
├── services/
│   ├── victory_service.dart               # 勝利判定サービス
│   ├── game_state_manager.dart            # セーブ/ロード管理
│   └── victory_integration_example.dart   # 統合サンプル
└── ui/
    ├── screens/
    │   └── game_over_screen.dart          # ゲーム終了画面
    └── widgets/
        └── log/
            └── game_log_widget.dart       # ゲームログウィジェット
```
