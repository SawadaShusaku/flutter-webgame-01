import 'enums.dart';

/// 建設物（集落または都市）
class Building {
  final String playerId;
  final BuildingType type;

  Building({
    required this.playerId,
    required this.type,
  });

  /// 勝利点
  int get victoryPoints {
    switch (type) {
      case BuildingType.settlement:
        return 1;
      case BuildingType.city:
        return 2;
    }
  }
}
