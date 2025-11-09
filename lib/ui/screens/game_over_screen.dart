import 'package:flutter/material.dart';
import 'package:test_web_app/models/player.dart';

/// ゲーム終了画面（MVP版）
class GameOverScreen extends StatelessWidget {
  final Player winner;

  const GameOverScreen({
    required this.winner,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.amber[700]!, Colors.orange[900]!],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events,
                size: 120,
                color: Colors.white,
              ),
              const SizedBox(height: 32),
              const Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${winner.name} の勝利！',
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${winner.victoryPoints} 勝利点',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
                child: const Text(
                  'メニューに戻る',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
