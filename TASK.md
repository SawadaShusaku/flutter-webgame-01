# Models担当タスク

## 役割
データモデルの実装

## フェーズ1の担当タスク

### 1. Player, PlayerConfig (models/player.dart, models/player_config.dart)
- Playerクラス: ゲーム中のプレイヤー情報
  - id, name, color
  - resources (Map<ResourceType, int>)
  - developmentCards, victoryPoints
  - settlementsBuilt, citiesBuilt, roadsBuilt
  - hasLongestRoad, hasLargestArmy, knightsPlayed
- PlayerConfigクラス: ゲーム開始前の設定
  - name, color, isCPU, difficulty

### 2. HexTile, Vertex, Edge (models/hex_tile.dart, models/vertex.dart, models/edge.dart)
- HexTile: 六角形タイル
  - id, terrain, number, position, hasRobber
- Vertex: 頂点（集落・都市を配置）
  - id, position, adjacentHexIds, adjacentEdgeIds, building
- Edge: 辺（道路を配置）
  - id, vertex1Id, vertex2Id, road

### 3. Building, Road (models/building.dart, models/road.dart)
- Building: 建設物
  - playerId, type (settlement/city)
- Road: 道路
  - playerId

### 4. DevelopmentCard, GameState (models/development_card.dart, models/game_state.dart)
- DevelopmentCard: 発展カード
  - type, played
- GameState: ゲーム状態全体
  - gameId, players, board, vertices, edges
  - phase, currentPlayerIndex, turnNumber
  - developmentCardDeck, robberHexId, eventLog

### 5. Enum定義 (models/enums.dart)
- ResourceType: lumber, brick, wool, grain, ore
- TerrainType: forest, hills, pasture, fields, mountains, desert
- PlayerColor: red, blue, green, yellow
- BuildingType: settlement, city
- GamePhase: setup, normalPlay, resourceDiscard, robberPlacement, trading, gameOver
- その他必要なenum

## 依存関係
- なし（全ての基礎となる）

## 成果物
- lib/models/player.dart
- lib/models/player_config.dart
- lib/models/hex_tile.dart
- lib/models/vertex.dart
- lib/models/edge.dart
- lib/models/building.dart
- lib/models/road.dart
- lib/models/development_card.dart
- lib/models/game_state.dart
- lib/models/enums.dart

## 完了条件
- 全てのデータモデルクラスが定義される
- JSONシリアライズ/デシリアライズに対応（将来実装）
- コンパイルエラーなし
