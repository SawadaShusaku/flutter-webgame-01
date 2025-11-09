# Phase 5-6: 交易UIサービスと発展カード

## タスク概要
交易UIのバックエンドと発展カード機能を実装してください。

## 実装内容

### 1. `lib/services/development_card_service.dart` を作成
- 発展カード購入: `buyDevelopmentCard()`
- カード使用ロジック:
  - 騎士カード: `playKnightCard()` - 盗賊を移動
  - 街道建設: `playRoadBuildingCard()` - 道路2本建設
  - 資源発見: `playYearOfPlentyCard()` - 好きな資源2枚獲得
  - 資源独占: `playMonopolyCard()` - 指定資源を全員から奪う
- 最大騎士力の判定
- カード使用制限（同ターンに購入したカードは使えない）

### 2. `lib/services/longest_road_service.dart` を作成
- 最長交易路の計算
- プレイヤーの道路ネットワーク解析
- 最長ルート探索（深さ優先探索）
- 5本以上で最長交易路ボーナス（2点）

### 3. 既存の `game_controller.dart` を拡張
- `buyDevelopmentCard()` メソッド追加
- `playDevelopmentCard()` メソッド追加
- 最長交易路・最大騎士力の更新処理

## 重要ポイント
- 発展カードは購入したターンには使えない
- 騎士カード3枚以上で最大騎士力（2点）
- 勝利点カードは即座に公開される

完成したら commit してください。
