import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // ゲーム状態（プレースホルダー）
  final List<String> _gameLog = [
    'ゲームを開始しました',
    'プレイヤー1のターン',
    'サイコロを振りました: 6',
    '資源を獲得: 木材 x2',
  ];

  final Map<String, int> _hand = {
    '木材': 2,
    'レンガ': 1,
    '羊毛': 3,
    '小麦': 1,
    '鉱石': 0,
  };

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
            onPressed: () {
              _showGameMenu(context);
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 800;

          if (isWideScreen) {
            return _buildWideLayout();
          } else {
            return _buildNarrowLayout();
          }
        },
      ),
    );
  }

  // ワイドスクリーン用レイアウト（タブレット・デスクトップ）
  Widget _buildWideLayout() {
    return Row(
      children: [
        // メインゲームエリア（ボード + 手札 + アクション）
        Expanded(
          flex: 3,
          child: Column(
            children: [
              // ボードエリア
              Expanded(
                flex: 3,
                child: _buildBoardArea(),
              ),
              // 手札エリア
              SizedBox(
                height: 120,
                child: _buildHandArea(),
              ),
              // アクションボタンエリア
              SizedBox(
                height: 80,
                child: _buildActionArea(),
              ),
            ],
          ),
        ),
        // ログエリア（右側）
        SizedBox(
          width: 300,
          child: _buildLogArea(),
        ),
      ],
    );
  }

  // ナロースクリーン用レイアウト（スマートフォン）
  Widget _buildNarrowLayout() {
    return Column(
      children: [
        // ボードエリア
        Expanded(
          flex: 2,
          child: Stack(
            children: [
              _buildBoardArea(),
              // ログエリア（半透明オーバーレイ）
              Positioned(
                right: 8,
                top: 8,
                bottom: 8,
                width: 200,
                child: _buildLogArea(),
              ),
            ],
          ),
        ),
        // 手札エリア
        SizedBox(
          height: 100,
          child: _buildHandArea(),
        ),
        // アクションボタンエリア
        SizedBox(
          height: 70,
          child: _buildActionArea(),
        ),
      ],
    );
  }

  // ボードエリア
  Widget _buildBoardArea() {
    return Container(
      color: Colors.lightBlue[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 120,
              color: Colors.brown[300],
            ),
            const SizedBox(height: 16),
            Text(
              'ゲームボード',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '（実装予定）',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ログエリア
  Widget _buildLogArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.list, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'ゲームログ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _gameLog.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    _gameLog[index],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 手札エリア
  Widget _buildHandArea() {
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
              children: _hand.entries.map((entry) {
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

  // アクションボタンエリア
  Widget _buildActionArea() {
    return Container(
      color: Colors.brown[200],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.casino,
            label: 'サイコロ',
            onPressed: () {
              _showMessage('サイコロを振る機能は実装予定です');
            },
          ),
          _ActionButton(
            icon: Icons.build,
            label: '建設',
            onPressed: () {
              _showMessage('建設メニューは実装予定です');
            },
          ),
          _ActionButton(
            icon: Icons.swap_horiz,
            label: '交渉',
            onPressed: () {
              _showMessage('交渉機能は実装予定です');
            },
          ),
          _ActionButton(
            icon: Icons.check_circle,
            label: 'ターン終了',
            onPressed: () {
              _showMessage('ターン終了機能は実装予定です');
            },
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
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
                _showMessage('セーブ機能は実装予定です');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('ヘルプ'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('ヘルプは実装予定です');
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
