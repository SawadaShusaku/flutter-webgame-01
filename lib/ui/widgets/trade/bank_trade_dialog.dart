import 'package:flutter/material.dart';

// modelsパッケージからimport
import 'package:test_web_app/models/player.dart';
import 'package:test_web_app/models/enums.dart';
import 'package:test_web_app/models/trade_offer.dart';

// utilsからimport
import 'package:test_web_app/utils/constants.dart';

/// 銀行取引のダイアログ
class BankTradeDialog extends StatefulWidget {
  final Player player;
  final Set<ResourceType>? harbor2to1; // 2:1で取引できる資源（専用港）
  final bool hasHarbor3to1; // 3:1で取引可能か（汎用港）
  final Function(BankTrade) onTradeCompleted;

  const BankTradeDialog({
    super.key,
    required this.player,
    this.harbor2to1,
    this.hasHarbor3to1 = false,
    required this.onTradeCompleted,
  });

  @override
  State<BankTradeDialog> createState() => _BankTradeDialogState();
}

class _BankTradeDialogState extends State<BankTradeDialog> {
  ResourceType? _givingResource;
  ResourceType? _receivingResource;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            _buildHeader(),
            const SizedBox(height: 20),

            // レート情報
            _buildRateInfo(),
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 渡す資源の選択
                    _buildResourceSelection(
                      title: '渡す資源',
                      selectedResource: _givingResource,
                      onSelect: (resource) {
                        setState(() {
                          _givingResource = resource;
                          // 同じ資源は受け取れない
                          if (_receivingResource == resource) {
                            _receivingResource = null;
                          }
                        });
                      },
                      showOnlyAvailable: true,
                    ),
                    const SizedBox(height: 20),

                    // 受け取る資源の選択
                    _buildResourceSelection(
                      title: '受け取る資源',
                      selectedResource: _receivingResource,
                      onSelect: (resource) {
                        setState(() {
                          _receivingResource = resource;
                        });
                      },
                      showOnlyAvailable: false,
                      excludeResource: _givingResource,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 取引概要
            if (_givingResource != null && _receivingResource != null) ...[
              _buildTradeSummary(),
              const SizedBox(height: 16),
            ],

            // アクションボタン
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
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.brown[600],
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: const Icon(
            Icons.account_balance,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '銀行取引',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '資源を交換する',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  /// レート情報
  Widget _buildRateInfo() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.blue[200]!,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                '利用可能な取引レート',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: [
              _buildRateChip('4:1', '通常レート', Colors.grey),
              if (widget.hasHarbor3to1)
                _buildRateChip('3:1', '汎用港', Colors.blue),
              if (widget.harbor2to1 != null && widget.harbor2to1!.isNotEmpty)
                _buildRateChip(
                  '2:1',
                  '専用港 (${_getHarborResourcesText()})',
                  Colors.green,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// レートチップ
  Widget _buildRateChip(String rate, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rate,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 港の資源テキストを取得
  String _getHarborResourcesText() {
    if (widget.harbor2to1 == null || widget.harbor2to1!.isEmpty) {
      return '';
    }
    return widget.harbor2to1!
        .map((r) => ResourceIcons.getIcon(r))
        .join(' ');
  }

  /// 資源選択
  Widget _buildResourceSelection({
    required String title,
    required ResourceType? selectedResource,
    required Function(ResourceType) onSelect,
    required bool showOnlyAvailable,
    ResourceType? excludeResource,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: ResourceType.values.map((resource) {
            if (excludeResource == resource) {
              return const SizedBox.shrink();
            }

            final available = widget.player.resources[resource] ?? 0;
            final isAvailable = !showOnlyAvailable || available > 0;
            final isSelected = selectedResource == resource;

            return _buildResourceCard(
              resource: resource,
              available: available,
              isSelected: isSelected,
              isEnabled: isAvailable,
              onTap: isAvailable ? () => onSelect(resource) : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 資源カード
  Widget _buildResourceCard({
    required ResourceType resource,
    required int available,
    required bool isSelected,
    required bool isEnabled,
    VoidCallback? onTap,
  }) {
    final icon = ResourceIcons.getIcon(resource);
    final color = GameColors.getResourceColor(resource);
    final name = _getResourceName(resource);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.3)
                : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: isSelected ? 2.5 : 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              if (available >= 0) ...[
                const SizedBox(height: 4),
                Text(
                  '×$available',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 取引概要
  Widget _buildTradeSummary() {
    final rate = _calculateRate();
    final requiredAmount = rate;
    final receivingAmount = 1;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[50]!, Colors.orange[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.orange[300]!,
          width: 2.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTradeItem(
            _givingResource!,
            requiredAmount,
            Colors.red,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Icon(
                  Icons.arrow_forward,
                  size: 28,
                  color: Colors.orange[700],
                ),
                Text(
                  '$rate:$receivingAmount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
              ],
            ),
          ),
          _buildTradeItem(
            _receivingResource!,
            receivingAmount,
            Colors.green,
          ),
        ],
      ),
    );
  }

  /// 取引アイテム
  Widget _buildTradeItem(ResourceType resource, int amount, Color color) {
    final icon = ResourceIcons.getIcon(resource);
    final resourceColor = GameColors.getResourceColor(resource);

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: resourceColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: resourceColor,
              width: 2.0,
            ),
          ),
          child: Center(
            child: Text(
              icon,
              style: const TextStyle(fontSize: 32),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '×$amount',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// アクションボタン
  Widget _buildActions() {
    final canTrade = _canExecuteTrade();
    final available = _givingResource != null
        ? (widget.player.resources[_givingResource!] ?? 0)
        : 0;
    final required = _calculateRate();

    return Column(
      children: [
        if (_givingResource != null && available < required)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '資源が不足しています（必要: $required、所持: $available）',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text('キャンセル'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: canTrade ? _executeTrade : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text('取引する'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 取引レートを計算
  int _calculateRate() {
    if (_givingResource == null) return 4;

    // 2:1 専用港
    if (widget.harbor2to1?.contains(_givingResource) ?? false) {
      return GameConstants.harborTradeRate2to1;
    }

    // 3:1 汎用港
    if (widget.hasHarbor3to1) {
      return GameConstants.harborTradeRate3to1;
    }

    // 4:1 通常レート
    return GameConstants.bankTradeRate;
  }

  /// 取引を実行できるか
  bool _canExecuteTrade() {
    if (_givingResource == null || _receivingResource == null) {
      return false;
    }

    final available = widget.player.resources[_givingResource!] ?? 0;
    final required = _calculateRate();

    return available >= required;
  }

  /// 取引を実行
  void _executeTrade() {
    if (!_canExecuteTrade()) return;

    final rate = _calculateRate();
    final trade = BankTrade(
      playerId: widget.player.id,
      giving: _givingResource!,
      givingAmount: rate,
      receiving: _receivingResource!,
      receivingAmount: 1,
    );

    widget.onTradeCompleted(trade);
    Navigator.of(context).pop();
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
