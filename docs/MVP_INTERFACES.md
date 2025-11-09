# MVP共通インターフェース定義

**最終更新**: 2025-11-09
**対象スプリント**: MVP（勝利点+ゲーム終了+7の処理+銀行交易）

---

## 🎯 MVPスコープ

### 実装する機能
1. **勝利点計算とゲーム終了判定** (Pane G)
2. **7の処理（資源破棄+盗賊）** (Pane I, J)
3. **銀行交易** (Pane L)

### 実装しない機能
- 港交易
- プレイヤー間交渉
- 発展カード
- 最長交易路・最大騎士力の計算

---

## 📋 共通データモデル（変更禁止）

### 既存モデル（全ペイン使用可能）

```dart
// lib/models/game_state.dart
class GameState {
  final String gameId;
  final List<Player> players;
  final List<HexTile> board;
  final List<Vertex> vertices;
  final List<Edge> edges;
  final List<Harbor> harbors;
  final Robber robber;

  GamePhase phase;
  int currentPlayerIndex;
  DiceRoll? lastDiceRoll;
  List<GameEvent> eventLog;

  Player get currentPlayer => players[currentPlayerIndex];
}

// lib/models/player.dart
class Player {
  final String id;
  final String name;
  final PlayerColor color;
  final PlayerType playerType;

  Map<ResourceType, int> resources;
  List<DevelopmentCard> developmentCards;
  int victoryPoints;  // 現在未使用
  int settlementsBuilt;
  int citiesBuilt;
  int roadsBuilt;
  bool hasLongestRoad;  // 現在未使用
  bool hasLargestArmy;  // 現在未使用
  int knightsPlayed;
}

// lib/models/robber.dart
class Robber {
  String currentHexId;  // 現在盗賊がいるタイルID
}

// lib/models/enums.dart
enum GamePhase {
  setup,
  normalPlay,
  resourceDiscard,  // 7が出た時の資源破棄フェーズ（MVP新規）
  robberPlacement,  // 盗賊配置フェーズ
  trading,
  gameOver,         // ゲーム終了（MVP新規）
}
```

---

## 🔧 共通サービスメソッド（各ペインが追加）

### GameController（既存メソッド - 変更禁止）

```dart
// lib/services/game_controller.dart
class GameController extends ChangeNotifier {
  GameState? get state;
  Player? get currentPlayer;
  GamePhase? get currentPhase;

  // サイコロ
  Future<void> rollDice();
  DiceRoll? get lastDiceRoll;
  bool get hasRolledDice;

  // 建設
  Future<bool> buildSettlement(String vertexId);
  Future<bool> buildRoad(String edgeId);
  Future<bool> buildCity(String vertexId);
  bool canBuildSettlement();
  bool canBuildRoad();
  bool canBuildCity();

  // ターン管理
  Future<void> endTurn();

  // 建設モード
  BuildMode get buildMode;
  void setBuildMode(BuildMode mode);
  Future<void> onVertexTapped(String vertexId);
  Future<void> onEdgeTapped(String edgeId);
}
```

### Pane G: VictoryPointServiceの追加メソッド

```dart
// lib/services/victory_point_service.dart（新規作成）
class VictoryPointService {
  /// プレイヤーの勝利点を計算
  ///
  /// 計算対象:
  /// - 集落: 1点/個
  /// - 都市: 2点/個
  ///
  /// 計算対象外（今回のMVPでは未実装）:
  /// - 最長交易路: 2点
  /// - 最大騎士力: 2点
  /// - 発展カード（勝利点）: 1点/枚
  int calculateVictoryPoints(GameState state, Player player);

  /// 全プレイヤーの勝利点を再計算
  void updateAllVictoryPoints(GameState state);

  /// 勝利条件を満たしているかチェック
  /// 10勝利点以上で勝利
  bool checkVictoryCondition(Player player);

  /// 勝者を取得（いない場合はnull）
  Player? getWinner(GameState state);
}
```

