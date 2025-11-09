import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_web_app/services/game_controller.dart';
import 'package:test_web_app/models/enums.dart';
import 'package:test_web_app/ui/widgets/phases/setup_phase_widget.dart';
import 'package:test_web_app/ui/widgets/phases/normal_play_phase_widget.dart';

/// ゲーム全体を管理する統合画面
/// GamePhaseに応じて表示を切り替える
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<GameController>(
        builder: (context, controller, child) {
          // ゲーム状態がない場合はローディング
          if (controller.state == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // フェーズごとにUIを切り替え
          switch (controller.currentPhase) {
            case GamePhase.setup:
              return const SetupPhaseWidget();

            case GamePhase.normalPlay:
              return const NormalPlayPhaseWidget();

            case GamePhase.robberPlacement:
              // TODO: Phase 4で実装
              return const Center(
                child: Text('盗賊配置フェーズ（未実装）'),
              );

            case GamePhase.resourceDiscard:
              // TODO: Phase 4で実装
              return const Center(
                child: Text('資源破棄フェーズ（未実装）'),
              );

            case GamePhase.trading:
              // TODO: Phase 5で実装
              return const Center(
                child: Text('交渉フェーズ（未実装）'),
              );

            case GamePhase.gameOver:
              // TODO: Phase 7で実装
              return const Center(
                child: Text('ゲーム終了'),
              );

            default:
              return const Center(
                child: Text('不明なフェーズ'),
              );
          }
        },
      ),
    );
  }
}
