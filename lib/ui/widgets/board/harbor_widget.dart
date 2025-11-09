import 'package:flutter/material.dart';
import '../../../models/trade.dart';
import '../../../models/enums.dart';
import '../../../utils/constants.dart';

/// 港のウィジェット
class HarborWidget extends StatelessWidget {
  final Harbor harbor;
  final Offset position;

  const HarborWidget({
    super.key,
    required this.harbor,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - 20,
      top: position.dy - 20,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getHarborColor(),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _getHarborLabel(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// 港のラベル
  String _getHarborLabel() {
    if (harbor.type == HarborType.generic) {
      return '3:1';
    } else {
      return '2:1';
    }
  }

  /// 港の色
  Color _getHarborColor() {
    switch (harbor.type) {
      case HarborType.generic:
        return Colors.grey.shade700;
      case HarborType.lumber:
        return GameColors.forest;
      case HarborType.brick:
        return GameColors.hills;
      case HarborType.wool:
        return GameColors.pasture;
      case HarborType.grain:
        return GameColors.fields;
      case HarborType.ore:
        return GameColors.mountains;
    }
  }
}

/// 港の詳細表示ウィジェット
class HarborDetailWidget extends StatelessWidget {
  final Harbor harbor;

  const HarborDetailWidget({
    super.key,
    required this.harbor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _getHarborColor(),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getHarborLabel(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getHarborName(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getHarborDescription(),
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getHarborLabel() {
    return harbor.type == HarborType.generic ? '3:1' : '2:1';
  }

  String _getHarborName() {
    switch (harbor.type) {
      case HarborType.generic:
        return '汎用港';
      case HarborType.lumber:
        return '木材港';
      case HarborType.brick:
        return 'レンガ港';
      case HarborType.wool:
        return '羊毛港';
      case HarborType.grain:
        return '小麦港';
      case HarborType.ore:
        return '鉱石港';
    }
  }

  String _getHarborDescription() {
    if (harbor.type == HarborType.generic) {
      return '任意の資源3枚を他の資源1枚と交換できます';
    } else {
      final resourceName = _getResourceName();
      return '$resourceName 2枚を他の資源1枚と交換できます';
    }
  }

  String _getResourceName() {
    switch (harbor.resourceType) {
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
      case null:
        return '';
    }
  }

  Color _getHarborColor() {
    switch (harbor.type) {
      case HarborType.generic:
        return Colors.grey.shade700;
      case HarborType.lumber:
        return GameColors.forest;
      case HarborType.brick:
        return GameColors.hills;
      case HarborType.wool:
        return GameColors.pasture;
      case HarborType.grain:
        return GameColors.fields;
      case HarborType.ore:
        return GameColors.mountains;
    }
  }
}
