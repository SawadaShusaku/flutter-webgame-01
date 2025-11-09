import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:test_web_app/main.dart';

void main() {
  runApp(const WidgetbookApp());
}

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [
        WidgetbookCategory(
          name: 'Space Invaders',
          children: [
            WidgetbookComponent(
              name: 'Game',
              useCases: [
                WidgetbookUseCase(
                  name: 'Full Game',
                  builder: (context) => const InvadersGame(),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Components',
              useCases: [
                WidgetbookUseCase(
                  name: 'Player Ship',
                  builder: (context) => Center(
                    child: Container(
                      width: 400,
                      height: 400,
                      color: Colors.black,
                      child: Center(
                        child: CustomPaint(
                          size: const Size(40, 30),
                          painter: PlayerPainter(),
                        ),
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Enemy Invader',
                  builder: (context) => Center(
                    child: Container(
                      width: 400,
                      height: 400,
                      color: Colors.black,
                      child: Center(
                        child: CustomPaint(
                          size: const Size(30, 30),
                          painter: InvaderPainter(),
                        ),
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Stars Background',
                  builder: (context) => Center(
                    child: Container(
                      width: 400,
                      height: 600,
                      color: Colors.grey[900],
                      child: CustomPaint(
                        size: const Size(400, 600),
                        painter: StarsPainter(),
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Player Bullet',
                  builder: (context) => Center(
                    child: Container(
                      width: 400,
                      height: 400,
                      color: Colors.black,
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 10,
                          color: Colors.yellow,
                        ),
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Enemy Bullet',
                  builder: (context) => Center(
                    child: Container(
                      width: 400,
                      height: 400,
                      color: Colors.black,
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 10,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'UI Elements',
              useCases: [
                WidgetbookUseCase(
                  name: 'Score Display',
                  builder: (context) => Container(
                    color: Colors.black,
                    padding: const EdgeInsets.all(16.0),
                    child: const Text(
                      'SCORE: 1234',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Game Over Screen',
                  builder: (context) => Container(
                    color: Colors.black,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          border: Border.all(color: Colors.green, width: 3),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'GAME OVER',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Final Score: 1234',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Victory Screen',
                  builder: (context) => Container(
                    color: Colors.black,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          border: Border.all(color: Colors.green, width: 3),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'YOU WIN!',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Final Score: 1500',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Control Buttons',
                  builder: (context) => Container(
                    color: Colors.black,
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.all(20),
                          ),
                          child: const Icon(Icons.arrow_back, size: 30),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.all(20),
                            shape: const CircleBorder(),
                          ),
                          child: const Icon(Icons.rocket_launch, size: 30),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.all(20),
                          ),
                          child: const Icon(Icons.arrow_forward, size: 30),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
      addons: [
        DeviceFrameAddon(
          devices: [
            Devices.ios.iPhone13,
            Devices.android.samsungGalaxyS20,
            Devices.android.smallPhone,
          ],
        ),
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(
              name: 'Dark',
              data: ThemeData.dark(),
            ),
            WidgetbookTheme(
              name: 'Light',
              data: ThemeData.light(),
            ),
          ],
        ),
      ],
    );
  }
}
