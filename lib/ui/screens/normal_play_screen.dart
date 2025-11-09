import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/game_controller.dart';
import '../../models/game_state.dart';
import '../widgets/game_board_widget.dart';
import '../widgets/game_log_widget.dart';

class NormalPlayScreen extends StatelessWidget {
  const NormalPlayScreen({super.key});

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
                      child: GameBoardWidget(),
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
                        child: GameLogWidget(logs: controller.gameLog),
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
              GameBoardWidget(),
              // ログ（オーバーレイ）
              Positioned(
                right: 8,
                top: 8,
                bottom: 8,
                width: 200,
                child: GameLogWidget(logs: controller.gameLog),
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
              color: currentPlayer.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            currentPlayer.name,
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
              'ターン ${state.turnNumber}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          // 勝利点
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '${currentPlayer.victoryPoints}点',
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
    final resources = controller.currentPlayer.resources;

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
                  name: entry.key,
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
          // サイコロボタン
          if (!controller.hasRolledDice)
            ElevatedButton.icon(
              onPressed: () => controller.rollDice(),
              icon: const Icon(Icons.casino),
              label: const Text('サイコロを振る'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
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
                  onPressed: () => controller.buildSettlement(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BuildButton(
                  icon: Icons.location_city,
                  label: '都市',
                  enabled: controller.canBuildCity(),
                  onPressed: () => controller.buildCity(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BuildButton(
                  icon: Icons.route,
                  label: '道路',
                  enabled: controller.canBuildRoad(),
                  onPressed: () => controller.buildRoad(),
                ),
              ),
            ],
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
  final VoidCallback onPressed;

  const _BuildButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.brown[700],
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
