import 'package:flutter/material.dart';
import 'package:test_web_app/models/player.dart';
import 'package:test_web_app/models/enums.dart';

class BankTradeDialog extends StatefulWidget {
  final Player player;
  final Function(ResourceType give, ResourceType receive) onTrade;

  const BankTradeDialog({
    required this.player,
    required this.onTrade,
    super.key,
  });

  @override
  State<BankTradeDialog> createState() => _BankTradeDialogState();
}

class _BankTradeDialogState extends State<BankTradeDialog> {
  ResourceType? _selectedGive;
  ResourceType? _selectedReceive;

  List<ResourceType> get _tradeableResources {
    return ResourceType.values.where((r) => (widget.player.resources[r] ?? 0) >= 4).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('銀行交易 (4:1)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('提供する資源（4枚）'),
          DropdownButton<ResourceType>(
            value: _selectedGive,
            hint: const Text('選択してください'),
            items: _tradeableResources.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text('${_getResourceName(type)} (${widget.player.resources[type]}枚)'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedGive = value);
            },
          ),

          const SizedBox(height: 24),

          const Icon(Icons.swap_vert, size: 40),

          const SizedBox(height: 24),

          const Text('受け取る資源（1枚）'),
          DropdownButton<ResourceType>(
            value: _selectedReceive,
            hint: const Text('選択してください'),
            items: ResourceType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getResourceName(type)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedReceive = value);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _selectedGive != null && _selectedReceive != null
              ? () {
                  widget.onTrade(_selectedGive!, _selectedReceive!);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('交易'),
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
