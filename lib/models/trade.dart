import 'enums.dart';

/// 交易の提案
class TradeOffer {
  final String id;
  final String proposerId; // 提案者のプレイヤーID
  final Map<ResourceType, int> offering; // 提供する資源
  final Map<ResourceType, int> requesting; // 要求する資源
  final DateTime createdAt;
  final Map<String, bool> responses; // プレイヤーID -> 承認/拒否

  TradeOffer({
    required this.id,
    required this.proposerId,
    required this.offering,
    required this.requesting,
    required this.createdAt,
    Map<String, bool>? responses,
  }) : responses = responses ?? {};

  /// 提供する資源の合計数
  int get offeringTotal => offering.values.fold(0, (sum, count) => sum + count);

  /// 要求する資源の合計数
  int get requestingTotal => requesting.values.fold(0, (sum, count) => sum + count);

  /// 指定したプレイヤーが承認したか
  bool hasAccepted(String playerId) => responses[playerId] == true;

  /// 指定したプレイヤーが拒否したか
  bool hasRejected(String playerId) => responses[playerId] == false;

  /// まだ応答していないプレイヤー
  bool hasNotResponded(String playerId) => !responses.containsKey(playerId);

  /// コピーを作成
  TradeOffer copyWith({
    String? id,
    String? proposerId,
    Map<ResourceType, int>? offering,
    Map<ResourceType, int>? requesting,
    DateTime? createdAt,
    Map<String, bool>? responses,
  }) {
    return TradeOffer(
      id: id ?? this.id,
      proposerId: proposerId ?? this.proposerId,
      offering: offering ?? this.offering,
      requesting: requesting ?? this.requesting,
      createdAt: createdAt ?? this.createdAt,
      responses: responses ?? this.responses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'proposerId': proposerId,
      'offering': offering.map((k, v) => MapEntry(k.toString(), v)),
      'requesting': requesting.map((k, v) => MapEntry(k.toString(), v)),
      'createdAt': createdAt.toIso8601String(),
      'responses': responses,
    };
  }
}

/// 交易タイプ
enum TradeType {
  bankTrade, // 銀行交易（4:1）
  harborTrade3to1, // 3:1港交易
  harborTrade2to1, // 2:1港交易
  playerTrade, // プレイヤー間交易
}

/// 港のタイプ
enum HarborType {
  generic, // 汎用港（3:1）
  lumber, // 木材港（2:1）
  brick, // レンガ港（2:1）
  wool, // 羊毛港（2:1）
  grain, // 小麦港（2:1）
  ore, // 鉱石港（2:1）
}

/// 港
class Harbor {
  final String id;
  final HarborType type;
  final List<String> vertexIds; // この港に接続する頂点ID

  Harbor({
    required this.id,
    required this.type,
    required this.vertexIds,
  });

  /// 交易レート（何対1か）
  int get tradeRate {
    return type == HarborType.generic ? 3 : 2;
  }

  /// 特定の資源タイプか
  bool get isSpecific => type != HarborType.generic;

  /// 港の資源タイプ（汎用港の場合はnull）
  ResourceType? get resourceType {
    switch (type) {
      case HarborType.lumber:
        return ResourceType.lumber;
      case HarborType.brick:
        return ResourceType.brick;
      case HarborType.wool:
        return ResourceType.wool;
      case HarborType.grain:
        return ResourceType.grain;
      case HarborType.ore:
        return ResourceType.ore;
      case HarborType.generic:
        return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'vertexIds': vertexIds,
    };
  }
}
