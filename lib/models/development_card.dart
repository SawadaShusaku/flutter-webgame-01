import 'enums.dart';

/// 発展カード
class DevelopmentCard {
  final DevelopmentCardType type;
  bool played;

  /// 購入したターン番号（購入したターンは使用不可）
  int? purchasedOnTurn;

  DevelopmentCard({
    required this.type,
    this.played = false,
    this.purchasedOnTurn,
  });
}
