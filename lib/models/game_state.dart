import 'player.dart';
import 'hex_tile.dart';
import 'vertex.dart';
import 'edge.dart';
import 'development_card.dart';
import 'enums.dart';

/// ゲーム状態全体
class GameState {
  final String gameId;
  final List<Player> players;
  final List<HexTile> board;
  final List<Vertex> vertices;
  final List<Edge> edges;
  final List<DevelopmentCard> developmentCardDeck;

  GamePhase phase;
  int currentPlayerIndex;
  int turnNumber;

  DiceRoll? lastDiceRoll;
  String? robberHexId;  // 盗賊の位置

  final List<GameEvent> eventLog;

  GameState({
    required this.gameId,
    required this.players,
    required this.board,
    required this.vertices,
    required this.edges,
    required this.developmentCardDeck,
    this.phase = GamePhase.setup,
    this.currentPlayerIndex = 0,
    this.turnNumber = 0,
    this.lastDiceRoll,
    this.robberHexId,
    List<GameEvent>? eventLog,
  }) : eventLog = eventLog ?? [];

  /// 現在のプレイヤー
  Player get currentPlayer => players[currentPlayerIndex];

  /// 次のプレイヤーに進む
  void nextPlayer() {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    if (currentPlayerIndex == 0) {
      turnNumber++;
    }
  }

  /// イベントをログに追加
  void logEvent(GameEvent event) {
    eventLog.add(event);
  }

  /// 発展カードを引く
  DevelopmentCard? drawDevelopmentCard() {
    if (developmentCardDeck.isEmpty) return null;
    return developmentCardDeck.removeLast();
  }
}

/// サイコロの目
class DiceRoll {
  final int die1;
  final int die2;

  DiceRoll(this.die1, this.die2)
      : assert(die1 >= 1 && die1 <= 6, 'サイコロの目は1-6です'),
        assert(die2 >= 1 && die2 <= 6, 'サイコロの目は1-6です');

  int get total => die1 + die2;
}

/// ゲームイベント
class GameEvent {
  final DateTime timestamp;
  final String playerId;
  final GameEventType type;
  final Map<String, dynamic> data;

  GameEvent({
    required this.timestamp,
    required this.playerId,
    required this.type,
    required this.data,
  });
}
