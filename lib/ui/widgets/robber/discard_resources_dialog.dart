import 'package:flutter/material.dart';

// modelsパッケージからimport
import 'package:test_web_app/models/player.dart';
import 'package:test_web_app/models/enums.dart';

// utilsからimport
import 'package:test_web_app/utils/constants.dart';

/// 7が出たときに8枚以上持っているプレイヤーが資源を破棄するダイアログ
class DiscardResourcesDialog extends StatefulWidget {
  final Player player;
  final int discardCount; // 破棄する枚数
  final Function(Map<ResourceType, int>)? onConfirm;

  const DiscardResourcesDialog({
    super.key,
    required this.player,
    required this.discardCount,
    this.onConfirm,
  });

  @override
  State<DiscardResourcesDialog> createState() => _DiscardResourcesDialogState();

  /// ダイアログを表示
  static Future<Map<ResourceType, int>?> show(
    BuildContext context, {
    required Player player,
    required int discardCount,
  }) {
    return showDialog<Map<ResourceType, int>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DiscardResourcesDialog(
        player: player,
        discardCount: discardCount,
      ),
    );
  }
}

class _DiscardResourcesDialogState extends State<DiscardResourcesDialog> {
  late Map<ResourceType, int> _discardSelection;

  @override
  void initState() {
    super.initState();
    // 破棄選択を初期化
    _discardSelection = {
      ResourceType.lumber: 0,
      ResourceType.brick: 0,
      ResourceType.wool: 0,
      ResourceType.grain: 0,
      ResourceType.ore: 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final totalSelected = _getTotalSelected();
    final isValid = totalSelected == widget.discardCount;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildDiscardCounter(totalSelected, isValid),
            const SizedBox(height: 16),
            Expanded(child: _buildResourceSelection()),
            const SizedBox(height: 16),
            _buildActions(isValid),
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
          child: const Icon(
            Icons.warning,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '資源を破棄',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.player.name} - 資源を半分破棄してください',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 破棄カウンター
  Widget _buildDiscardCounter(int totalSelected, bool isValid) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? Colors.green.shade300 : Colors.orange.shade300,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.info_outline,
            color: isValid ? Colors.green.shade700 : Colors.orange.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '破棄数: ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$totalSelected',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isValid
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                    Text(
                      ' / ${widget.discardCount}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '現在: ${widget.player.totalResources}枚 → ${widget.player.totalResources - widget.discardCount}枚',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 資源選択
  Widget _buildResourceSelection() {
    return ListView(
      children: ResourceType.values.map((resource) {
        final currentCount = widget.player.resources[resource] ?? 0;
        final discardCount = _discardSelection[resource] ?? 0;
        final remainingCount = currentCount - discardCount;

        if (currentCount == 0) {
          return const SizedBox.shrink();
        }

        return _buildResourceRow(
          resource,
          currentCount,
          discardCount,
          remainingCount,
        );
      }).toList(),
    );
  }

  /// 資源行
  Widget _buildResourceRow(
    ResourceType resource,
    int currentCount,
    int discardCount,
    int remainingCount,
  ) {
    final resourceColor = GameColors.getResourceColor(resource);
    final resourceIcon = ResourceIcons.getIcon(resource);
    final resourceName = _getResourceName(resource);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: resourceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: resourceColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 資源情報
          Row(
            children: [
              Text(
                resourceIcon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  resourceName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$remainingCount / $currentCount',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 選択スライダー
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: resourceColor,
                    inactiveTrackColor: resourceColor.withOpacity(0.3),
                    thumbColor: resourceColor,
                    overlayColor: resourceColor.withOpacity(0.2),
                    valueIndicatorColor: resourceColor,
                  ),
                  child: Slider(
                    value: discardCount.toDouble(),
                    min: 0,
                    max: currentCount.toDouble(),
                    divisions: currentCount,
                    label: '$discardCount',
                    onChanged: (value) {
                      setState(() {
                        _discardSelection[resource] = value.toInt();
                      });
                    },
                  ),
                ),
              ),
              // 増減ボタン
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: discardCount > 0
                        ? () {
                            setState(() {
                              _discardSelection[resource] = discardCount - 1;
                            });
                          }
                        : null,
                    color: resourceColor,
                    iconSize: 28,
                  ),
                  Container(
                    width: 40,
                    height: 36,
                    decoration: BoxDecoration(
                      color: resourceColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$discardCount',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: discardCount < currentCount
                        ? () {
                            setState(() {
                              _discardSelection[resource] = discardCount + 1;
                            });
                          }
                        : null,
                    color: resourceColor,
                    iconSize: 28,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// アクションボタン
  Widget _buildActions(bool isValid) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: _resetSelection,
          icon: const Icon(Icons.refresh),
          label: const Text('リセット'),
        ),
        ElevatedButton(
          onPressed: isValid ? _onConfirm : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline),
              SizedBox(width: 8),
              Text('破棄'),
            ],
          ),
        ),
      ],
    );
  }

  /// 選択をリセット
  void _resetSelection() {
    setState(() {
      for (var resource in ResourceType.values) {
        _discardSelection[resource] = 0;
      }
    });
  }

  /// 確定時の処理
  void _onConfirm() {
    final totalSelected = _getTotalSelected();
    if (totalSelected != widget.discardCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.discardCount}枚の資源を選択してください'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (widget.onConfirm != null) {
      widget.onConfirm!(_discardSelection);
    }

    Navigator.of(context).pop(_discardSelection);
  }

  /// 選択された資源の合計
  int _getTotalSelected() {
    return _discardSelection.values.fold(0, (sum, count) => sum + count);
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
