# 設計リファクタリング計画

## 現状の問題点

### 1. 初期配置とゲームモードが分離している
**問題**：
- `SetupScreen`（初期配置）と`NormalPlayScreen`（通常プレイ）が完全に別のWidget
- `SetupScreen`は独自の状態管理（`_settlements`, `_roads`, `_currentPlayerIndex`）
- `GameController`と連携していない
- 初期配置完了後、通常プレイに遷移する際に状態が引き継がれない

**設計的におかしい理由**：
- ゲームフェーズは連続しているのに、Screenが分断されている
- `GamePhase.setup`が存在するのに、`SetupScreen`は`GameController`を使わない
- データの二重管理（SetupScreenとGameState）

### 2. プレイヤータイプ（人間/CPU）が未実装
**問題**：
- `Player`クラスにはプレイヤータイプの情報がない
- 全プレイヤーが人間操作を前提としている
- CPU用の自動行動ロジックがない

**要件**：
- プレイヤー1: 人間
- プレイヤー2-4: CPU（ランダム）

---

## 修正方針

### Phase 1: プレイヤータイプの追加（30分）

#### 1.1 PlayerTypeの追加
`lib/models/enums.dart`:
```dart
/// プレイヤータイプ
enum PlayerType {
  human,   // 人間
  cpu,     // CPU
}
```

#### 1.2 Playerクラスの拡張
`lib/models/player.dart`:
```dart
class Player {
  final String id;
  final String name;
  final PlayerColor color;
  final PlayerType playerType;  // 追加

  Player({
    required this.id,
    required this.name,
    required this.color,
    this.playerType = PlayerType.human,  // デフォルトは人間
    // ... 既存のパラメータ
  });
}
```

#### 1.3 GameConfigの修正
`lib/models/game_config.dart` (または `player_config.dart`):
```dart
class PlayerConfig {
  final String name;
  final PlayerColor color;
  final PlayerType playerType;  // 追加

  const PlayerConfig({
    required this.name,
    required this.color,
    this.playerType = PlayerType.human,
  });
}
```

---

### Phase 2: 簡易CPU実装（1時間）

#### 2.1 CPUサービス作成
`lib/services/cpu_service.dart`:
```dart
import 'dart:math';
import 'package:test_web_app/models/game_state.dart';
import 'package:test_web_app/models/player.dart';
import 'package:test_web_app/models/enums.dart';

/// CPUプレイヤーの行動を管理するサービス
class CPUService {
  final Random _random = Random();

  /// CPUのターンを実行
  Future<void> executeCPUTurn(GameState state, Player player) async {
    if (player.playerType != PlayerType.cpu) return;

    // フェーズごとの処理
    switch (state.phase) {
      case GamePhase.setup:
        await _executeSetupPhase(state, player);
        break;
      case GamePhase.normalPlay:
        await _executeNormalPlayTurn(state, player);
        break;
      default:
        break;
    }
  }

  /// 初期配置フェーズのCPU行動
  Future<void> _executeSetupPhase(GameState state, Player player) async {
    // ランダムに建設可能な頂点を選ぶ
    final availableVertices = state.vertices
        .where((v) => v.buildingType == null && _isValidSettlementPlacement(state, v.id))
        .toList();

    if (availableVertices.isNotEmpty) {
      final selectedVertex = availableVertices[_random.nextInt(availableVertices.length)];
      // TODO: GameControllerのbuildSettlementを呼ぶ
    }

    // 道路も同様
    final availableEdges = state.edges
        .where((e) => e.playerId == null && _isValidRoadPlacement(state, e.id))
        .toList();

    if (availableEdges.isNotEmpty) {
      final selectedEdge = availableEdges[_random.nextInt(availableEdges.length)];
      // TODO: GameControllerのbuildRoadを呼ぶ
    }
  }

  /// 通常プレイのCPU行動
  Future<void> _executeNormalPlayTurn(GameState state, Player player) async {
    await Future.delayed(const Duration(milliseconds: 500)); // CPU思考時間

    // 1. サイコロを振る（自動）
    // 2. 資源があれば建設（ランダム）
    final actions = <String>[];

    // 集落が建てられるか
    if (_canBuildSettlement(player)) {
      actions.add('settlement');
    }

    // 道路が建てられるか
    if (_canBuildRoad(player)) {
      actions.add('road');
    }

    // 都市が建てられるか
    if (_canBuildCity(player)) {
      actions.add('city');
    }

    // ランダムに1つ選んで実行
    if (actions.isNotEmpty) {
      final action = actions[_random.nextInt(actions.length)];
      // TODO: 該当する建設を実行
    }

    // 建設しない場合はターン終了
  }

  bool _canBuildSettlement(Player player) {
    return player.resources[ResourceType.lumber]! >= 1 &&
           player.resources[ResourceType.brick]! >= 1 &&
           player.resources[ResourceType.wool]! >= 1 &&
           player.resources[ResourceType.grain]! >= 1 &&
           player.settlementsBuilt < 5;
  }

  bool _canBuildRoad(Player player) {
    return player.resources[ResourceType.lumber]! >= 1 &&
           player.resources[ResourceType.brick]! >= 1 &&
           player.roadsBuilt < 15;
  }

  bool _canBuildCity(Player player) {
    return player.resources[ResourceType.grain]! >= 2 &&
           player.resources[ResourceType.ore]! >= 3 &&
           player.citiesBuilt < 4;
  }

  bool _isValidSettlementPlacement(GameState state, String vertexId) {
    // TODO: 距離ルールチェック
    return true;
  }

  bool _isValidRoadPlacement(GameState state, String edgeId) {
    // TODO: 接続ルールチェック
    return true;
  }
}
```

