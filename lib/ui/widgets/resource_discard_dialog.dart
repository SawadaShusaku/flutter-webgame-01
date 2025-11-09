import 'package:flutter/material.dart';
import 'package:test_web_app/models/player.dart';
import 'package:test_web_app/models/enums.dart';

/// 資源破棄ダイアログ
/// 8枚以上所持しているプレイヤーが半分の資源を破棄するUI
class ResourceDiscardDialog extends StatefulWidget {
  final Player player;
  final int discardCount;
  final Function(Map<ResourceType, int>) onDiscard;

  const ResourceDiscardDialog({
    required this.player,
    required this.discardCount,
    required this.onDiscard,
    super.key,
  });

  @override
  State<ResourceDiscardDialog> createState() => _ResourceDiscardDialogState();
}

class _ResourceDiscardDialogState extends State<ResourceDiscardDialog> {
  final Map<ResourceType, int> _selectedResources = {
    ResourceType.lumber: 0,
    ResourceType.brick: 0,
    ResourceType.wool: 0,
    ResourceType.grain: 0,
    ResourceType.ore: 0,
  };

  int get _totalSelected => _selectedResources.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.player.name}: 資源を${widget.discardCount}枚破棄'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('選択: $_totalSelected / ${widget.discardCount}'),
          const SizedBox(height: 16),
          ...ResourceType.values.map((type) {
            final owned = widget.player.resources[type]!;
            final selected = _selectedResources[type]!;

            return Row(
              children: [
                Expanded(child: Text(_getResourceName(type))),
                Text('$selected / $owned'),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: selected > 0
                      ? () => setState(() => _selectedResources[type] = selected - 1)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: selected < owned
                      ? () => setState(() => _selectedResources[type] = selected + 1)
                      : null,
                ),
              ],
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _totalSelected == widget.discardCount
              ? () {
                  widget.onDiscard(_selectedResources);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('破棄'),
        ),
      ],
    );
  }

  String _getResourceName(ResourceType type) {
    switch (type) {
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
