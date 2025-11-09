import 'package:flutter/material.dart';

/// ゲームログのエントリ種別
enum GameLogEventType {
  diceRoll,          // サイコロ
  resourceProduction, // 資源生産
  resourceDiscard,   // 資源破棄
  buildRoad,         // 道路建設
  buildSettlement,   // 集落建設
  buildCity,         // 都市建設
  buyCard,           // 発展カード購入
  useCard,           // 発展カード使用
  trade,             // 交易
  robberMove,        // 盗賊移動
  robberSteal,       // 盗賊による資源強奪
  victory,           // 勝利
  turnStart,         // ターン開始
  turnEnd,           // ターン終了
  system,            // システムメッセージ
}

/// ゲームログエントリ
class GameLogEntry {
  /// エントリID
  final String id;

  /// イベント種別
  final GameLogEventType eventType;

  /// メッセージ
  final String message;

  /// プレイヤーID（オプション）
  final String? playerId;

  /// タイムスタンプ
  final DateTime timestamp;

  /// 追加データ（オプション）
  final Map<String, dynamic>? data;

  GameLogEntry({
    required this.id,
    required this.eventType,
    required this.message,
    this.playerId,
    DateTime? timestamp,
    this.data,
  }) : timestamp = timestamp ?? DateTime.now();

