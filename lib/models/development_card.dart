import 'enums.dart';

/// 発展カード
class DevelopmentCard {
  final DevelopmentCardType type;
  bool played;

  DevelopmentCard({
    required this.type,
    this.played = false,
  });
}
