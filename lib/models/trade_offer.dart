import 'enums.dart';

/// 交易オファー
class TradeOffer {
  final String id;
  final String fromPlayerId;  // 提案者
  final String toPlayerId;    // 相手プレイヤー（nullの場合は全員に提案）

  /// 提供する資源
  final Map<ResourceType, int> offering;

  /// 要求する資源
  final Map<ResourceType, int> requesting;

  /// オファーの状態
  TradeOfferStatus status;

  final DateTime createdAt;
  DateTime? respondedAt;

  TradeOffer({
    required this.id,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.offering,
    required this.requesting,
    this.status = TradeOfferStatus.pending,
    DateTime? createdAt,
    this.respondedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 提供する資源の総数
  int get offeringTotal {
    return offering.values.fold(0, (sum, count) => sum + count);
  }

  /// 要求する資源の総数
  int get requestingTotal {
    return requesting.values.fold(0, (sum, count) => sum + count);
  }

  /// オファーを承諾
  void accept() {
    status = TradeOfferStatus.accepted;
    respondedAt = DateTime.now();
  }

  /// オファーを拒否
  void reject() {
    status = TradeOfferStatus.rejected;
    respondedAt = DateTime.now();
  }

  /// オファーをキャンセル
  void cancel() {
    status = TradeOfferStatus.cancelled;
    respondedAt = DateTime.now();
  }

  /// オファーが有効か（保留中）
  bool get isPending => status == TradeOfferStatus.pending;

  /// オファーが承諾されたか
  bool get isAccepted => status == TradeOfferStatus.accepted;

  /// オファーが拒否されたか
  bool get isRejected => status == TradeOfferStatus.rejected;

  /// オファーがキャンセルされたか
  bool get isCancelled => status == TradeOfferStatus.cancelled;

  /// コピーを作成
  TradeOffer copyWith({
    String? id,
    String? fromPlayerId,
    String? toPlayerId,
    Map<ResourceType, int>? offering,
    Map<ResourceType, int>? requesting,
    TradeOfferStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return TradeOffer(
      id: id ?? this.id,
      fromPlayerId: fromPlayerId ?? this.fromPlayerId,
      toPlayerId: toPlayerId ?? this.toPlayerId,
      offering: offering ?? Map.from(this.offering),
      requesting: requesting ?? Map.from(this.requesting),
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}

/// 銀行取引
class BankTrade {
  final String playerId;
  final ResourceType giving;
  final int givingAmount;
  final ResourceType receiving;
  final int receivingAmount;
  final DateTime timestamp;

  BankTrade({
    required this.playerId,
    required this.giving,
    required this.givingAmount,
    required this.receiving,
    required this.receivingAmount,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 取引レート
  int get rate => givingAmount ~/ receivingAmount;
}
