# Catan UI Widgets

カタンボードゲームのUIウィジェットライブラリ

## 概要

このパッケージは、カタンのボードゲームを表示するためのFlutterウィジェット群を提供します。六角形タイル、頂点、辺などのゲームボードコンポーネントを描画できます。

## 実装内容

### フェーズ1完成タスク

#### 1. HexTileWidget (`lib/ui/widgets/board/hex_tile_widget.dart`)
- ✅ 六角形タイルの描画
- ✅ 地形タイプに応じた色分け（森、丘陵、牧草地、畑、山、砂漠）
- ✅ 数字チップの表示（2-12、確率ドット付き）
- ✅ 盗賊の表示
- ✅ ハイライト表示機能

#### 2. VertexWidget (`lib/ui/widgets/board/vertex_widget.dart`)
- ✅ 頂点の描画
- ✅ 集落（settlement）の表示
- ✅ 都市（city）の表示
- ✅ タップ検出
- ✅ ハイライト表示
- ✅ プレイヤーカラー対応（赤、青、緑、黄）

#### 3. EdgeWidget (`lib/ui/widgets/board/edge_widget.dart`)
- ✅ 辺の描画
- ✅ 道路の表示
- ✅ タップ検出（hitTest実装）
- ✅ ハイライト表示
- ✅ プレイヤーカラー対応

#### 4. BoardPainter (`lib/ui/painters/board_painter.dart`)
- ✅ CustomPainterでボード全体を描画
- ✅ 六角形の座標計算
- ✅ パフォーマンス最適化（shouldRepaint）
- ✅ ズーム・パン機能付きボードウィジェット
- ✅ ボードデータジェネレータ（テスト用）

### 追加実装

#### 5. HexMath (`lib/utils/hex_math.dart`)
- ✅ 六角形座標システム（アキシャル座標系）
- ✅ 座標変換（六角形座標 ⇔ ピクセル座標）
- ✅ 頂点・辺のID生成と正規化
- ✅ カタンボードレイアウト生成（標準19タイル、拡張版）

#### 6. デモアプリケーション (`lib/main.dart`)
- ✅ インタラクティブなボード表示
- ✅ ズーム・パン操作対応
- ✅ 建物・道路の動的追加機能

## ファイル構成

```
lib/
├── catan_widgets.dart              # エクスポートファイル
├── main.dart                       # デモアプリケーション
├── utils/
│   └── hex_math.dart              # 六角形座標計算ユーティリティ
├── ui/
│   ├── widgets/
│   │   └── board/
│   │       ├── hex_tile_widget.dart   # 六角形タイルウィジェット
│   │       ├── vertex_widget.dart     # 頂点ウィジェット
│   │       └── edge_widget.dart       # 辺ウィジェット
│   └── painters/
│       └── board_painter.dart     # ボードペインター
└── widgetbook.dart                # Widgetbookエントリーポイント
```

## 使用方法

### 基本的な使い方

```dart
import 'package:catan_widgets/catan_widgets.dart';

// レイアウトの作成
final layout = HexLayout(
  orientation: HexOrientation.flatTop,
  size: 50.0,
  origin: Offset.zero,
);

// タイルデータの生成
final tiles = BoardDataGenerator.generateStandardBoard();
final vertices = BoardDataGenerator.generateVertices(tiles, layout);
final edges = BoardDataGenerator.generateEdges(tiles, layout);

// ボードの表示
CatanBoardWidget(
  tiles: tiles,
  layout: layout,
  vertices: vertices,
  edges: edges,
  onTileTap: (coordinate) {
    print('Tile tapped: $coordinate');
  },
  onVertexTap: (vertexId) {
    print('Vertex tapped: $vertexId');
  },
  onEdgeTap: (edgeId) {
    print('Edge tapped: $edgeId');
  },
)
```

### 個別ウィジェットの使用

```dart
// 六角形タイル
HexTileWidget(
  coordinate: HexCoordinate(0, 0),
  terrain: TerrainType.forest,
  number: 8,
  hasRobber: false,
  layout: layout,
)

// 頂点（集落）
VertexWidget(
  vertexId: 'v_0_0_1',
  position: Offset(100, 100),
  buildingType: BuildingType.settlement,
  playerColor: PlayerColor.red,
)

// 辺（道路）
EdgeWidget(
  edgeId: 'e_0_0_2',
  startPosition: Offset(50, 50),
  endPosition: Offset(150, 50),
  hasRoad: true,
  playerColor: PlayerColor.blue,
)
```

## 機能

### 座標システム

- **アキシャル座標系**: 六角形グリッドの効率的な表現
- **自動正規化**: 頂点と辺の一意なID生成
- **距離計算**: 六角形間の距離測定

### インタラクション

- **タップ検出**: タイル、頂点、辺のタップイベント
- **ハイライト**: 配置可能な位置の視覚的フィードバック
- **ズーム・パン**: マルチタッチジェスチャー対応

### カスタマイズ

- **色**: 地形タイプとプレイヤーカラーのカスタマイズ可能
- **サイズ**: 六角形サイズの調整
- **向き**: フラットトップ/ポイントトップの選択

## 依存関係

このパッケージは、将来的に以下のパッケージと統合される予定です：

- `models` - ゲームデータモデル（HexTile, Vertex, Edge, Building, Road等）
  - 現在は仮の型定義を使用
  - modelsパッケージ完成後に統合

## 完了条件チェック

- ✅ 六角形タイルが正しく描画される
- ✅ 頂点と辺が正しい位置に配置される
- ✅ タップ検出が動作する
- ✅ 地形タイプに応じた色分けが機能する
- ✅ 数字チップが正しく表示される
- ✅ 集落・都市・道路が描画される
- ✅ プレイヤーカラーが反映される
- ✅ ハイライト機能が動作する
- ✅ ズーム・パン機能が動作する

## デモの実行

```bash
flutter run
```

デモアプリでは以下の操作が可能です：
- ピンチでズーム
- ドラッグでパン
- 「建物追加」ボタンでランダムな位置に建物を配置
- 「道路追加」ボタンでランダムな位置に道路を配置
- 「リセット」ボタンでボードを初期状態に戻す

## TODO（将来の拡張）

- [ ] modelsパッケージとの統合
- [ ] アニメーション効果の追加
- [ ] サウンド効果の追加
- [ ] より詳細な建物デザイン
- [ ] ハーバー（港）の描画
- [ ] ゲームログの表示
- [ ] AIプレイヤーの視覚化

## ライセンス

このプロジェクトは開発中のカタンゲームアプリケーションの一部です。
