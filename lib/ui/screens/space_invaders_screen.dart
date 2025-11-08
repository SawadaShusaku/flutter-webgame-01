import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class SpaceInvadersScreen extends StatefulWidget {
  const SpaceInvadersScreen({super.key});

  @override
  State<SpaceInvadersScreen> createState() => _SpaceInvadersScreenState();
}

class _SpaceInvadersScreenState extends State<SpaceInvadersScreen> {
  // ゲーム設定
  static const double gameWidth = 400;
  static const double gameHeight = 600;

  // プレイヤー
  double playerX = gameWidth / 2;
  static const double playerY = gameHeight - 80;
  static const double playerWidth = 40;
  static const double playerHeight = 30;
  static const double playerSpeed = 5;

  // 敵
  List<Invader> invaders = [];
  double invaderDirection = 1;
  int invaderMoveDownCounter = 0;

  // 弾
  List<Bullet> playerBullets = [];
  List<Bullet> enemyBullets = [];

  // ゲーム状態
  int score = 0;
  bool gameOver = false;
  Timer? gameTimer;

  @override
  void initState() {
    super.initState();
    initGame();
    startGame();
  }

  void initGame() {
    // 敵を5x3のグリッドで配置
    invaders.clear();
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 5; col++) {
        invaders.add(Invader(
          x: 60 + col * 60.0,
          y: 50 + row * 50.0,
        ));
      }
    }

    playerX = gameWidth / 2;
    playerBullets.clear();
    enemyBullets.clear();
    score = 0;
    gameOver = false;
    invaderDirection = 1;
  }

  void startGame() {
    gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!gameOver) {
        updateGame();
      }
    });
  }

  void updateGame() {
    setState(() {
      // プレイヤーの弾を移動
      playerBullets.forEach((bullet) {
        bullet.y -= 8;
      });
      playerBullets.removeWhere((bullet) => bullet.y < 0);

      // 敵の弾を移動
      enemyBullets.forEach((bullet) {
        bullet.y += 5;
      });
      enemyBullets.removeWhere((bullet) => bullet.y > gameHeight);

      // 敵を移動
      invaderMoveDownCounter++;
      if (invaderMoveDownCounter > 20) {
        invaderMoveDownCounter = 0;

        bool shouldMoveDown = false;
        for (var invader in invaders) {
          invader.x += invaderDirection * 20;
          if (invader.x <= 0 || invader.x >= gameWidth - 40) {
            shouldMoveDown = true;
          }
        }

        if (shouldMoveDown) {
          invaderDirection *= -1;
          for (var invader in invaders) {
            invader.y += 30;
            invader.x += invaderDirection * 20;
          }
        }

        // ランダムに敵が弾を撃つ
        if (invaders.isNotEmpty && Random().nextDouble() < 0.3) {
          var shooter = invaders[Random().nextInt(invaders.length)];
          enemyBullets.add(Bullet(x: shooter.x + 15, y: shooter.y + 30));
        }
      }

      // 衝突判定：プレイヤーの弾と敵
      for (var bullet in List.from(playerBullets)) {
        for (var invader in List.from(invaders)) {
          if (checkCollision(
            bullet.x, bullet.y, 4, 10,
            invader.x, invader.y, 30, 30,
          )) {
            playerBullets.remove(bullet);
            invaders.remove(invader);
            score += 10;
            break;
          }
        }
      }

      // 衝突判定：敵の弾とプレイヤー
      for (var bullet in enemyBullets) {
        if (checkCollision(
          bullet.x, bullet.y, 4, 10,
          playerX - playerWidth / 2, playerY, playerWidth, playerHeight,
        )) {
          gameOver = true;
          gameTimer?.cancel();
          break;
        }
      }

      // 敵が下まで来たらゲームオーバー
      for (var invader in invaders) {
        if (invader.y > gameHeight - 100) {
          gameOver = true;
          gameTimer?.cancel();
          break;
        }
      }

      // 全ての敵を倒したら勝利
      if (invaders.isEmpty) {
        gameOver = true;
        gameTimer?.cancel();
      }
    });
  }

  bool checkCollision(double x1, double y1, double w1, double h1,
                      double x2, double y2, double w2, double h2) {
    return x1 < x2 + w2 &&
           x1 + w1 > x2 &&
           y1 < y2 + h2 &&
           y1 + h1 > y2;
  }

  void movePlayer(double direction) {
    setState(() {
      playerX += direction * playerSpeed;
      playerX = playerX.clamp(playerWidth / 2, gameWidth - playerWidth / 2);
    });
  }

  void shootBullet() {
    if (playerBullets.length < 3) {
      setState(() {
        playerBullets.add(Bullet(x: playerX, y: playerY));
      });
    }
  }

  void restartGame() {
    gameTimer?.cancel();
    initGame();
    startGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Space Invaders'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // スコア表示
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'SCORE: $score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // ゲーム画面
            Container(
              width: gameWidth,
              height: gameHeight,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Stack(
                children: [
                  // 星空背景
                  CustomPaint(
                    size: Size(gameWidth, gameHeight),
                    painter: StarsPainter(),
                  ),

                  // プレイヤー
                  Positioned(
                    left: playerX - playerWidth / 2,
                    top: playerY,
                    child: CustomPaint(
                      size: const Size(playerWidth, playerHeight),
                      painter: PlayerPainter(),
                    ),
                  ),

                  // 敵
                  ...invaders.map((invader) => Positioned(
                    left: invader.x,
                    top: invader.y,
                    child: CustomPaint(
                      size: const Size(30, 30),
                      painter: InvaderPainter(),
                    ),
                  )),

                  // プレイヤーの弾
                  ...playerBullets.map((bullet) => Positioned(
                    left: bullet.x - 2,
                    top: bullet.y,
                    child: Container(
                      width: 4,
                      height: 10,
                      color: Colors.yellow,
                    ),
                  )),

                  // 敵の弾
                  ...enemyBullets.map((bullet) => Positioned(
                    left: bullet.x - 2,
                    top: bullet.y,
                    child: Container(
                      width: 4,
                      height: 10,
                      color: Colors.red,
                    ),
                  )),

                  // ゲームオーバー表示
                  if (gameOver)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          border: Border.all(color: Colors.green, width: 3),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              invaders.isEmpty ? 'YOU WIN!' : 'GAME OVER',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Final Score: $score',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // コントロールボタン
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => movePlayer(-1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.all(20),
                    ),
                    child: const Icon(Icons.arrow_back, size: 30),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: shootBullet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.all(20),
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(Icons.rocket_launch, size: 30),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => movePlayer(1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.all(20),
                    ),
                    child: const Icon(Icons.arrow_forward, size: 30),
                  ),
                ],
              ),
            ),

            // リスタートボタン
            if (gameOver)
              ElevatedButton(
                onPressed: restartGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  'RESTART',
                  style: TextStyle(fontSize: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// データクラス
class Invader {
  double x;
  double y;

  Invader({required this.x, required this.y});
}

class Bullet {
  double x;
  double y;

  Bullet({required this.x, required this.y});
}

// カスタムペインター
class PlayerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    // 三角形の宇宙船
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class InvaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple
      ..style = PaintingStyle.fill;

    // シンプルな敵の形
    canvas.drawRect(
      Rect.fromLTWH(5, 10, 20, 15),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 15, 30, 10),
      paint,
    );

    // 目
    paint.color = Colors.red;
    canvas.drawCircle(const Offset(10, 17), 2, paint);
    canvas.drawCircle(const Offset(20, 17), 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final random = Random(42); // 固定シードで同じ星の配置
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