#### 2.2 GameControllerへの統合
`lib/services/game_controller.dart`:
```dart
class GameController extends ChangeNotifier {
  // 既存のコード...

  final CPUService _cpuService = CPUService();

  /// ターン終了時に次のプレイヤーがCPUなら自動実行
  Future<void> endTurn() async {
    _turnService.nextTurn(_state!);
    notifyListeners();

    // 次のプレイヤーがCPUなら自動実行
    if (_state!.currentPlayer.playerType == PlayerType.cpu) {
      await Future.delayed(const Duration(milliseconds: 300)); // UI更新待ち
      await _cpuService.executeCPUTurn(_state!, _state!.currentPlayer);
      notifyListeners();
    }
  }

  /// サイコロを振る（CPU自動実行対応）
  Future<void> rollDice() async {
    // 既存のロジック...

    // CPUプレイヤーの場合は自動的にターン続行
    if (_state!.currentPlayer.playerType == PlayerType.cpu) {
      await Future.delayed(const Duration(milliseconds: 1000));
      await _cpuService.executeCPUTurn(_state!, _state!.currentPlayer);
    }
  }
}
```

---

### Phase 3: 初期配置とゲームモードの統合（1.5時間）

#### 3.1 設計方針
**現在**：
```
TitleScreen → SetupScreen（独立） → NormalPlayScreen
                ↓
           GameControllerと無関係
```

**修正後**：
```
TitleScreen → GameScreen（統一）
                ↓
           GamePhaseで表示切り替え
           - GamePhase.setup → 初期配置UI表示
           - GamePhase.normalPlay → 通常プレイUI表示
```

#### 3.2 実装案

##### Option A: GamePhaseで1つのScreenを切り替え（推奨）
`lib/ui/screens/game_screen.dart`:
```dart
class GameScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, child) {
        if (controller.state == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // フェーズごとにUIを切り替え
        switch (controller.currentPhase) {
          case GamePhase.setup:
            return SetupPhaseWidget(); // 初期配置UI
          case GamePhase.normalPlay:
            return NormalPlayPhaseWidget(); // 通常プレイUI
          case GamePhase.robberPlacement:
            return RobberPlacementWidget(); // 盗賊配置UI
          case GamePhase.gameOver:
            return GameOverWidget(); // ゲーム終了UI
          default:
            return const SizedBox();
        }
      },
    );
  }
}
```

**メリット**：
- GameControllerと完全に連携
- フェーズ遷移がスムーズ
- 状態の一元管理

##### Option B: SetupScreenをGameControllerに統合（既存コードを活かす）
`SetupScreen`を改修して`GameController`を使うように変更。

**デメリット**：
- 既存の`SetupScreen`のロジックを大幅に書き換え
- 二重管理のリスク

**結論**: Option Aを採用

---

## 実装順序

### Step 1: GitHub Actionsをリリースモードに変更（5分）
`.github/workflows/build-android.yml`:
```yaml
- name: Build APK
  run: flutter build apk --release  # --debug → --release
```

### Step 2: PlayerType追加（30分）
- `lib/models/enums.dart` - PlayerType enum追加
- `lib/models/player.dart` - playerTypeフィールド追加
- `lib/models/player_config.dart` - playerTypeフィールド追加

### Step 3: 簡易CPU実装（1時間）
- `lib/services/cpu_service.dart` - 新規作成
- `lib/services/game_controller.dart` - CPU自動実行統合

### Step 4: 初期配置統合（1.5時間）
- `lib/ui/screens/game_screen.dart` - 統合画面作成
- `lib/ui/widgets/phases/setup_phase_widget.dart` - 初期配置UI分離
- `lib/ui/widgets/phases/normal_play_phase_widget.dart` - 通常プレイUI分離
- `lib/ui/screens/title_screen.dart` - 遷移先をGameScreenに変更

### Step 5: テスト・デバッグ（30分）
- ビルド確認
- CPU動作確認
- フェーズ遷移確認

---

## 合計見積もり時間
- Step 1: 5分
- Step 2: 30分
- Step 3: 1時間
- Step 4: 1.5時間
- Step 5: 30分

**合計**: 約3.5時間

---

## 禁止事項
1. 既存のGameStateを変更しない（PlayerのフィールドのみOK）
2. Phase B/Cで実装した機能（DiceRoller, BuildMode）を壊さない
3. 相対importを使わない

---

## 検証項目
- [ ] リリースビルドが成功する
- [ ] プレイヤー1は人間操作できる
- [ ] プレイヤー2-4はCPUが自動で行動する
- [ ] 初期配置からゲーム終了まで一貫したGameController管理
- [ ] ビルドエラー0件
