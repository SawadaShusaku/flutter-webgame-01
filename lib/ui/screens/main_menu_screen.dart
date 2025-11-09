import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_web_app/ui/screens/game_screen.dart';
import 'package:test_web_app/ui/screens/space_invaders_screen.dart';
import 'package:test_web_app/ui/screens/setup_screen.dart';
import 'package:test_web_app/services/game_controller.dart';
import 'package:test_web_app/models/player_config.dart';
import 'package:test_web_app/models/enums.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.brown.shade900.withOpacity(0.3),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // タイトル
                  const Text(
                    'CATAN',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // メニューボタン
                  _MenuButton(
                    text: '新しいゲーム',
                    icon: Icons.add_circle_outline,
                    onPressed: () async {
                      // ゲームを開始
                      final controller = context.read<GameController>();

                      // デフォルト設定: プレイヤー1=人間、2-4=CPU
                      await controller.startNewGame(GameConfig(
                        playerCount: 4,
                        players: [
                          PlayerConfig(
                            name: 'プレイヤー1',
                            color: PlayerColor.red,
                            playerType: PlayerType.human,
                          ),
                          PlayerConfig(
                            name: 'CPU 1',
                            color: PlayerColor.blue,
                            playerType: PlayerType.cpu,
                          ),
                          PlayerConfig(
                            name: 'CPU 2',
                            color: PlayerColor.green,
                            playerType: PlayerType.cpu,
                          ),
                          PlayerConfig(
                            name: 'CPU 3',
                            color: PlayerColor.yellow,
                            playerType: PlayerType.cpu,
                          ),
                        ],
                      ));

                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const GameScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  _MenuButton(
                    text: 'ゲーム画面（デバッグ）',
                    icon: Icons.games,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const GameScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  _MenuButton(
                    text: 'Space Invaders',
                    icon: Icons.rocket_launch,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SpaceInvadersScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  _MenuButton(
                    text: 'ゲームを続ける',
                    icon: Icons.play_arrow,
                    onPressed: () {
                      _showComingSoonDialog(context, 'セーブデータ読み込み機能は今後実装予定です');
                    },
                  ),
                  const SizedBox(height: 16),

                  _MenuButton(
                    text: 'ルール説明',
                    icon: Icons.menu_book,
                    onPressed: () {
                      _showRulesDialog(context);
                    },
                  ),
                  const SizedBox(height: 16),

                  _MenuButton(
                    text: '設定',
                    icon: Icons.settings,
                    onPressed: () {
                      _showComingSoonDialog(context, '設定機能は今後実装予定です');
                    },
                  ),
                  const SizedBox(height: 16),

                  _MenuButton(
                    text: '終了',
                    icon: Icons.exit_to_app,
                    onPressed: () {
                      _showExitDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          '開発中',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'カタンのルール',
          style: TextStyle(color: Colors.white),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'カタンは資源を集めて開拓地や都市を建設するゲームです。\n\n'
            '【基本ルール】\n'
            '• サイコロを振って資源を獲得\n'
            '• 資源で道、開拓地、都市を建設\n'
            '• 他のプレイヤーと交渉・交換が可能\n'
            '• 最初に10点を獲得したプレイヤーが勝利\n\n'
            '【資源の種類】\n'
            '• 木材（森）\n'
            '• レンガ（丘陵）\n'
            '• 羊毛（牧草地）\n'
            '• 小麦（畑）\n'
            '• 鉱石（山）\n\n'
            '詳細なルールはゲーム中に確認できます。',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          '終了確認',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'ゲームを終了しますか？',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              // Flutterアプリの終了
              // Note: Webでは動作しません
              Navigator.of(context).pop();
              // SystemNavigator.pop(); // アプリ終了（必要に応じて）
            },
            child: const Text(
              '終了',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown.shade800,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.orange.shade700,
              width: 2,
            ),
          ),
          elevation: 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
