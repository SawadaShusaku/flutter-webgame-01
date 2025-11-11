import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_web_app/services/game_controller.dart';
import 'package:test_web_app/models/game_state.dart';
import 'package:test_web_app/models/enums.dart';
import 'package:test_web_app/ui/widgets/trade/resource_selector.dart';
import 'package:test_web_app/ui/widgets/trade/trade_offer_widget.dart';

/// 交易画面
class TradeScreen extends StatefulWidget {
  const TradeScreen({super.key});

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 日本語文字列 → ResourceType のマッピング
  static const Map<String, ResourceType> _resourceTypeMap = {
    '木材': ResourceType.lumber,
    'レンガ': ResourceType.brick,
    '羊毛': ResourceType.wool,
    '小麦': ResourceType.grain,
    '鉱石': ResourceType.ore,
  };

  // 銀行交易用
  final Map<String, int> _bankOffering = {};
  final Map<String, int> _bankRequesting = {};

  // プレイヤー間交易用
  final Map<String, int> _playerOffering = {};
  final Map<String, int> _playerRequesting = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeResourceMaps();
  }

  void _initializeResourceMaps() {
    final resourceTypes = ['木材', 'レンガ', '羊毛', '小麦', '鉱石'];
    for (var type in resourceTypes) {
      _bankOffering[type] = 0;
      _bankRequesting[type] = 0;
      _playerOffering[type] = 0;
      _playerRequesting[type] = 0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onBankOfferingChanged(String resourceType, int delta) {
    setState(() {
      _bankOffering[resourceType] = (_bankOffering[resourceType] ?? 0) + delta;
    });
  }

  void _onBankRequestingChanged(String resourceType, int delta) {
    setState(() {
      _bankRequesting[resourceType] =
          (_bankRequesting[resourceType] ?? 0) + delta;
    });
  }

  void _onPlayerOfferingChanged(String resourceType, int delta) {
    setState(() {
      _playerOffering[resourceType] =
          (_playerOffering[resourceType] ?? 0) + delta;
    });
  }

  void _onPlayerRequestingChanged(String resourceType, int delta) {
    setState(() {
      _playerRequesting[resourceType] =
          (_playerRequesting[resourceType] ?? 0) + delta;
    });
  }

  void _executeBankTrade(BuildContext context, GameController controller) {
    final totalOffering = _bankOffering.values.fold<int>(0, (sum, v) => sum + v);
    final totalRequesting = _bankRequesting.values.fold<int>(0, (sum, v) => sum + v);

    // バリデーション
    if (totalOffering == 0 || totalRequesting == 0) {
      _showError(context, '提供する資源と受け取る資源を選択してください');
      return;
    }

    if (totalOffering != 4 || totalRequesting != 1) {
      _showError(context, '銀行交易は4:1の交換です');
      return;
    }

    // 資源不足チェック
    for (var entry in _bankOffering.entries) {
      if (entry.value > 0) {
        final resourceType = _resourceTypeMap[entry.key];
        if (resourceType == null) continue;
        final available = controller.currentPlayer?.resources[resourceType] ?? 0;
        if (available < entry.value) {
          _showError(context, '${entry.key}が不足しています');
          return;
        }
      }
    }

    // 交易実行
    for (var entry in _bankOffering.entries) {
      if (entry.value > 0) {
        final resourceType = _resourceTypeMap[entry.key];
        if (resourceType == null) continue;
        controller.currentPlayer?.resources[resourceType] =
            (controller.currentPlayer?.resources[resourceType] ?? 0) - entry.value;
      }
    }

    for (var entry in _bankRequesting.entries) {
      if (entry.value > 0) {
        final resourceType = _resourceTypeMap[entry.key];
        if (resourceType == null) continue;
        controller.currentPlayer?.resources[resourceType] =
            (controller.currentPlayer?.resources[resourceType] ?? 0) + entry.value;
      }
    }

    controller.state?.logEvent(GameEvent(
      timestamp: DateTime.now(),
      playerId: controller.currentPlayer!.id,
      type: GameEventType.tradeExecuted,
      data: {'tradeType': 'bank'},
    ));
    controller.notifyListeners();

    // リセット
    _resetBankTrade();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('交易が完了しました'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _proposePlayerTrade(BuildContext context, GameController controller) {
    final totalOffering = _playerOffering.values.fold<int>(0, (sum, v) => sum + v);
    final totalRequesting = _playerRequesting.values.fold<int>(0, (sum, v) => sum + v);

    // バリデーション
    if (totalOffering == 0 && totalRequesting == 0) {
      _showError(context, '交易内容を設定してください');
      return;
    }

    // 資源不足チェック
    for (var entry in _playerOffering.entries) {
      if (entry.value > 0) {
        final resourceType = _resourceTypeMap[entry.key];
        if (resourceType == null) continue;
        final available = controller.currentPlayer?.resources[resourceType] ?? 0;
        if (available < entry.value) {
          _showError(context, '${entry.key}が不足しています');
          return;
        }
      }
    }

    // 提案を表示（実際のゲームではゲーム状態に保存し、他のプレイヤーに通知）
    _showTradeProposal(context, controller);
  }

  void _showTradeProposal(BuildContext context, GameController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('交易提案'),
        content: SingleChildScrollView(
          child: TradeOfferWidget(
            proposer: controller.currentPlayer!,
            offering: Map.from(_playerOffering),
            requesting: Map.from(_playerRequesting),
            isProposer: true,
            onCancel: () {
              Navigator.pop(context);
              _resetPlayerTrade();
            },
          ),
        ),
      ),
    );
  }

  void _resetBankTrade() {
    setState(() {
      for (var key in _bankOffering.keys) {
        _bankOffering[key] = 0;
      }
      for (var key in _bankRequesting.keys) {
        _bankRequesting[key] = 0;
      }
    });
  }

  void _resetPlayerTrade() {
    setState(() {
      for (var key in _playerOffering.keys) {
        _playerOffering[key] = 0;
      }
      for (var key in _playerRequesting.keys) {
        _playerRequesting[key] = 0;
      }
    });
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: Colors.lightBlue[50],
          appBar: AppBar(
            backgroundColor: Colors.brown[700],
            title: const Text('交易'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.account_balance),
                  text: '銀行交易',
                ),
                Tab(
                  icon: Icon(Icons.people),
                  text: 'プレイヤー間交易',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildBankTradeTab(controller),
              _buildPlayerTradeTab(controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBankTradeTab(GameController controller) {
    final totalOffering = _bankOffering.values.fold<int>(0, (sum, v) => sum + v);
    final totalRequesting = _bankRequesting.values.fold<int>(0, (sum, v) => sum + v);
    final canTrade = totalOffering == 4 && totalRequesting == 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 説明
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '銀行交易: 任意の資源4枚と、好きな資源1枚を交換できます',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 提供する資源
          Row(
            children: [
              const Text(
                '提供する資源',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalOffering / 4',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: totalOffering == 4 ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResourceSelector(
            currentResources: controller.currentPlayer?.resources ?? {},
            selectedResources: _bankOffering,
            onResourceChanged: _onBankOfferingChanged,
            showAvailable: true,
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // 受け取る資源
          Row(
            children: [
              const Text(
                '受け取る資源',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalRequesting / 1',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: totalRequesting == 1 ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResourceSelector(
            currentResources: {
              '木材': 99,
              'レンガ': 99,
              '羊毛': 99,
              '小麦': 99,
              '鉱石': 99,
            },
            selectedResources: _bankRequesting,
            onResourceChanged: _onBankRequestingChanged,
            showAvailable: false,
          ),

          const SizedBox(height: 24),

          // 実行ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canTrade
                  ? () => _executeBankTrade(context, controller)
                  : null,
              icon: const Icon(Icons.swap_horiz),
              label: const Text(
                '交易を実行',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey[300],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTradeTab(GameController controller) {
    final totalOffering = _playerOffering.values.fold<int>(0, (sum, v) => sum + v);
    final totalRequesting = _playerRequesting.values.fold<int>(0, (sum, v) => sum + v);
    final hasContent = totalOffering > 0 || totalRequesting > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 説明
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'プレイヤー間交易: 他のプレイヤーに交易を提案できます',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 提供する資源
          const Text(
            '提供する資源',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ResourceSelector(
            currentResources: controller.currentPlayer?.resources ?? {},
            selectedResources: _playerOffering,
            onResourceChanged: _onPlayerOfferingChanged,
            showAvailable: true,
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // 要求する資源
          const Text(
            '要求する資源',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ResourceSelector(
            currentResources: {
              '木材': 99,
              'レンガ': 99,
              '羊毛': 99,
              '小麦': 99,
              '鉱石': 99,
            },
            selectedResources: _playerRequesting,
            onResourceChanged: _onPlayerRequestingChanged,
            showAvailable: false,
          ),

          const SizedBox(height: 24),

          // 提案ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: hasContent
                  ? () => _proposePlayerTrade(context, controller)
                  : null,
              icon: const Icon(Icons.send),
              label: const Text(
                '交易を提案',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey[300],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
