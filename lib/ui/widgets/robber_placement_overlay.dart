import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_web_app/services/game_controller.dart';
import 'package:test_web_app/models/player.dart';

/// 盗賊配置オーバーレイ
///
/// 盗賊配置フェーズ時に表示される半透明オーバーレイ
/// ユーザーにタイルをタップするよう促す
class RobberPlacementOverlay extends StatelessWidget {
  const RobberPlacementOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, child) {
        return Stack(
          children: [
            // 半透明背景
            Container(
              color: Colors.black54,
            ),

            // 説明テキスト
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.brown[800],
                child: const Text(
                  '盗賊を配置するタイルをタップしてください',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // タイルのタップ検出はGameBoardWidget内のHexTileWidgetで行う
            // このオーバーレイは視覚的な案内のみ
          ],
        );
      },
    );
  }

  /// プレイヤー選択ダイアログを表示
  ///
  /// 盗賊を配置した後、隣接するプレイヤーから資源を奪う対象を選択
  static Future<Player?> showPlayerSelectionDialog(
    BuildContext context,
    List<Player> players,
  ) async {
    if (players.isEmpty) return null;

    // プレイヤーが1人だけなら自動選択
    if (players.length == 1) {
      return players.first;
    }

    // 複数いる場合はダイアログで選択
    return showDialog<Player>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('資源を奪う対象を選択'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: players.map((player) {
              return ListTile(
                title: Text(player.name),
                subtitle: Text('資源: ${player.totalResources}枚'),
                leading: CircleAvatar(
                  backgroundColor: _getPlayerColor(player.color),
                  child: Text(
                    player.name[0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop(player);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// プレイヤーカラーをColorに変換
  static Color _getPlayerColor(dynamic color) {
    final colorStr = color.toString().split('.').last;
    switch (colorStr) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }
}
