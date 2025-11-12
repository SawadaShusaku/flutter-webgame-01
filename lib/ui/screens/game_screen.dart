import 'package:flutter/material.dart';
import 'package:test_web_app/ui/screens/normal_play_screen.dart';

/// ゲーム全体を管理する統合画面
/// 初期配置フェーズも通常プレイフェーズも同じビューを使用
/// フェーズの違いは処理ロジックのみで、ビューは共通
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 全フェーズで同じゲーム画面を使用
    // 初期配置も通常プレイも同じビューで表示
    return const NormalPlayScreen();
  }
}
