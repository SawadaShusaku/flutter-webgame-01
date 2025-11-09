import 'package:flutter/material.dart';

// modelsパッケージからimport
import 'package:test_web_app/models/hex_tile.dart';
import 'package:test_web_app/models/enums.dart';

// utilsからimport
import 'package:test_web_app/utils/constants.dart';

/// 盗賊を配置するヘックスを選択するダイアログ
class RobberPlacementDialog extends StatefulWidget {
  final List<HexTile> hexTiles;
  final HexTile? currentRobberHex;
  final Function(HexTile)? onConfirm;

  const RobberPlacementDialog({
    super.key,
    required this.hexTiles,
    this.currentRobberHex,
    this.onConfirm,
  });

  @override
  State<RobberPlacementDialog> createState() => _RobberPlacementDialogState();

  /// ダイアログを表示
  static Future<HexTile?> show(
    BuildContext context, {
    required List<HexTile> hexTiles,
    HexTile? currentRobberHex,
  }) {
    return showDialog<HexTile>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RobberPlacementDialog(
        hexTiles: hexTiles,
        currentRobberHex: currentRobberHex,
      ),
    );
  }
}

class _RobberPlacementDialogState extends State<RobberPlacementDialog> {
  HexTile? _selectedHex;

  @override
  Widget build(BuildContext context) {
    // 現在の盗賊位置以外のヘックスをフィルタ
    final availableHexes = widget.hexTiles
        .where((hex) => hex != widget.currentRobberHex)
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(child: _buildHexList(availableHexes)),
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
            color: Colors.grey.shade800,
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
                '盗賊を移動',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '盗賊を配置するヘックスを選択してください',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// ヘックスリスト
  Widget _buildHexList(List<HexTile> hexes) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: hexes.length,
        itemBuilder: (context, index) {
          final hex = hexes[index];
          final isSelected = _selectedHex == hex;

          return _buildHexTile(hex, isSelected);
        },
      ),
    );
  }

  /// ヘックスタイル
  Widget _buildHexTile(HexTile hex, bool isSelected) {
    final terrainColor = GameColors.terrainColors[hex.terrain] ?? Colors.grey;
    final terrainIcon = ResourceIcons.terrainIcons[hex.terrain] ?? '❓';
    final terrainName = _getTerrainName(hex.terrain);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedHex = hex;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? terrainColor.withOpacity(0.3)
              : terrainColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? terrainColor : terrainColor.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Row(
          children: [
            // 地形アイコンと色
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: terrainColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  terrainIcon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 地形情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    terrainName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (hex.number != null)
                    Row(
                      children: [
                        const Text(
                          '数字: ',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: GameColors.getNumberColor(hex.number!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${hex.number}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${'・' * DiceProbabilities.getDots(hex.number!)})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      '砂漠（数字なし）',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            // 選択インジケーター
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: terrainColor,
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

  /// アクションボタン
  Widget _buildActions() {
    final canConfirm = _selectedHex != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: canConfirm ? _onConfirm : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade800,
            foregroundColor: Colors.white,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🦹'),
              SizedBox(width: 8),
              Text('配置'),
            ],
          ),
        ),
      ],
    );
  }

  /// 確定時の処理
  void _onConfirm() {
    if (_selectedHex == null) return;

    if (widget.onConfirm != null) {
      widget.onConfirm!(_selectedHex!);
    }

    Navigator.of(context).pop(_selectedHex);
  }

  /// 地形名を取得
  String _getTerrainName(TerrainType terrain) {
    switch (terrain) {
      case TerrainType.forest:
        return '森林';
      case TerrainType.hills:
        return '丘陵';
      case TerrainType.pasture:
        return '牧草地';
      case TerrainType.fields:
        return '畑';
      case TerrainType.mountains:
        return '山地';
      case TerrainType.desert:
        return '砂漠';
    }
  }
}
