/// Catan board game UI widgets library
///
/// This library provides customizable widgets for rendering Catan board game components:
/// - Hexagonal tiles with terrain types and number chips
/// - Vertices for settlements and cities
/// - Edges for roads
/// - Complete board painter with zoom and pan support
/// - Game board widget with BoardGenerator integration
/// - Player info and resource management widgets
/// - Build actions and victory points widgets
/// - Development card UI and interactions
/// - Achievements display (longest road, largest army)
///
/// Usage:
/// ```dart
/// import 'package:catan_widgets/catan_widgets.dart';
/// ```
library catan_widgets;

// Utils
export 'utils/hex_math.dart';
export 'utils/constants.dart';

// Board Widgets
export 'ui/widgets/board/hex_tile_widget.dart';
export 'ui/widgets/board/vertex_widget.dart';
export 'ui/widgets/board/edge_widget.dart';
export 'ui/widgets/board/game_board_widget.dart';

// Player Widgets
export 'ui/widgets/player/player_hand_widget.dart';
export 'ui/widgets/player/player_info_widget.dart';

// Action Widgets
export 'ui/widgets/actions/build_actions_widget.dart';
export 'ui/widgets/actions/victory_points_widget.dart';
export 'ui/widgets/actions/card_action_dialog.dart';

// Card Widgets
export 'ui/widgets/cards/development_card_widget.dart';
export 'ui/widgets/cards/card_hand_widget.dart';

// Game Info Widgets
export 'ui/widgets/game_info/achievements_widget.dart';

// Painters
export 'ui/painters/board_painter.dart';

// Demo
export 'game_board_demo.dart';
