// modelsからimport
import 'package:test_web_app/models/game_state.dart';
import 'package:test_web_app/models/player.dart';
import 'package:test_web_app/models/development_card.dart';
import 'package:test_web_app/models/enums.dart';
import 'package:test_web_app/models/hex_tile.dart';

// servicesからimport
import 'package:test_web_app/services/resource_manager.dart';

/// 発展カード使用結果
class DevelopmentCardResult {
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic>? data;

  const DevelopmentCardResult.success([this.data])
      : success = true,
        errorMessage = null;

  const DevelopmentCardResult.failure(this.errorMessage)
      : success = false,
        data = null;

  @override
  String toString() {
    return success ? 'Success' : 'Failed: $errorMessage';
  }
}

/// 発展カード管理サービス
///
/// Phase 5-6: 発展カードの購入と使用を管理
/// - 騎士カード: 盗賊を移動して資源を奪う
/// - 街道建設: 道路2本を無料で建設
/// - 資源発見: 好きな資源2枚を獲得
/// - 資源独占: 指定資源を全プレイヤーから奪う
/// - 勝利点カード: 即座に公開され1勝利点
class DevelopmentCardService {
  final ResourceManager _resourceManager;

  /// 今ターンに購入したカードを追跡（同ターン使用制限のため）
  final Set<DevelopmentCard> _cardsPurchasedThisTurn = {};

  DevelopmentCardService({
    ResourceManager? resourceManager,
  }) : _resourceManager = resourceManager ?? ResourceManager();

  /// ターン開始時に呼び出す（購入制限リセット）
  void startTurn() {
    _cardsPurchasedThisTurn.clear();
  }

  /// 発展カード購入時に呼び出す
  void notifyCardPurchased(DevelopmentCard card) {
    _cardsPurchasedThisTurn.add(card);
  }

  // ========== 騎士カード ==========

  /// 騎士カードを使用
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  /// [card] 使用するカード
  /// [newRobberHexId] 盗賊の移動先タイルID
  /// [targetPlayerId] 資源を奪う対象プレイヤーID（nullの場合は奪わない）
  ///
  /// 戻り値: 使用結果
  DevelopmentCardResult playKnightCard(
    GameState gameState,
    String playerId,
    DevelopmentCard card,
    String newRobberHexId,
    String? targetPlayerId,
  ) {
    // 1. 検証
    final validation = _validateCardPlay(gameState, playerId, card);
    if (!validation.success) {
      return validation;
    }

    if (card.type != DevelopmentCardType.knight) {
      return const DevelopmentCardResult.failure('騎士カードではありません');
    }

    // 2. 盗賊の移動先が有効かチェック
    final hex = gameState.board.firstWhere(
      (h) => h.id == newRobberHexId,
      orElse: () => throw ArgumentError('無効なタイルID: $newRobberHexId'),
    );

    if (gameState.robberHexId == newRobberHexId) {
      return const DevelopmentCardResult.failure('盗賊は同じ場所に移動できません');
    }

    // 3. プレイヤーを取得
    final player = gameState.players.firstWhere((p) => p.id == playerId);

    // 4. カードを使用
    if (!player.playDevelopmentCard(card)) {
      return const DevelopmentCardResult.failure('カードの使用に失敗しました');
    }

    // 5. 盗賊を移動
    final oldRobberHexId = gameState.robberHexId;
    gameState.robberHexId = newRobberHexId;

    // 6. 対象プレイヤーから資源を奪う
    ResourceType? stolenResource;
    if (targetPlayerId != null && targetPlayerId != playerId) {
      final targetPlayer =
          gameState.players.firstWhere((p) => p.id == targetPlayerId);

      // ランダムに資源を1枚奪う
      final availableResources = <ResourceType>[];
      targetPlayer.resources.forEach((type, count) {
        for (int i = 0; i < count; i++) {
          availableResources.add(type);
        }
      });

      if (availableResources.isNotEmpty) {
        availableResources.shuffle();
        stolenResource = availableResources.first;
        targetPlayer.removeResource(stolenResource, 1);
        player.addResource(stolenResource, 1);
      }
    }

    // 7. 最大騎士力をチェック
    _updateLargestArmy(gameState);

    // 8. 勝利点を更新
    player.victoryPoints = player.calculateVictoryPoints();

    // 9. イベントログに追加
    gameState.logEvent(GameEvent(
      timestamp: DateTime.now(),
      playerId: playerId,
      type: GameEventType.cardPlayed,
      data: {
        'cardType': 'knight',
        'oldRobberHexId': oldRobberHexId,
        'newRobberHexId': newRobberHexId,
        'targetPlayerId': targetPlayerId,
        'stolenResource': stolenResource?.name,
        'knightsPlayed': player.knightsPlayed,
      },
    ));

    return DevelopmentCardResult.success({
      'robberMoved': true,
      'stolenResource': stolenResource,
      'knightsPlayed': player.knightsPlayed,
      'hasLargestArmy': player.hasLargestArmy,
      'victoryPoints': player.victoryPoints,
    });
  }

