import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_web_app/services/game_controller.dart';
import 'package:test_web_app/models/game_state.dart';
import 'package:test_web_app/models/enums.dart';
import 'package:test_web_app/ui/widgets/board/game_board_widget.dart';
import 'package:test_web_app/ui/widgets/log/game_log_widget.dart';
import 'package:test_web_app/ui/widgets/actions/dice_roller.dart';
import 'package:test_web_app/ui/widgets/bank_trade_dialog.dart';
import 'package:test_web_app/ui/screens/trade_screen.dart';
import 'package:test_web_app/ui/widgets/cards/card_hand_widget.dart';
import 'package:test_web_app/ui/widgets/game_info/achievements_widget.dart';
import 'package:test_web_app/utils/constants.dart';

class NormalPlayScreen extends StatefulWidget {
  const NormalPlayScreen({super.key});

  @override
  State<NormalPlayScreen> createState() => _NormalPlayScreenState();
}

class _NormalPlayScreenState extends State<NormalPlayScreen> {
  DiceRoll? _lastShownDiceRoll;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      appBar: AppBar(
        backgroundColor: Colors.brown[700],
        title: const Text('カタン'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _showGameMenu(context),
          ),
        ],
      ),
      body: Consumer<GameController>(
        builder: (context, controller, child) {
          // サイコロの結果が変わった時にフィードバックを表示
          _showDiceResultFeedback(context, controller);

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 800;

              if (isWideScreen) {
                return _buildWideLayout(controller);
              } else {
                return _buildNarrowLayout(controller);
              }
            },
          );
        },
      ),
    );
  }

  /// サイコロの結果に対するフィードバックを表示
  void _showDiceResultFeedback(BuildContext context, GameController controller) {
    final currentRoll = controller.lastDiceRoll;

    // 新しいサイコロの結果が出た場合のみ処理
    if (currentRoll != null && currentRoll != _lastShownDiceRoll) {
      _lastShownDiceRoll = currentRoll;

      // ビルド完了後にSnackBarを表示
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (currentRoll.total == 7) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Text('7が出ました！盗賊を移動してください'),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.casino, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('${currentRoll.total}が出ました！資源を獲得'),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    }
  }

  /// ワイドスクリーン用レイアウト
  Widget _buildWideLayout(GameController controller) {
    return Column(
      children: [
        // 上部：プレイヤー情報
        _buildPlayerStatusBar(controller),

        // メインエリア
        Expanded(
          child: Row(
            children: [
              // 左側：ゲームボード + 手札
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // ゲームボード
                    Expanded(
                      flex: 3,
                      child: GameBoardWidget(
                        hexTiles: controller.state?.board ?? [],
                        vertices: controller.state?.vertices ?? [],
                        edges: controller.state?.edges ?? [],
                        harbors: controller.state?.harbors,
                        robber: controller.state?.robber,
                        onVertexTap: (vertex) => controller.onVertexTapped(vertex.id),
                        onEdgeTap: (edge) => controller.onEdgeTapped(edge.id),
                        highlightedVertexIds: _getHighlightedVertices(controller),
                        highlightedEdgeIds: _getHighlightedEdges(controller),
                      ),
                    ),
                    // 手札
                    SizedBox(
                      height: 120,
                      child: _buildHandArea(controller),
                    ),
                  ],
                ),
              ),

              // 右側：アクションパネル + ログ
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    // アクションパネル
                    _buildActionPanel(controller),
                    const SizedBox(height: 8),
                    // ゲームログ
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GameLogWidget(entries: const []),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ナロースクリーン用レイアウト
  Widget _buildNarrowLayout(GameController controller) {
    return Column(
      children: [
        // 上部：プレイヤー情報
        _buildPlayerStatusBar(controller),

        // ゲームボードとログ
        Expanded(
          flex: 2,
          child: Stack(
            children: [
              // ゲームボード
              GameBoardWidget(
                hexTiles: controller.state?.board ?? [],
                vertices: controller.state?.vertices ?? [],
                edges: controller.state?.edges ?? [],
                harbors: controller.state?.harbors,
                robber: controller.state?.robber,
                onVertexTap: (vertex) => controller.onVertexTapped(vertex.id),
                onEdgeTap: (edge) => controller.onEdgeTapped(edge.id),
                highlightedVertexIds: _getHighlightedVertices(controller),
                highlightedEdgeIds: _getHighlightedEdges(controller),
              ),
              // ログ（オーバーレイ）
              Positioned(
                right: 8,
                top: 8,
                bottom: 8,
                width: 200,
                child: GameLogWidget(entries: const []),
              ),
            ],
          ),
        ),

        // 手札
        SizedBox(
          height: 100,
          child: _buildHandArea(controller),
        ),

        // アクションボタン
        _buildActionPanel(controller),
      ],
    );
  }

  /// プレイヤーステータスバー
  Widget _buildPlayerStatusBar(GameController controller) {
    final currentPlayer = controller.currentPlayer;
    final state = controller.state;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 現在のプレイヤー
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: currentPlayer != null
                  ? GameColors.getPlayerColor(currentPlayer.color)
                  : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            currentPlayer?.name ?? '???',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          // ターン数
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'ターン ${state?.turnNumber ?? 0}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),

          // 特別ボーナス表示
          if (state != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: AchievementsWidget(
                longestRoadPlayer: state.longestRoadPlayer,
                longestRoadLength: state.longestRoadLength,
                largestArmyPlayer: state.largestArmyPlayer,
                largestArmySize: state.largestArmySize,
                compact: true,
              ),
            ),

          // 勝利点
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '${currentPlayer?.victoryPoints ?? 0}点',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // サイコロ結果
          if (controller.lastDiceRoll != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.casino, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${controller.lastDiceRoll}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 手札エリア
  Widget _buildHandArea(GameController controller) {
    final resources = controller.currentPlayer?.resources ?? {};

    return Container(
      color: Colors.brown[100],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '手札',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: resources.entries.map((entry) {
                return _ResourceCard(
                  name: entry.key.name,
                  count: entry.value,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// アクションパネル
  Widget _buildActionPanel(GameController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // サイコロウィジェット
          DiceRoller(
            onRoll: () => controller.rollDice(),
            canRoll: !controller.hasRolledDice,
            lastRoll: controller.lastDiceRoll,
          ),

          const SizedBox(height: 8),

          // 建設ボタン
          Row(
            children: [
              Expanded(
                child: _BuildButton(
                  icon: Icons.home,
                  label: '集落',
                  enabled: controller.canBuildSettlement(),
                  isActive: controller.buildMode == BuildMode.settlement,
                  onPressed: () => controller.setBuildMode(BuildMode.settlement),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BuildButton(
                  icon: Icons.location_city,
                  label: '都市',
                  enabled: controller.canBuildCity(),
                  isActive: controller.buildMode == BuildMode.city,
                  onPressed: () => controller.setBuildMode(BuildMode.city),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BuildButton(
                  icon: Icons.route,
                  label: '道路',
                  enabled: controller.canBuildRoad(),
                  isActive: controller.buildMode == BuildMode.road,
                  onPressed: () => controller.setBuildMode(BuildMode.road),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 銀行交易ボタン
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => BankTradeDialog(
                  player: controller.state!.currentPlayer,
                  onTrade: (give, receive) async {
                    await controller.executeBankTrade(give, receive);
                  },
                ),
              );
            },
            icon: const Icon(Icons.account_balance),
            label: const Text('銀行交易'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          // 発展カード購入ボタン
          ElevatedButton.icon(
            onPressed: controller.canPurchaseDevelopmentCard()
                ? () async {
                    final success = await controller.purchaseDevelopmentCard();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? '発展カードを購入しました'
                              : '発展カードを購入できませんでした'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                : null,
            icon: const Icon(Icons.card_giftcard),
            label: const Text('発展カード'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[700],
              foregroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          // 発展カード手札表示
          if (controller.currentPlayer != null &&
              controller.currentPlayer!.developmentCards.isNotEmpty)
            SizedBox(
              height: 100,
              child: CardHandWidget(
                player: controller.currentPlayer!,
                canPlayCards: controller.hasRolledDice,
                showFaceUp: true,
              ),
            ),

          const SizedBox(height: 8),

          // 交渉ボタン
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TradeScreen(),
                ),
              );
            },
            icon: const Icon(Icons.handshake),
            label: const Text('交渉'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          // デバッグボタン（開発用）
          OutlinedButton.icon(
            onPressed: () => controller.addDebugResources(),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('資源追加（デバッグ）'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
          ),

          const SizedBox(height: 8),

          // ターン終了ボタン
          ElevatedButton.icon(
            onPressed: controller.hasRolledDice
                ? () => controller.endTurn()
                : null,
            icon: const Icon(Icons.check_circle),
            label: const Text('ターン終了'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// BuildModeに応じてハイライトする頂点のIDを取得
  Set<String> _getHighlightedVertices(GameController controller) {
    if (controller.buildMode == BuildMode.settlement ||
        controller.buildMode == BuildMode.city) {
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
      final state = controller.state;
      if (state == null) return {};

      final currentPlayerId = controller.currentPlayer?.id;
      if (currentPlayerId == null) return {};

      // 初期配置フェーズの場合、集落に隣接する辺のみハイライト
      if (state.phase == GamePhase.setup) {
        return state.edges.where((edge) {
          if (edge.hasRoad) return false;

          // 辺の両端の頂点を確認
          final vertex1 = state.vertices.firstWhere(
            (v) => v.id == edge.vertex1Id,
            orElse: () => state.vertices.first,
          );
          final vertex2 = state.vertices.firstWhere(
            (v) => v.id == edge.vertex2Id,
            orElse: () => state.vertices.first,
          );

          // どちらかの頂点に自分の集落があるか確認
          return (vertex1.building != null && vertex1.building!.playerId == currentPlayerId) ||
              (vertex2.building != null && vertex2.building!.playerId == currentPlayerId);
        }).map((e) => e.id).toSet();
      }

      // 通常フェーズ: 空いている辺のみハイライト
      return state.edges
          .where((e) => !e.hasRoad)
          .map((e) => e.id)
          .toSet();
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
              leading: const Icon(Icons.save),
              title: const Text('保存'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('セーブ機能は実装予定です')),
                );
              },
            ),
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

/// 資源カード
class _ResourceCard extends StatelessWidget {
  final String name;
  final int count;

  const _ResourceCard({
    required this.name,
    required this.count,
  });

  Color _getResourceColor(String name) {
    switch (name) {
      case '木材':
        return Colors.green[700]!;
      case 'レンガ':
        return Colors.red[700]!;
      case '羊毛':
        return Colors.lightGreen[300]!;
      case '小麦':
        return Colors.amber[600]!;
      case '鉱石':
        return Colors.grey[700]!;
      default:
        return Colors.grey;
    }
  }

  IconData _getResourceIcon(String name) {
    switch (name) {
      case '木材':
        return Icons.park;
      case 'レンガ':
        return Icons.square;
      case '羊毛':
        return Icons.pets;
      case '小麦':
        return Icons.grass;
      case '鉱石':
        return Icons.landscape;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: _getResourceColor(name),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black26,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getResourceIcon(name),
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'x$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// 建設ボタン
class _BuildButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool isActive;
  final VoidCallback onPressed;

  const _BuildButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.green[700] : Colors.brown[700],
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[300],
        disabledForegroundColor: Colors.grey[600],
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
