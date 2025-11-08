import 'package:flutter/material.dart';

/// 盗賊ウィジェット
///
/// 盗賊アイコンを表示するウィジェット
/// - 現在盗賊がいるタイルに表示される
/// - タイル中央に配置
class RobberWidget extends StatelessWidget {
  /// 盗賊のサイズ
  final double size;

  /// タップ時のコールバック（盗賊移動時に使用）
  final VoidCallback? onTap;

  /// ハイライト表示するか（移動先候補として）
  final bool isHighlighted;

  const RobberWidget({
    super.key,
    this.size = 40.0,
    this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isHighlighted
              ? Colors.red.withOpacity(0.3)
              : Colors.transparent,
        ),
        child: CustomPaint(
          size: Size(size, size),
          painter: RobberPainter(isHighlighted: isHighlighted),
        ),
      ),
    );
  }
}

/// 盗賊を描画するカスタムペインター
class RobberPainter extends CustomPainter {
  final bool isHighlighted;

  RobberPainter({this.isHighlighted = false});

  @override
  void paint(Canvas canvas, Size size) {
    final robberSize = size.width;
    final center = Offset(size.width / 2, size.height / 2);

    // 盗賊のシルエット（黒い影）
    final bodyPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // 体部分（円）
    canvas.drawCircle(
      Offset(center.dx, center.dy + robberSize * 0.05),
      robberSize * 0.25,
      bodyPaint,
    );

    // 帽子部分（台形風）
    final hatPath = Path();
    hatPath.moveTo(
      center.dx - robberSize * 0.2,
      center.dy - robberSize * 0.1,
    );
    hatPath.lineTo(
      center.dx + robberSize * 0.2,
      center.dy - robberSize * 0.1,
    );
    hatPath.lineTo(
      center.dx + robberSize * 0.15,
      center.dy - robberSize * 0.35,
    );
    hatPath.lineTo(
      center.dx - robberSize * 0.15,
      center.dy - robberSize * 0.35,
    );
    hatPath.close();

    canvas.drawPath(hatPath, bodyPaint);

    // 盗賊のアウトライン（白い縁取り）
    final outlinePaint = Paint()
      ..color = isHighlighted ? Colors.red : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHighlighted ? 3.0 : 2.0;

    // 体のアウトライン
    canvas.drawCircle(
      Offset(center.dx, center.dy + robberSize * 0.05),
      robberSize * 0.25,
      outlinePaint,
    );

    // 帽子のアウトライン
    canvas.drawPath(hatPath, outlinePaint);

    // ハイライト表示時の追加エフェクト
    if (isHighlighted) {
      final glowPaint = Paint()
        ..color = Colors.red.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(center.dx, center.dy),
        robberSize * 0.45,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RobberPainter oldDelegate) {
    return oldDelegate.isHighlighted != isHighlighted;
  }
}

/// 盗賊アイコン（小サイズ）
///
/// UI上で盗賊を示すための小さなアイコン
/// - ゲームログやステータス表示に使用
class RobberIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const RobberIcon({
    super.key,
    this.size = 20.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: RobberIconPainter(color: color ?? Colors.black),
    );
  }
}

/// 盗賊アイコンを描画するペインター
class RobberIconPainter extends CustomPainter {
  final Color color;

  RobberIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final iconSize = size.width;

    // 簡略化された盗賊アイコン
    // 体
    canvas.drawCircle(
      Offset(center.dx, center.dy + iconSize * 0.1),
      iconSize * 0.3,
      paint,
    );

    // 帽子
    final hatPath = Path();
    hatPath.moveTo(center.dx - iconSize * 0.25, center.dy);
    hatPath.lineTo(center.dx + iconSize * 0.25, center.dy);
    hatPath.lineTo(center.dx + iconSize * 0.2, center.dy - iconSize * 0.3);
    hatPath.lineTo(center.dx - iconSize * 0.2, center.dy - iconSize * 0.3);
    hatPath.close();

    canvas.drawPath(hatPath, paint);
  }

  @override
  bool shouldRepaint(covariant RobberIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