  // ========== 街道建設カード ==========

  /// 街道建設カードを使用
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  /// [card] 使用するカード
  ///
  /// 戻り値: 使用結果（道路建設は別途呼び出す必要がある）
  DevelopmentCardResult playRoadBuildingCard(
    GameState gameState,
    String playerId,
    DevelopmentCard card,
  ) {
    // 1. 検証
    final validation = _validateCardPlay(gameState, playerId, card);
    if (!validation.success) {
      return validation;
    }

    if (card.type != DevelopmentCardType.roadBuilding) {
      return const DevelopmentCardResult.failure('街道建設カードではありません');
    }

    // 2. プレイヤーを取得
    final player = gameState.players.firstWhere((p) => p.id == playerId);

    // 3. カードを使用
    if (!player.playDevelopmentCard(card)) {
      return const DevelopmentCardResult.failure('カードの使用に失敗しました');
    }

    // 4. イベントログに追加
    gameState.logEvent(GameEvent(
      timestamp: DateTime.now(),
      playerId: playerId,
      type: GameEventType.cardPlayed,
      data: {
        'cardType': 'roadBuilding',
      },
    ));

    return DevelopmentCardResult.success({
      'freeRoads': 2,
    });
  }

  // ========== 資源発見カード ==========

  /// 資源発見カードを使用
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  /// [card] 使用するカード
  /// [resource1] 獲得する資源1
  /// [resource2] 獲得する資源2
  ///
  /// 戻り値: 使用結果
  DevelopmentCardResult playYearOfPlentyCard(
    GameState gameState,
    String playerId,
    DevelopmentCard card,
    ResourceType resource1,
    ResourceType resource2,
  ) {
    // 1. 検証
    final validation = _validateCardPlay(gameState, playerId, card);
    if (!validation.success) {
      return validation;
    }

    if (card.type != DevelopmentCardType.yearOfPlenty) {
      return const DevelopmentCardResult.failure('資源発見カードではありません');
    }

    // 2. プレイヤーを取得
    final player = gameState.players.firstWhere((p) => p.id == playerId);

    // 3. カードを使用
    if (!player.playDevelopmentCard(card)) {
      return const DevelopmentCardResult.failure('カードの使用に失敗しました');
    }

    // 4. 資源を獲得
    player.addResource(resource1, 1);
    player.addResource(resource2, 1);

    // 5. イベントログに追加
    gameState.logEvent(GameEvent(
      timestamp: DateTime.now(),
      playerId: playerId,
      type: GameEventType.cardPlayed,
      data: {
        'cardType': 'yearOfPlenty',
        'resource1': resource1.name,
        'resource2': resource2.name,
      },
    ));

    return DevelopmentCardResult.success({
      'resources': [resource1, resource2],
    });
  }

  // ========== 資源独占カード ==========

  /// 資源独占カードを使用
  ///
  /// [gameState] ゲーム状態
  /// [playerId] プレイヤーID
  /// [card] 使用するカード
  /// [resourceType] 奪う資源の種類
  ///
  /// 戻り値: 使用結果
  DevelopmentCardResult playMonopolyCard(
    GameState gameState,
    String playerId,
    DevelopmentCard card,
    ResourceType resourceType,
  ) {
    // 1. 検証
    final validation = _validateCardPlay(gameState, playerId, card);
    if (!validation.success) {
      return validation;
    }

    if (card.type != DevelopmentCardType.monopoly) {
      return const DevelopmentCardResult.failure('資源独占カードではありません');
    }

    // 2. プレイヤーを取得
    final player = gameState.players.firstWhere((p) => p.id == playerId);

    // 3. カードを使用
    if (!player.playDevelopmentCard(card)) {
      return const DevelopmentCardResult.failure('カードの使用に失敗しました');
    }

    // 4. 全プレイヤーから指定資源を奪う
    int totalStolen = 0;
    for (final otherPlayer in gameState.players) {
      if (otherPlayer.id == playerId) continue;

      final amount = otherPlayer.resources[resourceType] ?? 0;
      if (amount > 0) {
        otherPlayer.removeResource(resourceType, amount);
        totalStolen += amount;
      }
    }

    // 5. 奪った資源を獲得
    player.addResource(resourceType, totalStolen);

    // 6. イベントログに追加
    gameState.logEvent(GameEvent(
      timestamp: DateTime.now(),
      playerId: playerId,
      type: GameEventType.cardPlayed,
      data: {
        'cardType': 'monopoly',
        'resourceType': resourceType.name,
        'totalStolen': totalStolen,
      },
    ));

    return DevelopmentCardResult.success({
      'resourceType': resourceType,
      'totalStolen': totalStolen,
    });
  }

