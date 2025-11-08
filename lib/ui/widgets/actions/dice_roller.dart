import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../services/dice_service.dart';

/// サイコロを振るウィジェット
class DiceRoller extends StatefulWidget {
  final DiceService diceService;
  final VoidCallback? onRollComplete;
  final double size;

  const DiceRoller({
    super.key,
    required this.diceService,
    this.onRollComplete,
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

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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

    // DiceServiceの状態変更を監視
    widget.diceService.addListener(_onDiceServiceChanged);
  }

  @override
  void dispose() {
    widget.diceService.removeListener(_onDiceServiceChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onDiceServiceChanged() {
    if (widget.diceService.state == DiceState.rolling) {
      _animationController.forward(from: 0);
    } else if (widget.diceService.state == DiceState.finished) {
      if (widget.onRollComplete != null) {
        widget.onRollComplete!();
      }
    }
  }

  Future<void> _rollDice() async {
    if (widget.diceService.isRolling) return;

    try {
      await widget.diceService.rollDice();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.diceService,
      builder: (context, child) {
        final lastRoll = widget.diceService.lastRoll;
        final isRolling = widget.diceService.isRolling;

        return GestureDetector(
          onTap: isRolling ? null : _rollDice,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isRolling
                  ? Colors.orange.shade200
                  : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.shade700,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // サイコロアイコン
                Icon(
                  Icons.casino,
                  size: 32,
                  color: Colors.orange.shade900,
                ),
                const SizedBox(height: 8),

                // サイコロ表示
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDice(lastRoll?.die1 ?? 1, isRolling),
                    const SizedBox(width: 16),
                    _buildDice(lastRoll?.die2 ?? 1, isRolling),
                  ],
                ),
                const SizedBox(height: 12),

                // 合計値表示
                if (lastRoll != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: lastRoll.isSeven
                          ? Colors.red.shade700
                          : Colors.brown.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '合計: ${lastRoll.total}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // ボタン
                ElevatedButton.icon(
                  onPressed: isRolling ? null : _rollDice,
                  icon: Icon(isRolling ? Icons.hourglass_bottom : Icons.casino),
                  label: Text(isRolling ? '振っています...' : 'サイコロを振る'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildDice(int value, bool isRolling) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: isRolling ? _rotationAnimation.value : 0,
          child: Transform.scale(
            scale: isRolling ? _scaleAnimation.value : 1.0,
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
