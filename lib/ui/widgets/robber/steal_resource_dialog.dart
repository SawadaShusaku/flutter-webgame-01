import 'dart:math';
import 'package:flutter/material.dart';

// modelsパッケージからimport
import 'package:test_web_app/models/player.dart';
import 'package:test_web_app/models/enums.dart';

// utilsからimport
import 'package:test_web_app/utils/constants.dart';

/// 資源を奪うプレイヤーを選択するダイアログ
class StealResourceDialog extends StatefulWidget {
  final List<Player> availablePlayers;
  final Function(Player, ResourceType?)? onConfirm;

  const StealResourceDialog({
    super.key,
    required this.availablePlayers,
    this.onConfirm,
  });

  @override
  State<StealResourceDialog> createState() => _StealResourceDialogState();

  /// ダイアログを表示
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required List<Player> availablePlayers,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StealResourceDialog(
        availablePlayers: availablePlayers,
      ),
    );
  }
}

class _StealResourceDialogState extends State<StealResourceDialog> {
  Player? _selectedPlayer;
  ResourceType? _stolenResource;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (widget.availablePlayers.isEmpty)
              _buildNoPlayersMessage()
            else if (_stolenResource != null)
              _buildResultDisplay()
            else
              Expanded(child: _buildPlayerList()),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  /// ヘッダー
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '🦹',
            style: TextStyle(fontSize: 24),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '資源を奪う',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '資源を奪うプレイヤーを選択してください',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        if (!_isProcessing)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }

  /// プレイヤーがいない場合のメッセージ
  Widget _buildNoPlayersMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '盗賊を配置したヘックスに隣接する建設物を持つプレイヤーがいません。',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// プレイヤーリスト
  Widget _buildPlayerList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.availablePlayers.length,
        itemBuilder: (context, index) {
          final player = widget.availablePlayers[index];
          final isSelected = _selectedPlayer == player;

          return _buildPlayerTile(player, isSelected);
        },
      ),
    );
  }

  /// プレイヤータイル
  Widget _buildPlayerTile(Player player, bool isSelected) {
    final playerColor = GameColors.getPlayerColor(player.color);
    final totalResources = player.totalResources;

    return InkWell(
      onTap: _isProcessing
          ? null
          : () {
              setState(() {
                _selectedPlayer = player;
              });
            },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? playerColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? playerColor : Colors.transparent,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Row(
          children: [
            // プレイヤーカラー
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: playerColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // プレイヤー情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.layers,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '資源カード: $totalResources枚',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 選択インジケーター
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: playerColor,
                size: 28,
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey.shade400,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  /// 結果表示
  Widget _buildResultDisplay() {
    if (_selectedPlayer == null || _stolenResource == null) {
      return const SizedBox.shrink();
    }

    final resourceColor = GameColors.getResourceColor(_stolenResource!);
    final resourceIcon = ResourceIcons.getIcon(_stolenResource!);
    final playerColor = GameColors.getPlayerColor(_selectedPlayer!.color);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300, width: 2),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green.shade700,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            '${_selectedPlayer!.name} から',
            style: TextStyle(
              fontSize: 16,
              color: playerColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: resourceColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: resourceColor, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  resourceIcon,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 8),
                Text(
                  _getResourceName(_stolenResource!),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'を奪いました！',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// アクションボタン
  Widget _buildActions() {
    if (widget.availablePlayers.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      );
    }

    if (_stolenResource != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop({
                'player': _selectedPlayer,
                'resource': _stolenResource,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('確認'),
          ),
        ],
      );
    }

    final canConfirm = _selectedPlayer != null && !_isProcessing;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: canConfirm ? _onSteal : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🦹'),
                    SizedBox(width: 8),
                    Text('奪う'),
                  ],
                ),
        ),
      ],
    );
  }

  /// 資源を奪う処理
  void _onSteal() {
    if (_selectedPlayer == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // ランダムに資源を1枚奪う
    final availableResources = <ResourceType>[];
    for (var entry in _selectedPlayer!.resources.entries) {
      for (var i = 0; i < entry.value; i++) {
        availableResources.add(entry.key);
      }
    }

    if (availableResources.isNotEmpty) {
      final random = Random();
      final randomIndex = random.nextInt(availableResources.length);
      final stolenResource = availableResources[randomIndex];

      // アニメーション効果のため少し待つ
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _stolenResource = stolenResource;
          _isProcessing = false;
        });

        if (widget.onConfirm != null) {
          widget.onConfirm!(_selectedPlayer!, stolenResource);
        }
      });
    } else {
      // 資源がない場合
      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('選択したプレイヤーは資源を持っていません'),
        ),
      );
    }
  }

  /// 資源名を取得
  String _getResourceName(ResourceType resource) {
    switch (resource) {
      case ResourceType.lumber:
        return '木材';
      case ResourceType.brick:
        return 'レンガ';
      case ResourceType.wool:
        return '羊毛';
      case ResourceType.grain:
        return '小麦';
      case ResourceType.ore:
        return '鉱石';
    }
  }
}
