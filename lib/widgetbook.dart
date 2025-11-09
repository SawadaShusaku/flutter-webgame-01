import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:test_web_app/models/enums.dart';
import 'package:test_web_app/models/hex_tile.dart';
import 'package:test_web_app/models/vertex.dart';
import 'package:test_web_app/models/edge.dart';
import 'package:test_web_app/ui/widgets/board/hex_tile_widget.dart';
import 'package:test_web_app/ui/widgets/board/vertex_widget.dart';
import 'package:test_web_app/ui/widgets/board/edge_widget.dart';
import 'package:test_web_app/ui/widgets/robber/robber_widget.dart';
import 'package:test_web_app/ui/widgets/log/game_log_widget.dart';
import 'package:test_web_app/ui/widgets/actions/dice_roller.dart';

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
          name: 'Catan Game',
          children: [
            WidgetbookComponent(
              name: 'Board Components',
              useCases: [
                WidgetbookUseCase(
                  name: 'Hex Tile - Forest',
                  builder: (context) => Center(
                    child: Container(
                      width: 400,
                      height: 400,
                      color: Colors.lightBlue[100],
                      child: Center(
                        child: HexTileWidget(
                          tile: HexTile(
                            id: 'hex_0',
                            terrain: TerrainType.forest,
                            number: 6,
                            position: const Offset(200, 200),
                            hasRobber: false,
                          ),
                          onTap: () {},
                        ),
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Hex Tile - Mountains',
                  builder: (context) => Center(
                    child: Container(
                      width: 400,
                      height: 400,
                      color: Colors.lightBlue[100],
                      child: Center(
                        child: HexTileWidget(
                          tile: HexTile(
                            id: 'hex_1',
                            terrain: TerrainType.mountains,
                            number: 8,
                            position: const Offset(200, 200),
                            hasRobber: false,
                          ),
                          onTap: () {},
                        ),
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Hex Tile - Desert with Robber',
                  builder: (context) => Center(
                    child: Container(
                      width: 400,
                      height: 400,
                      color: Colors.lightBlue[100],
                      child: Center(
                        child: HexTileWidget(
                          tile: HexTile(
                            id: 'hex_2',
                            terrain: TerrainType.desert,
                            number: null,
                            position: const Offset(200, 200),
                            hasRobber: true,
                          ),
                          onTap: () {},
                        ),
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Vertex - Empty',
                  builder: (context) => Center(
                    child: Container(
                      width: 400,
                      height: 400,
                      color: Colors.lightBlue[100],
                      child: Center(
                        child: VertexWidget(
                          vertex: Vertex(
                            id: 'v_0',
                            position: const Offset(200, 200),
                            adjacentHexIds: [],
                            adjacentEdgeIds: [],
                          ),
                          onTap: () {},
                        ),
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Vertex - Settlement',
                  builder: (context) => Center(
                    child: Container(
                      width: 400,
                      height: 400,
                      color: Colors.lightBlue[100],
                      child: Center(
                        child: VertexWidget(
                          vertex: Vertex(
                            id: 'v_1',
                            position: const Offset(200, 200),
                            adjacentHexIds: [],
                            adjacentEdgeIds: [],
                            buildingType: BuildingType.settlement,
                            playerId: 'player_0',
                          ),
                          onTap: () {},
                        ),
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Edge - Empty',
                  builder: (context) => Center(
                    child: Container(
                      width: 400,
                      height: 400,
                      color: Colors.lightBlue[100],
                      child: Center(
                        child: EdgeWidget(
                          edge: Edge(
                            id: 'e_0',
                            vertex1Id: 'v_0',
                            vertex2Id: 'v_1',
                          ),
                          vertex1Position: const Offset(150, 200),
                          vertex2Position: const Offset(250, 200),
                          onTap: () {},
                        ),
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Edge - Road',
                  builder: (context) => Center(
                    child: Container(
                      width: 400,
                      height: 400,
                      color: Colors.lightBlue[100],
                      child: Center(
                        child: EdgeWidget(
                          edge: Edge(
                            id: 'e_1',
                            vertex1Id: 'v_0',
                            vertex2Id: 'v_1',
                            playerId: 'player_0',
                          ),
                          vertex1Position: const Offset(150, 200),
                          vertex2Position: const Offset(250, 200),
                          onTap: () {},
                        ),
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Robber',
                  builder: (context) => Center(
                    child: Container(
                      width: 400,
                      height: 400,
                      color: Colors.lightBlue[100],
                      child: const Center(
                        child: RobberWidget(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Game UI',
              useCases: [
                WidgetbookUseCase(
                  name: 'Game Log',
                  builder: (context) => Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16.0),
                    child: const GameLogWidget(
                      entries: [],
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Dice Roller',
                  builder: (context) => Container(
                    color: Colors.brown[100],
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: DiceRoller(
                        onRoll: () {},
                        canRoll: true,
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
