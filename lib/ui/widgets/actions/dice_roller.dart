import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:test_web_app/models/game_state.dart';

/// サイコロを振るウィジェット
class DiceRoller extends StatefulWidget {
  final VoidCallback onRoll;
  final bool canRoll;
  final DiceRoll? lastRoll;
  final double size;

  const DiceRoller({
    super.key,
    required this.onRoll,
    required this.canRoll,
    this.lastRoll,
    this.size = 60.0,
  });

  @override
  State<DiceRoller> createState() => _DiceRollerState();
}

class _DiceRollerState extends State<DiceRoller>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  bool _isRolling = false;

  // アニメーション中に表示するランダムな目
  int _animatedDie1 = 1;
  int _animatedDie2 = 1;
  Timer? _randomChangeTimer;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // 回転アニメーション（0度から360度x3回転）
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: math.pi * 6, // 3回転
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // スケールアニメーション（少し拡大縮小）
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 0.9),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.1),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0),
        weight: 25,
      ),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _randomChangeTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRoll() async {
    setState(() => _isRolling = true);
    _animationController.forward(from: 0.0);

    // ランダムに目を変更するタイマーを開始（50msごと）
    _randomChangeTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _animatedDie1 = _random.nextInt(6) + 1;
          _animatedDie2 = _random.nextInt(6) + 1;
        });
      }
    });

    // アニメーション終了後にタイマーを停止
    await Future.delayed(const Duration(milliseconds: 500));
    _randomChangeTimer?.cancel();

    widget.onRoll();

    await Future.delayed(const Duration(milliseconds: 100));
    setState(() => _isRolling = false);
  }

  @override
  Widget build(BuildContext context) {
    final canRollNow = widget.canRoll && !_isRolling;
    final lastRoll = widget.lastRoll;

    // アニメーション中はランダムな目、それ以外は実際の出目を表示
    final die1Value = _isRolling ? _animatedDie1 : (lastRoll?.die1 ?? 1);
    final die2Value = _isRolling ? _animatedDie2 : (lastRoll?.die2 ?? 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // サイコロ表示
        if (lastRoll != null || _isRolling) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDice(die1Value),
              const SizedBox(width: 16),
              _buildDice(die2Value),
            ],
          ),
          const SizedBox(height: 8),
          // 合計値表示（アニメーション中は非表示）
          if (!_isRolling && lastRoll != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: lastRoll.total == 7
                    ? Colors.red.shade700
                    : Colors.orange.shade700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '合計: ${lastRoll.total}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
        const SizedBox(height: 16),
        // ボタン
        ElevatedButton.icon(
          onPressed: canRollNow ? _handleRoll : null,
          icon: Icon(_isRolling ? Icons.hourglass_bottom : Icons.casino),
          label: Text(_isRolling ? '振っています...' : 'サイコロを振る'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade400,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDice(int value) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _isRolling ? _rotationAnimation.value : 0,
          child: Transform.scale(
            scale: _isRolling ? _scaleAnimation.value : 1.0,
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black87,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: _buildDiceFace(value),
        ),
      ),
    );
  }

  Widget _buildDiceFace(int value) {
    return CustomPaint(
      size: Size(widget.size * 0.8, widget.size * 0.8),
      painter: DiceFacePainter(value),
    );
  }
}

/// サイコロの目を描画するペインター
class DiceFacePainter extends CustomPainter {
  final int value;

  DiceFacePainter(this.value) : assert(value >= 1 && value <= 6);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final dotRadius = size.width * 0.08;
    final positions = _getDotPositions(size);

    // 目の位置を取得して描画
    final dots = _getDotsForValue(value, positions);
    for (final pos in dots) {
      canvas.drawCircle(pos, dotRadius, paint);
    }
  }

  Map<String, Offset> _getDotPositions(Size size) {
    final w = size.width;
    final h = size.height;
    final margin = w * 0.2;

    return {
      'topLeft': Offset(margin, margin),
      'topRight': Offset(w - margin, margin),
      'middleLeft': Offset(margin, h / 2),
      'center': Offset(w / 2, h / 2),
      'middleRight': Offset(w - margin, h / 2),
      'bottomLeft': Offset(margin, h - margin),
      'bottomRight': Offset(w - margin, h - margin),
    };
  }

  List<Offset> _getDotsForValue(int value, Map<String, Offset> positions) {
    switch (value) {
      case 1:
        return [positions['center']!];
      case 2:
        return [positions['topLeft']!, positions['bottomRight']!];
      case 3:
        return [
          positions['topLeft']!,
          positions['center']!,
          positions['bottomRight']!
        ];
      case 4:
        return [
          positions['topLeft']!,
          positions['topRight']!,
          positions['bottomLeft']!,
          positions['bottomRight']!
        ];
      case 5:
        return [
          positions['topLeft']!,
          positions['topRight']!,
          positions['center']!,
          positions['bottomLeft']!,
          positions['bottomRight']!
        ];
      case 6:
        return [
          positions['topLeft']!,
          positions['topRight']!,
          positions['middleLeft']!,
          positions['middleRight']!,
          positions['bottomLeft']!,
          positions['bottomRight']!
        ];
      default:
        return [];
    }
  }

  @override
  bool shouldRepaint(covariant DiceFacePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
