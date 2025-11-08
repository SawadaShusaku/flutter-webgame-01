import 'enums.dart';

/// ゲーム開始前のプレイヤー設定
class PlayerConfig {
  final String name;
  final PlayerColor color;
  final bool isCPU;
  final CPUDifficulty? difficulty;

  PlayerConfig({
    required this.name,
    required this.color,
    this.isCPU = false,
    this.difficulty,
  }) : assert(!isCPU || difficulty != null, 'CPUプレイヤーには難易度が必要です');
}

/// ゲーム全体の設定
class GameConfig {
  final int playerCount;
  final List<PlayerConfig> players;
  final bool randomBoard;
  final bool tutorialMode;

  GameConfig({
    required this.playerCount,
    required this.players,
    this.randomBoard = true,
    this.tutorialMode = false,
  }) : assert(playerCount >= 2 && playerCount <= 4, 'プレイヤー数は2-4人です'),
       assert(players.length == playerCount, 'プレイヤー設定の数が一致しません');
}
