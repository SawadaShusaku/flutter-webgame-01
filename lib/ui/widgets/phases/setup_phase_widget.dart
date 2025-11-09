import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_web_app/services/game_controller.dart';
import 'package:test_web_app/models/enums.dart';
import 'package:test_web_app/ui/widgets/board/game_board_widget.dart';
import 'package:test_web_app/utils/constants.dart';

/// 初期配置フェーズのWidget
class SetupPhaseWidget extends StatelessWidget {
  const SetupPhaseWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, child) {
        final state = controller.state!;
        final currentPlayer = controller.currentPlayer!;

        return Scaffold(
          backgroundColor: Colors.lightBlue[100],
          appBar: AppBar(
            backgroundColor: Colors.brown[700],
            title: const Text('初期配置フェーズ'),
            actions: [
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _showGameMenu(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // ヘッダー
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: GameColors.getPlayerColor(currentPlayer.color),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${currentPlayer.name}のターン',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // プレイヤータイプ表示
                    if (currentPlayer.playerType == PlayerType.cpu)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple, width: 1),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.computer, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'CPU',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // ボード表示
              Expanded(
                child: Center(
                  child: GameBoardWidget(
                    hexTiles: state.board,
                    vertices: state.vertices,
                    edges: state.edges,
                    onVertexTap: (vertex) => controller.onVertexTapped(vertex.id),
                    onEdgeTap: (edge) => controller.onEdgeTapped(edge.id),
                    highlightedVertexIds: _getHighlightedVertices(controller),
                    highlightedEdgeIds: _getHighlightedEdges(controller),
                  ),
                ),
              ),

              // 説明
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.orange[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      controller.buildMode == BuildMode.settlement
                          ? Icons.home
                          : Icons.route,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      controller.buildMode == BuildMode.settlement
                          ? '集落を配置してください（交点をタップ）'
                          : '道路を配置してください（辺をタップ）',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// BuildModeに応じてハイライトする頂点のIDを取得
  Set<String> _getHighlightedVertices(GameController controller) {
    if (controller.buildMode == BuildMode.settlement) {
      // 簡易版: 空いている頂点のみハイライト
      return controller.state?.vertices
              .where((v) => !v.hasBuilding)
              .map((v) => v.id)
              .toSet() ??
          {};
    }
    return {};
  }

  /// BuildModeに応じてハイライトする辺のIDを取得
  Set<String> _getHighlightedEdges(GameController controller) {
    if (controller.buildMode == BuildMode.road) {
      // 簡易版: 空いている辺のみハイライト
      return controller.state?.edges
              .where((e) => !e.hasRoad)
              .map((e) => e.id)
              .toSet() ??
          {};
    }
    return {};
  }

  void _showGameMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ゲームメニュー'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('ヘルプ'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ヘルプは実装予定です')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('メニューに戻る'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