  /// JSONから作成
  factory GameLogEntry.fromJson(Map<String, dynamic> json) {
    return GameLogEntry(
      id: json['id'] as String,
      eventType: GameLogEventType.values.firstWhere(
        (e) => e.toString() == json['eventType'],
        orElse: () => GameLogEventType.system,
      ),
      message: json['message'] as String,
      playerId: json['playerId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventType': eventType.toString(),
      'message': message,
      'playerId': playerId,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}

/// ゲームログウィジェット
///
/// 機能:
/// - イベントタイプごとのアイコン表示
/// - フィルタリング機能（イベント種別、プレイヤー）
/// - タイムスタンプ表示
/// - 自動スクロール
class GameLogWidget extends StatefulWidget {
  /// ログエントリのリスト
  final List<GameLogEntry> entries;

  /// 最大表示件数（デフォルト: 100）
  final int maxEntries;

  /// 自動スクロールを有効化（デフォルト: true）
  final bool autoScroll;

  /// フィルタリングを有効化（デフォルト: true）
  final bool enableFiltering;

  /// タイムスタンプを表示（デフォルト: true）
  final bool showTimestamp;

  const GameLogWidget({
    super.key,
    required this.entries,
    this.maxEntries = 100,
    this.autoScroll = true,
    this.enableFiltering = true,
    this.showTimestamp = true,
  });

  @override
  State<GameLogWidget> createState() => _GameLogWidgetState();
}

class _GameLogWidgetState extends State<GameLogWidget> {
  final ScrollController _scrollController = ScrollController();

  /// フィルター: 選択されたイベント種別
  final Set<GameLogEventType> _selectedEventTypes = {};

  /// フィルター: 選択されたプレイヤーID
  String? _selectedPlayerId;

  /// すべてのイベント種別を選択
  bool _allEventTypesSelected = true;

  @override
  void initState() {
    super.initState();
    // 初期状態ではすべてのイベント種別を選択
    _selectedEventTypes.addAll(GameLogEventType.values);
  }

  @override
  void didUpdateWidget(GameLogWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // エントリが追加された場合、自動スクロール
    if (widget.autoScroll && widget.entries.length > oldWidget.entries.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// フィルタリングされたエントリを取得
  List<GameLogEntry> get _filteredEntries {
    var filtered = widget.entries;

    // イベント種別でフィルタ
    if (!_allEventTypesSelected) {
      filtered = filtered.where((entry) {
        return _selectedEventTypes.contains(entry.eventType);
      }).toList();
    }

    // プレイヤーIDでフィルタ
    if (_selectedPlayerId != null) {
      filtered = filtered.where((entry) {
        return entry.playerId == _selectedPlayerId;
      }).toList();
    }

    // 最大件数を適用
    if (filtered.length > widget.maxEntries) {
      filtered = filtered.sublist(filtered.length - widget.maxEntries);
    }

    return filtered;
  }

  /// プレイヤーIDのリストを取得
  Set<String> get _playerIds {
    return widget.entries
        .where((entry) => entry.playerId != null)
        .map((entry) => entry.playerId!)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEntries = _filteredEntries;

    return Column(
      children: [
        // フィルターバー
        if (widget.enableFiltering) _buildFilterBar(),

        // ログリスト
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[700]!, width: 1),
            ),
            child: filteredEntries.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      return _buildLogEntry(filteredEntries[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  /// フィルターバー
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 20, color: Colors.white70),
          const SizedBox(width: 8),

          // イベント種別フィルター
          Expanded(
            child: _buildEventTypeFilter(),
          ),

          const SizedBox(width: 12),

          // プレイヤーフィルター
          _buildPlayerFilter(),

          const SizedBox(width: 8),

          // リセットボタン
          IconButton(
            icon: const Icon(Icons.clear, size: 20),
            color: Colors.white70,
            tooltip: 'Clear filters',
            onPressed: _resetFilters,
          ),
        ],
      ),
    );
  }

  /// イベント種別フィルター
  Widget _buildEventTypeFilter() {
    return PopupMenuButton<GameLogEventType>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Event Type',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(width: 4),
            Text(
              _allEventTypesSelected
                  ? 'All'
                  : '(${_selectedEventTypes.length})',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 20),
          ],
        ),
      ),
      itemBuilder: (context) {
        return [
          // 「すべて」オプション
          CheckedPopupMenuItem<GameLogEventType>(
            value: null,
            checked: _allEventTypesSelected,
            child: const Text('All Events'),
            onTap: () {
              setState(() {
                _allEventTypesSelected = true;
                _selectedEventTypes.clear();
                _selectedEventTypes.addAll(GameLogEventType.values);
              });
            },
          ),
          const PopupMenuDivider(),
          // 各イベント種別
          ...GameLogEventType.values.map((eventType) {
            return CheckedPopupMenuItem<GameLogEventType>(
              value: eventType,
              checked: _selectedEventTypes.contains(eventType),
              child: Row(
                children: [
                  _getEventIcon(eventType),
                  const SizedBox(width: 8),
                  Text(_getEventTypeName(eventType)),
                ],
              ),
              onTap: () {
                setState(() {
                  if (_selectedEventTypes.contains(eventType)) {
                    _selectedEventTypes.remove(eventType);
                  } else {
                    _selectedEventTypes.add(eventType);
                  }
                  _allEventTypesSelected =
                      _selectedEventTypes.length == GameLogEventType.values.length;
                });
              },
            );
          }),
        ];
      },
    );
  }

  /// プレイヤーフィルター
  Widget _buildPlayerFilter() {
    final playerIds = _playerIds;

    if (playerIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return DropdownButton<String?>(
      value: _selectedPlayerId,
      hint: const Text(
        'All Players',
        style: TextStyle(color: Colors.white70, fontSize: 14),
      ),
      dropdownColor: Colors.grey[800],
      style: const TextStyle(color: Colors.white, fontSize: 14),
      underline: Container(height: 1, color: Colors.grey[700]),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Players'),
        ),
        ...playerIds.map((playerId) {
          return DropdownMenuItem<String?>(
            value: playerId,
            child: Text('Player $playerId'),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedPlayerId = value;
        });
      },
    );
  }

  /// フィルターをリセット
  void _resetFilters() {
    setState(() {
      _allEventTypesSelected = true;
      _selectedEventTypes.clear();
      _selectedEventTypes.addAll(GameLogEventType.values);
      _selectedPlayerId = null;
    });
  }

  /// 空状態
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.white38),
          SizedBox(height: 16),
          Text(
            'No log entries',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// ログエントリ
  Widget _buildLogEntry(GameLogEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // アイコン
          _getEventIcon(entry.eventType),
          const SizedBox(width: 8),

          // メッセージ
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.message,
                  style: TextStyle(
                    color: _getEventColor(entry.eventType),
                    fontSize: 14,
                  ),
                ),
                if (widget.showTimestamp)
                  Text(
                    _formatTimestamp(entry.timestamp),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// イベント種別のアイコンを取得
  Icon _getEventIcon(GameLogEventType eventType) {
    IconData iconData;
    Color color;

    switch (eventType) {
      case GameLogEventType.diceRoll:
        iconData = Icons.casino;
        color = Colors.amber;
        break;
      case GameLogEventType.resourceProduction:
        iconData = Icons.agriculture;
        color = Colors.green;
        break;
      case GameLogEventType.resourceDiscard:
        iconData = Icons.delete;
        color = Colors.red;
        break;
      case GameLogEventType.buildRoad:
        iconData = Icons.route;
        color = Colors.brown;
        break;
      case GameLogEventType.buildSettlement:
        iconData = Icons.home;
        color = Colors.orange;
        break;
      case GameLogEventType.buildCity:
        iconData = Icons.location_city;
        color = Colors.blue;
        break;
      case GameLogEventType.buyCard:
        iconData = Icons.card_giftcard;
        color = Colors.purple;
        break;
      case GameLogEventType.useCard:
        iconData = Icons.stars;
        color = Colors.purple;
        break;
      case GameLogEventType.trade:
        iconData = Icons.swap_horiz;
        color = Colors.teal;
        break;
      case GameLogEventType.robberMove:
        iconData = Icons.moving;
        color = Colors.grey;
        break;
      case GameLogEventType.robberSteal:
        iconData = Icons.pan_tool;
        color = Colors.deepOrange;
        break;
      case GameLogEventType.victory:
        iconData = Icons.emoji_events;
        color = Colors.amber;
        break;
      case GameLogEventType.turnStart:
        iconData = Icons.play_arrow;
        color = Colors.lightBlue;
        break;
      case GameLogEventType.turnEnd:
        iconData = Icons.stop;
        color = Colors.blueGrey;
        break;
      case GameLogEventType.system:
        iconData = Icons.info;
        color = Colors.white70;
        break;
    }

    return Icon(iconData, size: 18, color: color);
  }

  /// イベント種別の色を取得
  Color _getEventColor(GameLogEventType eventType) {
    switch (eventType) {
      case GameLogEventType.victory:
        return Colors.amber;
      case GameLogEventType.resourceProduction:
        return Colors.green;
      case GameLogEventType.resourceDiscard:
      case GameLogEventType.robberSteal:
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  /// イベント種別の名前を取得
  String _getEventTypeName(GameLogEventType eventType) {
    switch (eventType) {
      case GameLogEventType.diceRoll:
        return 'Dice Roll';
      case GameLogEventType.resourceProduction:
        return 'Resource Production';
      case GameLogEventType.resourceDiscard:
        return 'Resource Discard';
      case GameLogEventType.buildRoad:
        return 'Build Road';
      case GameLogEventType.buildSettlement:
        return 'Build Settlement';
      case GameLogEventType.buildCity:
        return 'Build City';
      case GameLogEventType.buyCard:
        return 'Buy Card';
      case GameLogEventType.useCard:
        return 'Use Card';
      case GameLogEventType.trade:
        return 'Trade';
      case GameLogEventType.robberMove:
        return 'Robber Move';
      case GameLogEventType.robberSteal:
        return 'Robber Steal';
      case GameLogEventType.victory:
        return 'Victory';
      case GameLogEventType.turnStart:
        return 'Turn Start';
      case GameLogEventType.turnEnd:
        return 'Turn End';
      case GameLogEventType.system:
        return 'System';
    }
  }

  /// タイムスタンプをフォーマット
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
