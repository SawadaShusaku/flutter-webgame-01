/// Catan board game UI widgets library
///
/// This library provides customizable widgets for rendering Catan board game components:
/// - Hexagonal tiles with terrain types and number chips
/// - Vertices for settlements and cities
/// - Edges for roads
/// - Complete board painter with zoom and pan support
///
/// Usage:
/// ```dart
/// import 'package:catan_widgets/catan_widgets.dart';
/// ```
library catan_widgets;

// Utils
export 'utils/hex_math.dart';

// Widgets
export 'ui/widgets/board/hex_tile_widget.dart';
export 'ui/widgets/board/vertex_widget.dart';
export 'ui/widgets/board/edge_widget.dart';

// Painters
export 'ui/painters/board_painter.dart';
