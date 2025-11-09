import 'package:flutter/material.dart';
import '../../../models/game_state.dart';

/// 交易提案の表示カード
class TradeOfferWidget extends StatelessWidget {
  final Player proposer;
  final Map<String, int> offering;
  final Map<String, int> requesting;
  final bool isProposer;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  const TradeOfferWidget({
    super.key,
    required this.proposer,
    required this.offering,
    required this.requesting,
    required this.isProposer,
    this.onAccept,
    this.onReject,
    this.onCancel,
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
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 提案者情報
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: proposer.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  proposer.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '交易提案',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 提供する資源
            const Text(
              '提供:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            _buildResourceList(offering),

            const SizedBox(height: 16),

            // 交換アイコン
            Center(
              child: Icon(
                Icons.swap_vert,
                size: 32,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 16),

            // 要求する資源
            const Text(
              '要求:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            _buildResourceList(requesting),

            const SizedBox(height: 16),

            // ボタン
            if (isProposer)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close),
                  label: const Text('提案をキャンセル'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close),
                      label: const Text('拒否'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check),
                      label: const Text('承認'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceList(Map<String, int> resources) {
    final nonZeroResources = resources.entries
        .where((entry) => entry.value > 0)
        .toList();

    if (nonZeroResources.isEmpty) {
      return Text(
        'なし',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: nonZeroResources.map((entry) {
        return _ResourceChip(
          resourceType: entry.key,
          count: entry.value,
          color: _getResourceColor(entry.key),
          icon: _getResourceIcon(entry.key),
        );
      }).toList(),
    );
  }
}

class _ResourceChip extends StatelessWidget {
  final String resourceType;
  final int count;
  final Color color;
  final IconData icon;

  const _ResourceChip({
    required this.resourceType,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            resourceType,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'x$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