### Pane G: GameControllerへの追加メソッド

```dart
// lib/services/game_controller.dart（追加分）
class GameController extends ChangeNotifier {
  final VictoryPointService _victoryPointService = VictoryPointService();

  /// 勝利点を再計算（建設後に自動実行）
  void updateVictoryPoints() {
    if (_state == null) return;
    _victoryPointService.updateAllVictoryPoints(_state!);
    notifyListeners();
  }

  /// 勝利条件チェック（ターン終了時に自動実行）
  void checkGameOver() {
    if (_state == null) return;

    final winner = _victoryPointService.getWinner(_state!);
    if (winner != null) {
      _state!.phase = GamePhase.gameOver;
      notifyListeners();
    }
  }
}
```

### Pane I: ResourceDiscardServiceの追加メソッド

```dart
// lib/services/resource_discard_service.dart（新規作成）
class ResourceDiscardService {
  /// 資源破棄が必要なプレイヤーを取得
  /// 8枚以上所持しているプレイヤーが対象
  List<Player> getPlayersNeedingDiscard(GameState state) {
    return state.players.where((p) {
      final total = p.resources.values.fold(0, (a, b) => a + b);
      return total >= 8;
    }).toList();
  }

  /// 破棄すべき枚数を計算（総数の半分、切り捨て）
  int getDiscardCount(Player player) {
    final total = player.resources.values.fold(0, (a, b) => a + b);
    return total ~/ 2;
  }

  /// 資源を破棄
  bool discardResources(Player player, Map<ResourceType, int> resourcesToDiscard) {
    // バリデーション: 指定枚数が正しいか
    final totalDiscard = resourcesToDiscard.values.fold(0, (a, b) => a + b);
    final requiredDiscard = getDiscardCount(player);
    if (totalDiscard != requiredDiscard) return false;

    // バリデーション: 所持数を超えていないか
    for (final entry in resourcesToDiscard.entries) {
      if (player.resources[entry.key]! < entry.value) return false;
    }

    // 破棄実行
    for (final entry in resourcesToDiscard.entries) {
      player.resources[entry.key] = player.resources[entry.key]! - entry.value;
    }

    return true;
  }
}
```

### Pane I: GameControllerへの追加メソッド

```dart
// lib/services/game_controller.dart（追加分）
class GameController extends ChangeNotifier {
  final ResourceDiscardService _discardService = ResourceDiscardService();

  /// 7が出た時の処理開始
  Future<void> startSevenPhase() async {
    if (_state == null) return;

    // 資源破棄が必要なプレイヤーを確認
    final needDiscard = _discardService.getPlayersNeedingDiscard(_state!);

    if (needDiscard.isNotEmpty) {
      _state!.phase = GamePhase.resourceDiscard;
      notifyListeners();
    } else {
      // 破棄不要なら盗賊配置へ
      _state!.phase = GamePhase.robberPlacement;
      notifyListeners();
    }
  }

  /// 資源破棄実行（UIから呼ばれる）
  Future<bool> executeDiscard(Player player, Map<ResourceType, int> resources) async {
    if (_state == null) return false;

    final success = _discardService.discardResources(player, resources);
    if (success) {
      notifyListeners();

      // 全員の破棄が完了したか確認
      final stillNeedDiscard = _discardService.getPlayersNeedingDiscard(_state!);
      if (stillNeedDiscard.isEmpty) {
        _state!.phase = GamePhase.robberPlacement;
        notifyListeners();
      }
    }

    return success;
  }
}
```

### Pane J: RobberServiceの追加メソッド

