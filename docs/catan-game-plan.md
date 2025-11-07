# カタン風ボードゲーム 開発計画書

## 目次
1. [ゲーム概要](#ゲーム概要)
2. [基本ルール](#基本ルール)
3. [ゲーム要素](#ゲーム要素)
4. [データ構造設計](#データ構造設計)
5. [アーキテクチャ設計](#アーキテクチャ設計)
6. [UI設計](#ui設計)
7. [実装フェーズ](#実装フェーズ)
8. [JSONファイル構造](#jsonファイル構造)

---

## ゲーム概要

### コンセプト
- カタン（Settlers of Catan）をベースにした資源管理・建設ボードゲーム
- シンプルなグラフィック（2D、幾何学図形）
- 3-4人プレイ対応（デフォルトは4人から実装）
- ゲーム状態はJSONファイルで保存・読み込み
- CPUプレイヤーは最初は簡易的なロジックで実装

### 勝利条件
- **自分の手番で**10勝利点を先に獲得したプレイヤーが勝利
- 他プレイヤーの手番中に10点に達しても、自分の手番まで勝利宣言できない
- 勝利宣言は自分の手番でのみ可能

---

## 基本ルール

### 1. ゲームの準備
- **各プレイヤーの初期持ち駒**：
  - 集落 x5
  - 都市 x4
  - 道路 x15
- 資源カードは5つの山に分類し、表向きで配置
- 発展カードデッキ（全25枚）を裏向きでシャッフル

### 2. ゲームボード
- 六角形タイル19枚で構成される島
- 各タイルは資源を生産（森、丘陵、牧草地、畑、山、砂漠）
- 各タイル（砂漠除く）には数字チップ（2-12）を配置

### 3. 資源の種類
| 資源 | 地形 | アイコン |
|------|------|----------|
| 木材 | 森 | 🌲 |
| レンガ | 丘陵 | 🧱 |
| 羊毛 | 牧草地 | 🐑 |
| 小麦 | 畑 | 🌾 |
| 鉱石 | 山 | ⛰️ |

### 4. 建設物と必要資源

#### 道路（1勝利点なし）
- 木材 x1 + レンガ x1

#### 集落（1勝利点）
- 木材 x1 + レンガ x1 + 羊毛 x1 + 小麦 x1

#### 都市（2勝利点）
- 小麦 x2 + 鉱石 x3（集落から昇格）

#### 発展カード（購入）
- 羊毛 x1 + 小麦 x1 + 鉱石 x1

### 5. 発展カード（全25枚）
- 騎士（14枚）：盗賊を移動
- 勝利点（5枚）：1勝利点
- 街道建設（2枚）：道路2本無料建設
- 資源独占（2枚）：特定資源を全員から奪取
- 資源発見（2枚）：好きな資源2枚獲得

#### 発展カード使用ルール
- **手番中に使用できるのは1枚のみ**（購入したターンは使用不可）
- 購入は何枚でも可能
- **未使用の騎士カードは「最大騎士力」計算に含めない**
- **勝利ポイントカードは勝利宣言時のみ公開**
- 手番中いつでも使用可能（サイコロを振る前でも可）
- 街道建設カードなどで手番外に10点に達しても、自分の手番まで勝利宣言不可

### 6. ターンの流れ

```
1. サイコロを振る（2個、2-12の目）
   - 出た目に対応するタイルが資源を生産
   - その周辺に集落/都市を持つプレイヤーが資源獲得（集落=1枚、都市=2枚）
   - **産出された資源は必ず受け取る**（自主的な受け取り拒否は禁止）
   - 山札に資源不足の場合、その種類の資源は誰も受け取れない
   - 7が出た場合：
     * **資源8枚以上**のプレイヤーは半分（切り捨て）を捨てる
     * 手番プレイヤーが盗賊を移動させる

2. 交易（任意）
   - 銀行交易：同じ資源4枚→好きな資源1枚
   - 港交易：特定の港を持っている場合、レート改善（2:1または3:1）
     * 港での取引は建設直後から可能
   - プレイヤー間交渉：自由交渉
     * **交渉は手番プレイヤーのみが主体**（他プレイヤーから持ちかけることは可能）
     * 資源の譲渡は禁止、**必ず等価交換**
     * 同じ資源を含む交換や予約取引は不可
     * **交渉の流れ**：
       1. 交渉ボタンを押して交渉モードに入る
       2. 自分の手札から提供する資源を選択（1枚以上、複数選択可）
       3. 交渉相手のプレイヤーを選択
       4. 要求する資源を選択（1枚以上、複数選択可）
       5. 交渉を提案し、相手が承諾/拒否
     * **情報の非対称性**：
       - 相手の手札の総数は全員に公開
       - 相手の手札の資源の種類・内訳は非公開
       - 要求した資源を相手が持っていない場合、交渉は成立しない

3. 建設（任意）
   - 道路、集落、都市の建設
   - 発展カードの購入・使用

4. ターン終了
```

### 7. 特別ルール

#### 最長交易路（2勝利点）
- 5本以上の連続した道路を持つプレイヤー
- 他プレイヤーが長い道路を作ったら移動

#### 最大騎士力（2勝利点）
- 3枚以上の騎士カードを使用したプレイヤー
- 他プレイヤーがより多く使ったら移動

#### 盗賊
- 7が出たとき、または騎士カード使用時に移動
- 砂漠タイルへの配置も可能
- 配置されたタイルは資源を生産しない
- 隣接するプレイヤーから資源1枚をランダムに奪う（資源を持っている場合）
- **盗賊は建設を阻止しない**
- **港は盗賊で機能停止しない**
- 騎士カード使用後、同じターンでサイコロの「7」が出れば、**盗賊を2度移動できる**

---

## ゲーム要素

### 初期配置フェーズ
1. **順番決め**：2つのサイコロを振り、出目の大きい順に配置順を決定（協会推奨）
2. **1巡目**：各プレイヤーが集落1つ + 道路1本を配置（順番通り、時計回り）
3. **2巡目**：各プレイヤーが集落1つ + 道路1本を配置（逆順、反時計回り）
4. 2巡目の集落周辺の資源を初期資源として獲得

### 配置ルール
- 集落は交差点（3つのタイルが接する点）に配置
- **距離ルール**：すべてのプレイヤーの集落・都市は、他の集落・都市から3交差点分（街道2本分）離れている必要がある
  - つまり、隣接する3方向の交差点に既存の集落・都市があってはならない
- 道路は辺（2つのタイルの境界）に配置
- **初期配置以外**では、道路は自分の集落/都市または自分の道路から連続している必要がある
- 一度建設した集落は撤去不可
- 港のある海岸や港のない海岸にも集落を配置可能

### 都市
- 都市は自分の集落の上に建設（アップグレード）
- 新たな場所には配置できない


---

## データ構造設計

### 1. ゲームボード

```dart
// 六角形タイル
class HexTile {
  final String id;           // "hex_0", "hex_1", ...
  final TerrainType terrain; // 地形タイプ
  final int? number;         // 数字チップ (2-12, 砂漠はnull)
  final Offset position;     // ボード上の座標
  final bool hasRobber;      // 盗賊がいるか
}

enum TerrainType {
  forest,    // 森（木材）
  hills,     // 丘陵（レンガ）
  pasture,   // 牧草地（羊毛）
  fields,    // 畑（小麦）
  mountains, // 山（鉱石）
  desert,    // 砂漠（資源なし）
}

// 頂点（集落/都市を配置）
class Vertex {
  final String id;              // "v_0_0", "v_0_1", ...
  final Offset position;        // 画面上の座標
  final List<String> adjacentHexIds;  // 隣接するタイルID
  final List<String> adjacentEdgeIds; // 隣接する辺ID
  Building? building;           // 建設物
}

// 辺（道路を配置）
class Edge {
  final String id;              // "e_0_0", "e_0_1", ...
  final String vertex1Id;       // 頂点1のID
  final String vertex2Id;       // 頂点2のID
  Road? road;                   // 道路
}

// 建設物
class Building {
  final String playerId;
  final BuildingType type;
}

enum BuildingType {
  settlement, // 集落（1VP）
  city,       // 都市（2VP）
}

// 道路
class Road {
  final String playerId;
}
```

### 2. プレイヤー

```dart
class Player {
  final String id;                    // "player_1", "player_2", ...
  final String name;                  // プレイヤー名
  final PlayerColor color;            // プレイヤーカラー
  Map<ResourceType, int> resources;   // 所持資源
  List<DevelopmentCard> developmentCards; // 発展カード
  int victoryPoints;                  // 勝利点

  // 建設物カウント（各プレイヤーの初期持ち駒）
  int settlementsBuilt;   // 集落の数（最大5個）
  int citiesBuilt;        // 都市の数（最大4個）
  int roadsBuilt;         // 道路の数（最大15本）

  // 特別ポイント
  bool hasLongestRoad;    // 最長交易路
  bool hasLargestArmy;    // 最大騎士力
  int knightsPlayed;      // 使用した騎士カード数
}

enum PlayerColor {
  red,
  blue,
  green,
  yellow,
}

enum ResourceType {
  lumber,  // 木材
  brick,   // レンガ
  wool,    // 羊毛
  grain,   // 小麦
  ore,     // 鉱石
}
```

### 3. プレイヤー設定（ゲーム開始前）

```dart
// プレイヤー設定
class PlayerConfig {
  final String name;              // プレイヤー名
  final PlayerColor color;        // カラー
  final bool isCPU;               // CPUプレイヤーか
  final CPUDifficulty? difficulty; // CPU難易度（CPUの場合）
}

enum CPUDifficulty {
  easy,    // 簡単
  normal,  // 普通
  hard,    // 難しい
}

// ゲーム設定
class GameConfig {
  final int playerCount;              // プレイヤー数（2-4）
  final List<PlayerConfig> players;   // プレイヤー設定
  final bool randomBoard;             // ランダムボード配置
  final bool tutorialMode;            // チュートリアルモード
}
```

### 4. セーブデータ管理

```dart
// セーブデータ情報
class SaveGameInfo {
  final String gameId;
  final String fileName;              // ファイル名
  final DateTime savedAt;             // 保存日時
  final List<String> playerNames;     // プレイヤー名一覧
  final int turnNumber;               // 現在のターン数
  final String currentPlayerName;     // 現在のプレイヤー
  final Map<String, int> victoryPoints; // 各プレイヤーの勝利点
}
```

### 5. 発展カード

```dart
class DevelopmentCard {
  final DevelopmentCardType type;
  final bool played;  // 使用済みか
}

enum DevelopmentCardType {
  knight,           // 騎士
  victoryPoint,     // 勝利点
  roadBuilding,     // 街道建設
  yearOfPlenty,     // 資源発見
  monopoly,         // 資源独占
}
```

### 6. 交渉システム

```dart
// 交渉オファー
class TradeOffer {
  final String proposerId;           // 提案者ID
  final String targetPlayerId;       // 交渉相手ID
  final Map<ResourceType, int> offering;   // 提供する資源
  final Map<ResourceType, int> requesting; // 要求する資源
  final DateTime createdAt;          // 提案時刻
  TradeOfferStatus status;           // 交渉状態
}

enum TradeOfferStatus {
  pending,     // 保留中（相手の返答待ち）
  accepted,    // 承諾
  rejected,    // 拒否
  cancelled,   // 取り消し
}

// 交渉履歴
class TradeHistory {
  final String tradeId;
  final String proposerId;
  final String targetPlayerId;
  final Map<ResourceType, int> offering;
  final Map<ResourceType, int> requesting;
  final TradeOfferStatus result;
  final DateTime timestamp;
}

// 銀行/港交易
class BankTrade {
  final String playerId;
  final ResourceType giving;     // 渡す資源
  final int givingAmount;        // 渡す数量（4または港レート）
  final ResourceType receiving;  // 受け取る資源
  final int receivingAmount;     // 受け取る数量（通常1）
  final String? harborId;        // 使用した港（null=銀行取引）
}
```

### 7. ゲーム状態

```dart
class GameState {
  final String gameId;
  final List<Player> players;
  final List<HexTile> board;
  final List<Vertex> vertices;
  final List<Edge> edges;
  final List<DevelopmentCard> developmentCardDeck;

  final GamePhase phase;
  final int currentPlayerIndex;
  final int turnNumber;

  final DiceRoll? lastDiceRoll;
  final String? robberHexId;  // 盗賊の位置

  // 交渉
  final TradeOffer? currentTradeOffer;  // 現在の交渉オファー
  final List<TradeHistory> tradeHistory; // 交渉履歴

  // ログ
  final List<GameEvent> eventLog;
}

enum GamePhase {
  setup,           // 初期配置フェーズ
  normalPlay,      // 通常プレイ
  resourceDiscard, // 資源破棄（7が出たとき）
  robberPlacement, // 盗賊配置
  trading,         // 交渉中（プレイヤー間取引）
  gameOver,        // ゲーム終了
}

class DiceRoll {
  final int die1;
  final int die2;
  int get total => die1 + die2;
}

class GameEvent {
  final DateTime timestamp;
  final String playerId;
  final GameEventType type;
  final Map<String, dynamic> data;
}

enum GameEventType {
  diceRolled,
  resourceGained,
  resourceLost,
  buildingPlaced,
  roadPlaced,
  cardPurchased,
  cardPlayed,
  tradeProposed,    // 交渉提案
  tradeAccepted,    // 交渉承諾
  tradeRejected,    // 交渉拒否
  tradeCancelled,   // 交渉取り消し
  tradeCompleted,   // 交渉成立
  bankTradeCompleted, // 銀行取引完了
  robberMoved,
}
```

---

## アーキテクチャ設計

### レイヤー構造

```
lib/
├── main.dart                      # アプリエントリポイント
├── widgetbook.dart                # Widgetbook（開発用）
│
├── models/                        # データモデル
│   ├── game_state.dart
│   ├── player.dart
│   ├── player_config.dart        # プレイヤー設定（ゲーム開始前）
│   ├── hex_tile.dart
│   ├── vertex.dart
│   ├── edge.dart
│   ├── building.dart
│   ├── development_card.dart
│   ├── trade_offer.dart          # 交渉オファー
│   ├── trade_history.dart        # 交渉履歴
│   ├── save_game_info.dart       # セーブデータ情報
│   └── game_event.dart
│
├── services/                      # ビジネスロジック
│   ├── game_service.dart         # ゲーム全体の管理
│   ├── board_generator.dart      # ボード生成
│   ├── dice_service.dart         # サイコロ
│   ├── resource_service.dart     # 資源管理
│   ├── building_service.dart     # 建設ロジック
│   ├── trading_service.dart      # 交易ロジック（銀行・港）
│   ├── negotiation_service.dart  # プレイヤー間交渉ロジック
│   ├── victory_service.dart      # 勝利判定
│   └── ai_service.dart           # AI（後期実装）
│
├── repositories/                  # データ永続化
│   ├── game_repository.dart      # ゲーム保存/読み込み
│   └── settings_repository.dart  # 設定保存
│
├── ui/                            # UI層
│   ├── screens/
│   │   ├── title_screen.dart     # タイトル画面
│   │   ├── main_menu_screen.dart # メインメニュー画面
│   │   ├── game_screen.dart      # ゲーム画面
│   │   ├── setup_screen.dart     # 初期配置画面
│   │   └── settings_screen.dart  # 設定画面
│   │
│   ├── widgets/
│   │   ├── board/
│   │   │   ├── hex_tile_widget.dart
│   │   │   ├── vertex_widget.dart
│   │   │   ├── edge_widget.dart
│   │   │   ├── building_widget.dart
│   │   │   └── road_widget.dart
│   │   │
│   │   ├── player/
│   │   │   ├── player_panel.dart
│   │   │   ├── resource_display.dart
│   │   │   ├── resource_card.dart         # 資源カード（手札表示用）
│   │   │   └── development_cards_panel.dart
│   │   │
│   │   ├── actions/
│   │   │   ├── dice_roller.dart
│   │   │   ├── build_menu.dart
│   │   │   ├── bank_trade_dialog.dart     # 銀行・港取引ダイアログ
│   │   │   ├── negotiation_dialog.dart    # プレイヤー間交渉ダイアログ
│   │   │   └── robber_placement.dart
│   │   │
│   │   ├── menu/
│   │   │   ├── menu_button.dart          # メニューボタンウィジェット
│   │   │   ├── player_config_card.dart   # プレイヤー設定カード
│   │   │   └── save_game_card.dart       # セーブデータカード
│   │   │
│   │   └── common/
│   │       ├── game_log.dart
│   │       ├── game_log_overlay.dart      # ログのオーバーレイ表示
│   │       ├── turn_indicator.dart
│   │       ├── action_button_bar.dart     # 下部アクションボタン
│   │       └── blinking_text.dart         # 点滅テキスト
│   │
│   └── painters/
│       ├── hex_painter.dart
│       ├── board_painter.dart
│       └── road_painter.dart
│
└── utils/                         # ユーティリティ
    ├── constants.dart            # 定数
    ├── colors.dart               # カラーパレット
    └── hex_math.dart             # 六角形の座標計算
```

### 状態管理

**使用パターン: Provider + ChangeNotifier**

```dart
// ゲーム状態を管理
class GameController extends ChangeNotifier {
  GameState _state;
  final GameService _gameService;
  final GameRepository _repository;

  // ゲームアクション
  Future<void> rollDice();
  Future<void> buildSettlement(String vertexId);
  Future<void> buildRoad(String edgeId);
  Future<void> upgradeToCity(String vertexId);
  Future<void> buyDevelopmentCard();
  Future<void> playDevelopmentCard(DevelopmentCard card);
  Future<void> proposeTrade(TradeOffer offer);

  // ゲーム管理
  Future<void> saveGame();
  Future<void> loadGame(String gameId);
  Future<void> newGame(List<String> playerNames);
  Future<void> endTurn();
}
```

---

## UI設計

### デザインコンセプト
- **モバイルファースト**：スマホ・タブレットでのプレイを優先
- **縦長レイアウト**：縦持ちでも横持ちでもプレイ可能
- **タッチ操作対応**：大きめのボタンとタップ可能な領域

### 画面遷移フロー

```
┌─────────────┐
│タイトル画面  │ ← アプリ起動時
└──────┬──────┘
       │ タップでスタート
       ↓
┌─────────────┐
│メインメニュー│
└──────┬──────┘
       │
       ├→ [新しいゲーム] → プレイヤー設定 → ゲーム画面
       ├→ [ゲームを続ける] → セーブデータ選択 → ゲーム画面
       ├→ [設定]         → 設定画面
       └→ [ルール説明]    → ルール画面
```

### 1. タイトル画面

```
┌─────────────────────────────┐
│                             │
│                             │
│                             │
│          カ タ ン           │ ← タイトルロゴ（大きく中央）
│     Settlers of Catan       │
│                             │
│                             │
│                             │
│       [TOUCH TO START]      │ ← 点滅テキスト
│                             │
│                             │
│                             │
│      Version 1.0.0          │ ← バージョン表示（小さく下部）
└─────────────────────────────┘
```

**機能**：
- シンプルなタイトルロゴ表示
- 「TOUCH TO START」が点滅（フェードイン・アウト）
- 画面のどこをタップしてもメインメニューへ遷移
- BGM再生（設定でON/OFF可能）
- 初回起動時はチュートリアルへ誘導（オプション）

### 2. メインメニュー画面

```
┌─────────────────────────────┐
│        カ タ ン             │ ← タイトル（小）
├─────────────────────────────┤
│                             │
│  ┌───────────────────────┐  │
│  │   新しいゲーム          │  │ ← 大きなボタン
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │   ゲームを続ける        │  │
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │   ルール説明            │  │
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │   設定                  │  │
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │   終了                  │  │
│  └───────────────────────┘  │
│                             │
└─────────────────────────────┘
```

**機能**：
- **新しいゲーム**：プレイヤー設定画面へ遷移
- **ゲームを続ける**：セーブデータ一覧を表示、選択してゲーム再開
- **ルール説明**：ゲームルールのチュートリアル表示
- **設定**：サウンド、音楽、言語、通知などの設定
- **終了**：アプリ終了確認ダイアログ

### 3. プレイヤー設定画面（新しいゲーム選択時）

```
┌─────────────────────────────┐
│  新しいゲーム              [×]│
├─────────────────────────────┤
│                             │
│ プレイヤー数を選択:          │
│  ○ 2人  ○ 3人  ● 4人       │
│                             │
│ プレイヤー1 (あなた):        │
│ ┌─────────────────────────┐ │
│ │ Player 1            [赤]│ │
│ └─────────────────────────┘ │
│                             │
│ プレイヤー2:                │
│ ┌─────────────────────────┐ │
│ │ Player 2       [CPU][青]│ │
│ └─────────────────────────┘ │
│                             │
│ プレイヤー3:                │
│ ┌─────────────────────────┐ │
│ │ Player 3       [CPU][緑]│ │
│ └─────────────────────────┘ │
│                             │
│ プレイヤー4:                │
│ ┌─────────────────────────┐ │
│ │ Player 4       [CPU][黄]│ │
│ └─────────────────────────┘ │
│                             │
│        [ゲーム開始]          │
└─────────────────────────────┘
```

**機能**：
- プレイヤー数選択（2-4人）
- 各プレイヤーの名前入力
- CPUプレイヤーのON/OFF切り替え
- プレイヤーカラー選択
- 設定完了後、ゲーム画面へ遷移

### 4. ゲーム画面レイアウト（モバイル対応）

```
┌─────────────────────────────┐
│  カタン        [保存] [設定] │ ← ヘッダー
├─────────────────────────────┤
│                             │
│                             │
│     六角形ボード            │ ← メインエリア
│     (中央配置)              │   （ピンチズーム・パン対応）
│                             │
│                             │
│ ┌─────────────────────────┐ │
│ │ ログ（半透明背景）      │ │ ← ログ表示（右側、薄く）
│ │ Player 1: サイコロ 8    │ │   スクロール可能
│ │ Player 1: 木材x2獲得    │ │
│ └─────────────────────────┘ │
├─────────────────────────────┤
│ 手札：                      │ ← 資源手札エリア
│ 🌲x2 🧱x3 🐑x1 🌾x0 ⛰️x1   │   （カード形式で表示）
├─────────────────────────────┤
│[🎲サイコロ][🏠建設]         │ ← アクションボタン
│[🔄交渉][🃏カード][終了]     │   （一番下に配置）
└─────────────────────────────┘
```

### レスポンシブ対応

#### スマホ縦持ち（縦長）
- ボードを上部に配置
- ログは右側に半透明で薄く表示（ドロワー形式で展開可能）
- 手札は下部に横スクロール可能なカード形式
- アクションボタンは最下部に2行で配置

#### タブレット横持ち（横長）
- ボードを中央に配置
- ログは右側パネルとして常時表示
- 手札は下部に全て表示
- アクションボタンは最下部に1行で配置

### UI要素の詳細

#### 1. ボードエリア
- **ピンチズーム対応**：拡大縮小可能
- **パン対応**：ドラッグで移動可能
- **タップ検出**：頂点・辺をタップして選択
- **ハイライト表示**：建設可能な場所を強調

#### 2. ログ表示
- **半透明背景**（opacity: 0.8）で薄く表示
- **右側配置**（スマホでは右下）
- **自動スクロール**：新しいログが追加されたら自動で下にスクロール
- **タップで展開/折りたたみ**可能

#### 3. 資源手札エリア
- **カード形式**：各資源をカード状に表示
- **横スクロール対応**：資源が多い場合はスワイプ
- **枚数表示**：各カードに所持枚数を大きく表示
- **タップ選択**：交渉時に選択可能

#### 4. アクションボタン
- **大きなボタン**：最低44x44pxのタッチターゲット
- **アイコン+テキスト**：視認性向上
- **状態表示**：無効時はグレーアウト
- **ハプティックフィードバック**：タップ時に振動

#### 5. 交渉ダイアログ（プレイヤー間交渉）

**ダイアログの表示フロー**：

```
ステップ1: 提供資源の選択
┌─────────────────────────────────┐
│ プレイヤー間交渉                │
├─────────────────────────────────┤
│ 提供する資源を選択してください   │
│                                 │
│ [🌲x2] [🧱x3] [🐑x1] [🌾x0]    │  ← タップで選択（複数可）
│                  [⛰️x1]         │     選択されたカードはハイライト
│                                 │
│ 選択中: 🌲x1 🧱x2               │  ← 選択した資源を表示
│                                 │
│          [次へ]                 │
└─────────────────────────────────┘

ステップ2: 相手プレイヤーの選択
┌─────────────────────────────────┐
│ プレイヤー間交渉                │
├─────────────────────────────────┤
│ 交渉相手を選択してください       │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Player 2 (青)               │ │  ← タップで選択
│ │ 勝利点: 3  手札: 5枚        │ │     手札総数は表示
│ └─────────────────────────────┘ │     資源内訳は非表示
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Player 3 (緑)               │ │
│ │ 勝利点: 4  手札: 8枚        │ │
│ └─────────────────────────────┘ │
│                                 │
│    [戻る]        [次へ]         │
└─────────────────────────────────┘

ステップ3: 要求資源の選択
┌─────────────────────────────────┐
│ プレイヤー間交渉                │
├─────────────────────────────────┤
│ 要求する資源を選択してください   │
│                                 │
│ 相手: Player 2 (手札: 5枚)     │
│                                 │
│ [🌲] [🧱] [🐑] [🌾] [⛰️]       │  ← 種類のみ選択可能
│                                 │     （相手の所持枚数は不明）
│ 数量: [1] [2] [3] [4] [5]      │  ← 数量を選択
│                                 │
│ 選択中: 🐑x2 🌾x1               │
│                                 │
│    [戻る]      [交渉提案]       │
└─────────────────────────────────┘

ステップ4: 確認画面
┌─────────────────────────────────┐
│ 交渉内容の確認                  │
├─────────────────────────────────┤
│ あなたが渡す:                   │
│ 🌲x1 🧱x2                       │
│                                 │
│         ↓↑                     │
│                                 │
│ 相手から受け取る:               │
│ 🐑x2 🌾x1                       │
│                                 │
│ 交渉相手: Player 2              │
│                                 │
│  [キャンセル]   [提案する]      │
└─────────────────────────────────┘
```

**相手側の応答画面**：

```
┌─────────────────────────────────┐
│ 交渉の提案                      │
├─────────────────────────────────┤
│ Player 1 から交渉の提案:        │
│                                 │
│ Player 1が渡す:                 │
│ 🌲x1 🧱x2                       │
│                                 │
│         ↓↑                     │
│                                 │
│ あなたが渡す:                   │
│ 🐑x2 🌾x1                       │
│                                 │
│ ※所持していない資源が含まれる場合 │
│   は自動的に拒否されます         │
│                                 │
│    [拒否]      [承諾]           │
└─────────────────────────────────┘
```

**交渉結果の通知**：
- 承諾された場合：資源の交換が即座に実行され、ログに記録
- 拒否された場合：交渉不成立のメッセージを表示
- 相手が必要な資源を持っていない場合：自動的に不成立

### 六角形ボード描画

```
   / \     / \     / \
  /   \   /   \   /   \
 /  3  \ /  6  \ /  11 \
 \     / \     / \     /
  \   /   \   /   \   /
   \ /  4  \ /  8  \ /
   / \     / \     / \
  /   \   /   \   /   \
 /  9  \ /  5  \ / 10  \
 \     / \     / \     /
  \   /   \   /   \   /
   \ /  2  \ /  12 \ /
```

### カラーパレット（簡易）

```dart
// プレイヤーカラー
const playerColors = {
  PlayerColor.red: Color(0xFFE53935),
  PlayerColor.blue: Color(0xFF1E88E5),
  PlayerColor.green: Color(0xFF43A047),
  PlayerColor.yellow: Color(0xFFFDD835),
};

// 地形カラー
const terrainColors = {
  TerrainType.forest: Color(0xFF2E7D32),     // 濃い緑
  TerrainType.hills: Color(0xFFD84315),      // レンガ色
  TerrainType.pasture: Color(0xFF9CCC65),    // 明るい緑
  TerrainType.fields: Color(0xFFFDD835),     // 黄色
  TerrainType.mountains: Color(0xFF616161),  // 灰色
  TerrainType.desert: Color(0xFFFFCC80),     // 砂色
};
```

---

## 実装フェーズ

### フェーズ0: タイトル・メニュー画面
- ✅ タイトル画面の実装
  - タイトルロゴ表示
  - 点滅テキスト（TOUCH TO START）
  - BGM再生
  - タップでメニューへ遷移
- ✅ メインメニュー画面の実装
  - メニューボタン（新しいゲーム、続ける、ルール説明、設定、終了）
  - 画面遷移ロジック
- ✅ プレイヤー設定画面の実装
  - プレイヤー数選択（2-4人）
  - プレイヤー名入力
  - CPUプレイヤーON/OFF
  - プレイヤーカラー選択
- ✅ セーブデータ選択画面
  - セーブデータ一覧表示
  - セーブデータの読み込み
- ✅ 設定画面
  - サウンド、音楽のON/OFF
  - 言語設定
- ✅ データモデル
  - PlayerConfig、GameConfig
  - SaveGameInfo

**成果物**: タイトルからゲーム開始までの導線が完成

### フェーズ1: 基盤構築
- ✅ プロジェクト構造作成
- ✅ データモデル実装
- ✅ 六角形ボード生成ロジック
- ✅ 基本的なUI（ボード表示のみ）
- ✅ JSONシリアライズ/デシリアライズ

**成果物**: 静的なボードが表示される

### フェーズ2: 初期配置
- ✅ 頂点・辺のタップ検出
- ✅ 集落・道路の配置ロジック
- ✅ 配置ルールの検証（距離ルール、接続ルールなど）
- ✅ 初期資源の配布

**成果物**: 2人プレイヤーで初期配置ができる

### フェーズ3: 基本ゲームループ
- ✅ サイコロ機能
- ✅ 資源生産ロジック
- ✅ 建設メニュー（道路、集落、都市）
- ✅ ターン管理
- ✅ 勝利点計算

**成果物**: 基本的なゲームが完結する

### フェーズ4: 交易システム
- ✅ 銀行交易（4:1レート）
- ✅ 港の実装（2:1, 3:1レート）
- ✅ プレイヤー間交渉UI
  - 提供資源選択画面（複数選択可能）
  - 相手プレイヤー選択画面（手札総数表示）
  - 要求資源選択画面（種類と数量）
  - 確認画面
  - 相手側の承諾/拒否UI
- ✅ 交渉ロジック
  - 等価交換の検証
  - 資源所持チェック
  - 交渉履歴の記録
  - 情報の非対称性（相手の手札内訳は非公開）

**成果物**: 銀行取引とプレイヤー間交渉が完全に機能する

### フェーズ5: 発展カード
- ✅ 発展カード購入
- ✅ カード効果実装（1ターン1枚制限含む）
- ✅ 最長交易路・最大騎士力

**成果物**: すべてのゲームルールが実装される

### フェーズ6: 盗賊と7の処理
- ✅ 盗賊移動
- ✅ 資源破棄（8枚以上で半分）
- ✅ 資源強奪

**成果物**: 完全なルール実装

### フェーズ7: UI/UX改善（モバイル対応）
- ✅ モバイルレイアウトの最適化
  - レスポンシブデザイン（縦持ち・横持ち対応）
  - ピンチズーム・パン操作
  - 半透明ログオーバーレイ
  - 資源カード表示（横スクロール対応）
  - 下部アクションボタンバー
- ✅ アニメーション追加
  - サイコロ振りアニメーション
  - 資源獲得エフェクト
  - 建設アニメーション
- ✅ サウンドエフェクト
- ✅ ハプティックフィードバック（タップ時の振動）
- ✅ チュートリアル
- ✅ ゲームログ強化

**成果物**: スマホ・タブレットで快適にプレイできるUI

### フェーズ8: セーブ/ロード
- ✅ JSONファイル保存
- ✅ ゲーム再開機能
- ✅ 複数ゲーム管理

**成果物**: いつでも中断・再開可能

### フェーズ9: AIプレイヤー
- ✅ 基本的なAI戦略
- ✅ 建設優先度アルゴリズム
- ✅ 交易判断ロジック
- ✅ 難易度レベル

**成果物**: 1人プレイが可能

### フェーズ10: 最適化とテスト
- ✅ パフォーマンス最適化
- ✅ バグ修正
- ✅ マルチプレイヤー（3-4人）対応

---

## JSONファイル構造

### ゲーム状態ファイル (game_state.json)

```json
{
  "gameId": "game_20250104_001",
  "version": "1.0",
  "createdAt": "2025-01-04T10:30:00Z",
  "updatedAt": "2025-01-04T11:15:00Z",

  "phase": "normalPlay",
  "currentPlayerIndex": 0,
  "turnNumber": 5,

  "players": [
    {
      "id": "player_1",
      "name": "Alice",
      "color": "red",
      "resources": {
        "lumber": 2,
        "brick": 3,
        "wool": 1,
        "grain": 0,
        "ore": 1
      },
      "developmentCards": [
        {"type": "knight", "played": false},
        {"type": "knight", "played": true}
      ],
      "victoryPoints": 3,
      "settlementsBuilt": 2,
      "citiesBuilt": 0,
      "roadsBuilt": 4,
      "hasLongestRoad": true,
      "hasLargestArmy": false,
      "knightsPlayed": 1
    },
    {
      "id": "player_2",
      "name": "Bob",
      "color": "blue",
      "resources": {
        "lumber": 1,
        "brick": 0,
        "wool": 2,
        "grain": 3,
        "ore": 0
      },
      "developmentCards": [],
      "victoryPoints": 2,
      "settlementsBuilt": 2,
      "citiesBuilt": 0,
      "roadsBuilt": 2,
      "hasLongestRoad": false,
      "hasLargestArmy": false,
      "knightsPlayed": 0
    }
  ],

  "board": {
    "hexTiles": [
      {
        "id": "hex_0",
        "terrain": "forest",
        "number": 3,
        "position": {"x": 0, "y": 0},
        "hasRobber": false
      },
      {
        "id": "hex_1",
        "terrain": "desert",
        "number": null,
        "position": {"x": 1, "y": 0},
        "hasRobber": true
      }
      // ... 他のタイル
    ],

    "vertices": [
      {
        "id": "v_0_0",
        "position": {"x": 100, "y": 50},
        "adjacentHexIds": ["hex_0", "hex_1", "hex_2"],
        "adjacentEdgeIds": ["e_0_0", "e_0_1", "e_0_2"],
        "building": {
          "playerId": "player_1",
          "type": "settlement"
        }
      }
      // ... 他の頂点
    ],

    "edges": [
      {
        "id": "e_0_0",
        "vertex1Id": "v_0_0",
        "vertex2Id": "v_0_1",
        "road": {
          "playerId": "player_1"
        }
      }
      // ... 他の辺
    ]
  },

  "developmentCardDeck": [
    {"type": "knight"},
    {"type": "knight"},
    {"type": "victoryPoint"},
    {"type": "roadBuilding"}
    // ... 残りのカード
  ],

  "robberHexId": "hex_1",

  "lastDiceRoll": {
    "die1": 4,
    "die2": 4
  },

  "eventLog": [
    {
      "timestamp": "2025-01-04T11:14:30Z",
      "playerId": "player_1",
      "type": "diceRolled",
      "data": {"die1": 4, "die2": 4}
    },
    {
      "timestamp": "2025-01-04T11:14:35Z",
      "playerId": "player_1",
      "type": "resourceGained",
      "data": {"resource": "lumber", "amount": 2}
    }
  ]
}
```

### 設定ファイル (settings.json)

```json
{
  "soundEnabled": true,
  "musicEnabled": false,
  "animationsEnabled": true,
  "language": "ja",
  "defaultPlayerNames": ["Player 1", "Player 2", "Player 3", "Player 4"]
}
```

### ゲーム履歴ファイル (game_history.json)

```json
{
  "games": [
    {
      "gameId": "game_20250104_001",
      "startedAt": "2025-01-04T10:30:00Z",
      "finishedAt": "2025-01-04T11:45:00Z",
      "winner": "player_1",
      "players": ["Alice", "Bob"],
      "filePath": "saves/game_20250104_001.json"
    }
  ]
}
```

---

## 技術的検討事項

### 六角形の座標計算

**Axial座標系**を使用：
```dart
class HexCoordinate {
  final int q; // 列
  final int r; // 行

  // スクリーン座標への変換
  Offset toPixel(double hexSize) {
    final x = hexSize * (3.0 / 2.0 * q);
    final y = hexSize * (sqrt(3) / 2.0 * q + sqrt(3) * r);
    return Offset(x, y);
  }
}
```

### パフォーマンス最適化

- **CustomPainter**でボード全体を描画
- **RepaintBoundary**で部分的な再描画を制御
- 大きなゲーム状態は**Freezed**パッケージで不変性を保証
- JSONの読み書きは**isolate**で非同期処理

### テスト戦略

- **Unit Test**: ゲームロジック（資源計算、勝利判定など）
- **Widget Test**: UI コンポーネント
- **Integration Test**: ゲーム全体の流れ
- **Golden Test**: ボードの描画結果

---

## まとめ

この計画書に従って段階的に実装することで、以下を達成できます：

1. ✅ シンプルで分かりやすいUI
2. ✅ 完全なカタンルールの実装
3. ✅ JSONファイルによる柔軟な保存/読み込み
4. ✅ 将来的なAI実装に対応した設計
5. ✅ テスト可能で保守しやすいアーキテクチャ

次のステップ：
- フェーズ1から順番に実装開始
- Widgetbookで各UIコンポーネントを個別開発
- GitHub Actionsで継続的に APK をビルド

## 参考資料

- [カタン公式ルール](https://www.catan.jp/)
- [Flutter CustomPaint](https://api.flutter.dev/flutter/widgets/CustomPaint-class.html)
- [Provider パッケージ](https://pub.dev/packages/provider)
- [Freezed パッケージ](https://pub.dev/packages/freezed)
