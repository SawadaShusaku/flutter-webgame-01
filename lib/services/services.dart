/// Services layer for Catan board game
///
/// このファイルはservices層の全てのサービスをエクスポートします。
library;

export 'board_generator.dart';
export 'resource_service.dart';
export 'game_service.dart';
export 'building_service.dart';

// Phase 3: 通常建設サービスと資源消費
export 'building_costs.dart';
export 'resource_manager.dart';
export 'validation_service.dart';
export 'construction_service.dart';

// Phase 5-6: 発展カードと最長交易路
export 'development_card_service.dart';
export 'longest_road_service.dart';