```dart
// lib/services/robber_service.dart（新規作成）
class RobberService {
  /// 盗賊を移動
  bool moveRobber(GameState state, String hexId) {
    // 現在と同じタイルには移動できない
    if (state.robber.currentHexId == hexId) return false;

    state.robber.currentHexId = hexId;
    return true;
  }

  /// 指定タイルに隣接するプレイヤーを取得
  /// 手番プレイヤー以外で、そのタイルに建設物を持つプレイヤー
  List<Player> getAdjacentPlayers(GameState state, String hexId, Player currentPlayer) {
    final adjacentPlayers = <Player>[];

    // そのタイルの頂点を取得
    final adjacentVertices = state.vertices.where((v) =>
      v.adjacentHexIds.contains(hexId)
    );

    for (final vertex in adjacentVertices) {
      if (vertex.playerId != null && vertex.playerId != currentPlayer.id) {
        final player = state.players.firstWhere((p) => p.id == vertex.playerId);
        if (!adjacentPlayers.contains(player)) {
          adjacentPlayers.add(player);
        }
      }
    }

    return adjacentPlayers;
  }

  /// ランダムに資源を1枚奪う
  /// 資源がない場合はnullを返す
  ResourceType? stealResource(Player targetPlayer) {
    // 所持資源のリストを作成
    final availableResources = <ResourceType>[];
    for (final entry in targetPlayer.resources.entries) {
      for (int i = 0; i < entry.value; i++) {
        availableResources.add(entry.key);
      }
    }

    if (availableResources.isEmpty) return null;

    // ランダムに1枚選択
    final random = Random();
    final stolenResource = availableResources[random.nextInt(availableResources.length)];

    // 資源を減らす
    targetPlayer.resources[stolenResource] = targetPlayer.resources[stolenResource]! - 1;

    return stolenResource;
  }
}
```

### Pane J: GameControllerへの追加メソッド

```dart
// lib/services/game_controller.dart（追加分）
class GameController extends ChangeNotifier {
  final RobberService _robberService = RobberService();

  /// 盗賊移動（UIから呼ばれる）
  Future<bool> moveRobber(String hexId) async {
    if (_state == null || _state!.phase != GamePhase.robberPlacement) {
      return false;
    }

    final success = _robberService.moveRobber(_state!, hexId);
    if (success) {
      notifyListeners();
    }

    return success;
  }

  /// 資源を奪う（盗賊移動後に呼ばれる）
  Future<ResourceType?> stealFromPlayer(String targetPlayerId) async {
    if (_state == null) return null;

    final targetPlayer = _state!.players.firstWhere((p) => p.id == targetPlayerId);
    final stolenResource = _robberService.stealResource(targetPlayer);

    if (stolenResource != null) {
      // 手番プレイヤーに資源を追加
      _state!.currentPlayer.resources[stolenResource] =
        _state!.currentPlayer.resources[stolenResource]! + 1;

      notifyListeners();
    }

    // 盗賊フェーズ終了、通常プレイに戻る
    _state!.phase = GamePhase.normalPlay;
    notifyListeners();

    return stolenResource;
  }

  /// 盗賊配置可能なプレイヤーを取得
  List<Player> getRobberTargets(String hexId) {
    if (_state == null) return [];
    return _robberService.getAdjacentPlayers(_state!, hexId, _state!.currentPlayer);
  }
}
```

### Pane L: TradeServiceの追加メソッド

```dart
// lib/services/trade_service.dart（既存ファイル、メソッド追加）
class TradeService {
  // 既存のメソッド...

  /// 銀行交易を実行（4:1レート）
  ///
  /// @param player 交易するプレイヤー
  /// @param give 提供する資源（4枚）
  /// @param receive 受け取る資源（1枚）
  /// @return 成功したらtrue
  bool executeBankTrade(Player player, ResourceType give, ResourceType receive) {
    // バリデーション: 4枚所持しているか
    if (player.resources[give]! < 4) return false;

    // 交易実行
    player.resources[give] = player.resources[give]! - 4;
    player.resources[receive] = player.resources[receive]! + 1;

    return true;
  }

  /// 銀行交易が可能かチェック
  bool canBankTrade(Player player, ResourceType give) {
    return player.resources[give]! >= 4;
  }

  /// 交易可能な資源のリストを取得
  List<ResourceType> getTradeableResources(Player player) {
    return ResourceType.values.where((r) => player.resources[r]! >= 4).toList();
  }
}
```

