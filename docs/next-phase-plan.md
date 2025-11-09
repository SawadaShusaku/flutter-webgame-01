# 次フェーズ実装計画

## 日付
2025-11-09

## 現状
- ビルドは成功し、APKインストール完了
- 起動確認済み
- サービス層はほぼ完全に実装済み
- UIの基本構造は実装済み

## 不足している機能

### 1. 初期配置フェーズ（最優先）
**問題**: 現在ゲーム開始後、何もできない状態

**必要な実装**:
- [ ] 初期配置フェーズのUI実装
- [ ] 頂点タップによる集落配置
- [ ] 辺タップによる道路配置
- [ ] 配置ルールの可視化（距離ルール、接続ルール）
- [ ] 配置可能な場所のハイライト表示
- [ ] 2巡の配置順序管理
- [ ] 2巡目の初期資源配布
- [ ] 初期配置完了後、通常プレイへの自動遷移

**実装ファイル**:
```
lib/ui/screens/setup_screen.dart  ← 既存ファイルを拡張
lib/ui/widgets/board/hex_tile_widget.dart  ← タップ検出追加
lib/ui/widgets/board/vertex_widget.dart  ← タップ検出追加
lib/ui/widgets/board/edge_widget.dart  ← タップ検出追加
lib/ui/widgets/board/game_board_widget.dart  ← タップハンドリング統合
lib/services/setup_service.dart  ← 新規作成
```

### 2. ボードインタラクション
**問題**: 頂点・辺をタップできない（ダミーID使用中）

**必要な実装**:
- [ ] 頂点ウィジェットのタップ検出
- [ ] 辺ウィジェットのタップ検出
- [ ] 選択状態の可視化（ハイライト）
- [ ] GameControllerへのタップイベント伝達
- [ ] タップ可能/不可能の状態管理

### 3. サイコロ機能の実装
**問題**: サイコロボタンはあるが、実際の動作未確認

**必要な実装**:
- [ ] サイコロアニメーション
- [ ] 出目の表示
- [ ] 資源生産の実行
- [ ] 7が出た場合の処理フロー
- [ ] ログへの記録

### 4. 建設メニューの改善
**問題**: ダミーIDでしか建設できない

**必要な実装**:
- [ ] 建設モード切り替え（集落モード、道路モード、都市モード）
- [ ] 建設可能な場所のハイライト表示
- [ ] タップで建設位置を選択
- [ ] 資源消費の確認ダイアログ
- [ ] 建設後のUIフィードバック

### 5. ゲームフローの統合
**問題**: フェーズ間の遷移が不完全

**必要な実装**:
- [ ] GamePhaseの適切な管理
- [ ] フェーズごとのUI切り替え
- [ ] ターン進行ロジック
- [ ] 勝利判定と終了画面

## 実装フェーズ

### Phase A: 初期配置フェーズ（最優先・3日）
**目標**: ゲーム開始後、初期配置ができるようにする

#### A-1: SetupServiceの実装
```dart
class SetupService {
  // 現在の配置順番を管理
  int currentSetupIndex = 0;
  bool isSecondRound = false;

  // 配置可能な頂点を取得
  List<Vertex> getValidVerticesForSettlement(GameState state);

  // 配置可能な辺を取得
  List<Edge> getValidEdgesForRoad(GameState state, String settlementVertexId);

  // 集落を配置
  bool placeInitialSettlement(GameState state, String vertexId);

  // 道路を配置
  bool placeInitialRoad(GameState state, String edgeId);

  // 次のプレイヤーへ
  void nextSetupPlayer(GameState state);

  // 初期資源を配布（2巡目のみ）
  void distributeInitialResources(GameState state, String vertexId);
}
```

#### A-2: タップ検出の実装
- VertexWidgetにGestureDetectorを追加
- EdgeWidgetにGestureDetectorを追加
- GameBoardWidgetでタップイベントを統合
- GameControllerに`onVertexTapped(String vertexId)`追加
- GameControllerに`onEdgeTapped(String edgeId)`追加

#### A-3: ハイライト表示
- 配置可能な頂点を緑色でハイライト
- 配置可能な辺を緑色でハイライト
- 配置不可な場所は薄く表示

#### A-4: UIフロー
1. ゲーム開始 → SetupScreen表示
2. 「Player 1の番です。集落を配置してください」メッセージ
3. 配置可能な頂点がハイライト
4. タップで集落配置
5. 「道路を配置してください」メッセージ
6. 配置可能な辺（集落に隣接）がハイライト
7. タップで道路配置
8. 次のプレイヤーへ（4人まで繰り返し）
9. 2巡目（逆順）
10. 2巡目の集落周辺の資源を配布
11. 通常プレイフェーズへ自動遷移

### Phase B: サイコロとターン管理（2日）
**目標**: サイコロを振って資源が生産されるようにする

#### B-1: DiceRollerウィジェットの改善
- アニメーション追加
- 出目の3D風表示
- サウンドエフェクト

#### B-2: 資源生産フロー
- サイコロの出目取得
- 該当タイルの特定
- 隣接する集落・都市の検索
- 資源配布
- ログ記録

#### B-3: 7の処理
- 資源破棄フェーズへ遷移
- 盗賊移動フェーズへ遷移

### Phase C: 建設インタラクション（2日）
**目標**: タップで建設できるようにする

#### C-1: 建設モードの追加
```dart
enum BuildMode {
  none,
  settlement,
  road,
  city,
}
```

#### C-2: 建設フロー
1. 「集落」ボタンタップ → 建設モード = settlement
2. 建設可能な頂点がハイライト
3. 頂点タップ → 確認ダイアログ
4. 資源消費 → 集落配置
5. 建設モード解除

### Phase D: ゲームフロー統合（1日）
- 初期配置 → 通常プレイ遷移
- ターン終了処理
- 勝利判定
- ゲーム終了画面

## 実装の進め方

### 推奨アプローチ: Phase-by-Phase
各Phaseを順番に完成させることで、段階的に遊べる状態にする。

1. **Phase A完了** → 初期配置ができる（まだゲームは進まない）
2. **Phase B完了** → サイコロを振って資源がもらえる
3. **Phase C完了** → 建設ができる
4. **Phase D完了** → 完全なゲームループ

### 並列開発は避ける
前回の反省を活かし、**1つのPhaseを完全に実装してからコミット**する。

### テスト方法
各Phase完了後：
1. APKビルド
2. 実機でテスト
3. 動作確認後、次のPhaseへ

## 成果物

### Phase A完了時
- ゲーム開始後、4人のプレイヤーが順番に集落と道路を配置できる
- 2巡目の初期資源が配布される
- 通常プレイフェーズに自動遷移

### Phase B完了時
- サイコロを振ると資源が生産される
- ログに記録される
- ターン終了ができる

### Phase C完了時
- タップで建設場所を選択できる
- 建設可能な場所がハイライトされる
- 資源が消費される

### Phase D完了時
- 完全なゲームループが動作
- 勝利判定が機能
- ゲーム終了画面が表示される

## 次のアクション
**Phase Aから開始します。実装しますか？**
