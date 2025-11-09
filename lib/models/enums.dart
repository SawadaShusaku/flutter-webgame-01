// Enum definitions for Catan board game

/// 資源の種類
enum ResourceType {
  lumber,    // 木材
  brick,     // レンガ
  wool,      // 羊毛
  grain,     // 小麦
  ore,       // 鉱石
}

/// 地形タイプ
enum TerrainType {
  forest,     // 森（木材）
  hills,      // 丘陵（レンガ）
  pasture,    // 牧草地（羊毛）
  fields,     // 畑（小麦）
  mountains,  // 山（鉱石）
  desert,     // 砂漠（資源なし）
}

/// プレイヤーカラー
enum PlayerColor {
  red,
  blue,
  green,
  yellow,
}

/// 建設物のタイプ
enum BuildingType {
  settlement,  // 集落（1勝利点）
  city,        // 都市（2勝利点）
}

/// 発展カードのタイプ
enum DevelopmentCardType {
  knight,         // 騎士（14枚）
  victoryPoint,   // 勝利点（5枚）
  roadBuilding,   // 街道建設（2枚）
  yearOfPlenty,   // 資源発見（2枚）
  monopoly,       // 資源独占（2枚）
}

/// ゲームフェーズ
enum GamePhase {
  setup,            // 初期配置フェーズ
  normalPlay,       // 通常プレイ
  resourceDiscard,  // 資源破棄（7が出たとき）
  robberPlacement,  // 盗賊配置
  trading,          // 交渉中（プレイヤー間取引）
  gameOver,         // ゲーム終了
}

/// 交渉オファーの状態
enum TradeOfferStatus {
  pending,    // 保留中（相手の返答待ち）
  accepted,   // 承諾
  rejected,   // 拒否
  cancelled,  // 取り消し
}

/// ゲームイベントのタイプ
enum GameEventType {
  diceRolled,          // サイコロを振った
  resourceGained,      // 資源を獲得
  resourceLost,        // 資源を失った
  buildingPlaced,      // 建設物を配置
  roadPlaced,          // 道路を配置
  cardPurchased,       // カードを購入
  cardPlayed,          // カードを使用
  tradeProposed,       // 交渉提案
  tradeAccepted,       // 交渉承諾
  tradeRejected,       // 交渉拒否
  tradeCancelled,      // 交渉取り消し
  tradeCompleted,      // 交渉成立
  bankTradeCompleted,  // 銀行取引完了
  robberMoved,         // 盗賊を移動
}

/// CPU難易度
enum CPUDifficulty {
  easy,    // 簡単
  normal,  // 普通
  hard,    // 難しい
}

/// プレイヤータイプ
enum PlayerType {
  human,   // 人間
  cpu,     // CPU
}

/// 建設モード
enum BuildMode {
  none,        // 建設モードなし
  settlement,  // 集落建設モード
  road,        // 道路建設モード
  city,        // 都市建設モード
}