### Pane L: GameControllerへの追加メソッド

```dart
// lib/services/game_controller.dart（追加分）
class GameController extends ChangeNotifier {
  // TradeServiceは既に存在

  /// 銀行交易実行（UIから呼ばれる）
  Future<bool> executeBankTrade(ResourceType give, ResourceType receive) async {
    if (_state == null || _state!.phase != GamePhase.normalPlay) {
      return false;
    }

    final success = _tradeService.executeBankTrade(_state!.currentPlayer, give, receive);
    if (success) {
      notifyListeners();
    }

    return success;
  }

  /// 銀行交易可能か
  bool canBankTrade(ResourceType give) {
    if (_state == null) return false;
    return _tradeService.canBankTrade(_state!.currentPlayer, give);
  }

  /// 交易可能な資源リスト
  List<ResourceType> getTradeableResources() {
    if (_state == null) return [];
    return _tradeService.getTradeableResources(_state!.currentPlayer);
  }
}
```

---

## 🚫 禁止事項（全ペイン共通）

### 1. 既存メソッドのシグネチャ変更禁止
- `buildSettlement`, `buildRoad`, `buildCity`等の既存メソッドを変更しない
- 戻り値の型、引数を変更しない

### 2. 既存モデルのフィールド変更禁止
- `Player`, `GameState`, `Vertex`, `Edge`の既存フィールドを変更しない
- 新規フィールド追加はOK（例: MVP後に`hasLongestRoad`を計算用に使う）

### 3. 相対importの使用禁止
- 全て `package:test_web_app/...` 形式を使用

### 4. 他ペイン担当ファイルの編集禁止
- Pane G: `lib/services/victory_point_service.dart`, `lib/ui/screens/game_over_screen.dart`のみ
- Pane I: `lib/services/resource_discard_service.dart`, `lib/ui/widgets/resource_discard_dialog.dart`のみ
- Pane J: `lib/services/robber_service.dart`, `lib/ui/widgets/robber_placement_overlay.dart`のみ
- Pane L: `lib/ui/widgets/bank_trade_dialog.dart`のみ（TradeServiceは既存）

---

## ✅ 追加して良いもの

### 全ペイン
- GameControllerに新規メソッド追加（上記インターフェース準拠）
- 新規サービスクラス作成
- 新規Widgetクラス作成
- GameEventにイベント追加（例: `GameEventType.bankTradeCompleted`）

---

## 📡 ペイン間の連携

### GameControllerへのメソッド追加順序
1. **Pane G**: `updateVictoryPoints()`, `checkGameOver()`
2. **Pane I**: `startSevenPhase()`, `executeDiscard()`
3. **Pane J**: `moveRobber()`, `stealFromPlayer()`, `getRobberTargets()`
4. **Pane L**: `executeBankTrade()`, `canBankTrade()`, `getTradeableResources()`

すべてGameControllerの**末尾に追加**することで、競合を最小化

---

## 🔍 検証項目

### 各ペイン完了時
1. `flutter analyze` でエラー0件
2. 相対importなし
3. GameControllerのメソッド追加のみ（既存メソッド変更なし）
4. `/tmp/pane_status.json`に進捗記録

### 統合時
1. 1ペインずつマージ
2. マージごとにビルド確認
3. 最終的に全機能の動作確認

---

## 📚 参考ドキュメント

- カタンルール: `/root/test_web_app/docs/catan-game-plan.md`
- 既存実装: `/root/test_web_app/lib/services/game_controller.dart`
- 前回の並列開発: `/root/test_web_app/docs/SHARED_CONTEXT.md`
