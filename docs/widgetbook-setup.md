# Widgetbook セットアップガイド

## 概要
Widgetbookは、Flutterのウィジェットをカタログ化して、開発中に各ウィジェットやコンポーネントを簡単にプレビュー・テストできる開発ツールです。

このプロジェクトでは、Space Invadersゲームの各コンポーネント（プレイヤー、敵、弾、UI要素など）をWidgetbookで管理しています。

## 導入したパッケージ

```yaml
dev_dependencies:
  widgetbook: ^3.9.0
  widgetbook_annotation: ^3.2.0
  build_runner: ^2.4.13
```

## ファイル構成

```
lib/
├── main.dart              # 通常のゲームアプリ
└── widgetbook.dart        # Widgetbookアプリ（開発用）
```

## Widgetbookの起動方法

### 方法1: ローカルで起動（開発時）

```bash
# Widgetbookアプリを起動
flutter run -t lib/widgetbook.dart
```

これで、サイドバーから各コンポーネントを選択して表示できます。

### 方法2: Web版でビルド

```bash
# Web版としてビルド
flutter build web -t lib/widgetbook.dart

# ビルド成果物は build/web/ に生成される
```

## Widgetbookの構成

### カテゴリ構成

```
Space Invaders
├── Game
│   └── Full Game              # ゲーム全体
│
├── Components
│   ├── Player Ship            # プレイヤーの宇宙船
│   ├── Enemy Invader          # 敵キャラクター
│   ├── Stars Background       # 星空背景
│   ├── Player Bullet          # プレイヤーの弾
│   └── Enemy Bullet           # 敵の弾
│
└── UI Elements
    ├── Score Display          # スコア表示
    ├── Game Over Screen       # ゲームオーバー画面
    ├── Victory Screen         # 勝利画面
    └── Control Buttons        # コントロールボタン
```

### 利用可能なアドオン

1. **Device Frame Addon**
   - 様々なデバイスのフレームで表示を確認
   - iPhone 13
   - Samsung Galaxy S20
   - Small Phone

2. **Material Theme Addon**
   - ダークテーマ
   - ライトテーマ

## 使い方

### サイドバーからコンポーネントを選択

1. **左サイドバー**: カテゴリとコンポーネントのツリー表示
2. **中央エリア**: 選択したコンポーネントのプレビュー
3. **右サイドバー**: アドオン設定（デバイス選択、テーマ切替など）

### デバイスフレームの切り替え

右サイドバーの「Device Frame」から、表示するデバイスを選択できます。

### テーマの切り替え

右サイドバーの「Theme」から、ライト/ダークテーマを切り替えられます。

## コンポーネントの追加方法

新しいコンポーネントを追加する場合は、`lib/widgetbook.dart` に以下のように追加します：

```dart
WidgetbookUseCase(
  name: 'New Component',
  builder: (context) => YourNewWidget(),
),
```

## GitHub Actions でのビルド

通常のゲームアプリと同様に、Widgetbook版もGitHub Actionsでビルドできます。

ワークフローファイルに以下を追加：

```yaml
- name: Widgetbook APKをビルド
  run: flutter build apk -t lib/widgetbook.dart --debug
```

## 開発時の活用例

### 1. 個別のウィジェットのデザイン確認
- 各コンポーネントを個別に表示して、デザインを確認
- ゲーム全体を起動せずに、特定のウィジェットだけをテスト

### 2. 異なるデバイスでの表示確認
- iPhoneとAndroidでの見た目の違いを確認
- 小さい画面での表示を確認

### 3. UIの変更をすぐに確認
- ホットリロードで変更を即座に反映
- デザインの微調整が簡単

### 4. コンポーネントのドキュメント化
- 各コンポーネントの使い方を可視化
- チーム開発時の共有資料として活用

## トラブルシューティング

### Widgetbookアプリが起動しない

```bash
# パッケージを再インストール
flutter pub get

# キャッシュをクリア
flutter clean
flutter pub get
```

### import エラーが出る

`lib/widgetbook.dart` で `main.dart` をインポートしているため、`main.dart` のウィジェットをすべて使用できます。

### ホットリロードが効かない

ターゲットファイルを指定して起動：
```bash
flutter run -t lib/widgetbook.dart
```

## 参考リンク

- [Widgetbook 公式ドキュメント](https://docs.widgetbook.io/)
- [Flutter 公式サイト](https://flutter.dev/)