  // ========== 勝利点カード ==========

  /// 勝利点カードは購入時に自動的に公開され、勝利点が加算される
  /// このメソッドは明示的な使用には必要ないが、一貫性のために提供

  // ========== ヘルパーメソッド ==========

  /// カード使用の共通検証
  DevelopmentCardResult _validateCardPlay(
    GameState gameState,
    String playerId,
    DevelopmentCard card,
  ) {
    // プレイヤーを取得
    final player = gameState.players.firstWhere(
      (p) => p.id == playerId,
      orElse: () => throw ArgumentError('無効なプレイヤーID: $playerId'),
    );

    // プレイヤーがカードを持っているか
    if (!player.developmentCards.contains(card)) {
      return const DevelopmentCardResult.failure('このカードを持っていません');
    }

    // カードが既に使用されているか
    if (card.played) {
      return const DevelopmentCardResult.failure('このカードは既に使用されています');
    }

    // 同ターンに購入したカードは使えない
    if (_cardsPurchasedThisTurn.contains(card)) {
      return const DevelopmentCardResult.failure(
          '購入したターンにはカードを使用できません');
    }

    // 勝利点カードは手動で使用できない
    if (card.type == DevelopmentCardType.victoryPoint) {
      return const DevelopmentCardResult.failure('勝利点カードは自動的に公開されます');
    }

    return const DevelopmentCardResult.success();
  }

  /// 最大騎士力の更新
  void _updateLargestArmy(GameState gameState) {
    // 最小騎士数（3枚以上）
    const int minKnights = 3;

    // 現在最大騎士力を持っているプレイヤー
    Player? currentLargestArmyPlayer;
    int currentMaxKnights = minKnights - 1;

    for (final player in gameState.players) {
      if (player.hasLargestArmy) {
        currentLargestArmyPlayer = player;
        currentMaxKnights = player.knightsPlayed;
        break;
      }
    }

    // 全プレイヤーの騎士数をチェック
    Player? newLargestArmyPlayer;
    int maxKnights = currentMaxKnights;

    for (final player in gameState.players) {
      if (player.knightsPlayed >= minKnights &&
          player.knightsPlayed > maxKnights) {
        maxKnights = player.knightsPlayed;
        newLargestArmyPlayer = player;
      }
    }

    // 最大騎士力が変更された場合
    if (newLargestArmyPlayer != null &&
        newLargestArmyPlayer != currentLargestArmyPlayer) {
      // 古い保持者から剥奪
      if (currentLargestArmyPlayer != null) {
        currentLargestArmyPlayer.hasLargestArmy = false;
        currentLargestArmyPlayer.victoryPoints =
            currentLargestArmyPlayer.calculateVictoryPoints();
      }

      // 新しい保持者に付与
      newLargestArmyPlayer.hasLargestArmy = true;
      newLargestArmyPlayer.victoryPoints =
          newLargestArmyPlayer.calculateVictoryPoints();
    }
  }

  /// プレイヤーが使用可能なカードのリストを取得
  ///
  /// [player] プレイヤー
  ///
  /// 戻り値: 使用可能なカードのリスト
  List<DevelopmentCard> getPlayableCards(Player player) {
    return player.developmentCards.where((card) {
      return !card.played &&
          !_cardsPurchasedThisTurn.contains(card) &&
          card.type != DevelopmentCardType.victoryPoint;
    }).toList();
  }

  /// プレイヤーのカード種別ごとの枚数を取得
  ///
  /// [player] プレイヤー
  ///
  /// 戻り値: カード種別ごとの枚数マップ
  Map<DevelopmentCardType, int> getCardCounts(Player player) {
    final counts = <DevelopmentCardType, int>{
      DevelopmentCardType.knight: 0,
      DevelopmentCardType.victoryPoint: 0,
      DevelopmentCardType.roadBuilding: 0,
      DevelopmentCardType.yearOfPlenty: 0,
      DevelopmentCardType.monopoly: 0,
    };

    for (final card in player.developmentCards) {
      if (!card.played) {
        counts[card.type] = (counts[card.type] ?? 0) + 1;
      }
    }

    return counts;
  }
}
