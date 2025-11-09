import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:provider/provider.dart';

import 'controllers/game_controller.dart';
import 'ui/screens/title_screen.dart';
import 'ui/screens/main_menu_screen.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/setup_screen.dart';
import 'ui/screens/normal_play_screen.dart';
import 'ui/screens/space_invaders_screen.dart';

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
          name: 'Screens',
          children: [
            WidgetbookComponent(
              name: 'Title Screen',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => const TitleScreen(),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Main Menu',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => const MainMenuScreen(),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Setup Screen',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => ChangeNotifierProvider(
                    create: (_) => GameController(),
                    child: const SetupScreen(),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Normal Play Screen',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => ChangeNotifierProvider(
                    create: (_) => GameController()..startNormalPlay(),
                    child: const NormalPlayScreen(),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Game Screen',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => const GameScreen(),
                ),
              ],
            ),
          ],
        ),
        WidgetbookCategory(
          name: 'Space Invaders',
          children: [
            WidgetbookComponent(
              name: 'Game',
              useCases: [
                WidgetbookUseCase(
                  name: 'Full Game',
                  builder: (context) => const SpaceInvadersScreen(),
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
