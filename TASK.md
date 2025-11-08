# UI Screens担当タスク

## 役割
画面UIの実装

## フェーズ1の担当タスク

### 1. TitleScreen (ui/screens/title_screen.dart)
- タイトルロゴ表示
- 点滅テキスト「TOUCH TO START」
- タップでメインメニューへ遷移
- BGM再生（将来実装）

### 2. MainMenuScreen (ui/screens/main_menu_screen.dart)
- メニューボタン配置
  - 新しいゲーム（カタン）
  - Space Invaders（おまけゲーム）
  - ゲームを続ける
  - ルール説明
  - 設定
  - 終了
- 画面遷移ロジック

### 3. GameScreen (ui/screens/game_screen.dart)
- ゲーム画面の基本構造
- ボードエリア（中央）
- ログエリア（半透明、右側）
- 手札エリア（下部）
- アクションボタンエリア（最下部）
- レスポンシブレイアウト対応

## 依存関係
- ui/widgets/ のウィジェットを使用
- services/ のロジックを呼び出し

## 成果物
- lib/ui/screens/title_screen.dart
- lib/ui/screens/main_menu_screen.dart
- lib/ui/screens/game_screen.dart

## 完了条件
- タイトル→メインメニュー→ゲーム画面の遷移が動作
- 各画面が適切にレイアウトされる
