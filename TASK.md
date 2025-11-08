# UI Widgets担当タスク

## 役割
ウィジェットの実装

## フェーズ1の担当タスク

### 1. HexTileWidget (ui/widgets/board/hex_tile_widget.dart)
- 六角形タイルの描画
- 地形タイプに応じた色分け
- 数字チップの表示
- 盗賊の表示

### 2. VertexWidget (ui/widgets/board/vertex_widget.dart)
- 頂点の描画
- 集落・都市の表示
- タップ検出
- ハイライト表示

### 3. EdgeWidget (ui/widgets/board/edge_widget.dart)
- 辺の描画
- 道路の表示
- タップ検出
- ハイライト表示

### 4. BoardPainter (ui/painters/board_painter.dart)
- CustomPainterでボード全体を描画
- 六角形の座標計算
- パフォーマンス最適化

## 依存関係
- models/ のデータモデルを使用
- utils/hex_math.dart の座標計算を使用

## 成果物
- lib/ui/widgets/board/hex_tile_widget.dart
- lib/ui/widgets/board/vertex_widget.dart
- lib/ui/widgets/board/edge_widget.dart
- lib/ui/painters/board_painter.dart

## 完了条件
- 六角形タイルが正しく描画される
- 頂点と辺が正しい位置に配置される
- タップ検出が動作する
