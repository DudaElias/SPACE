import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:space/src/game/game.dart';
import 'package:space/src/game/shared/widgets/name_input_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final game = SpaceGame();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && game.router.canPop()) {
            game.router.pop();
          }
        },
        child: ValueListenableBuilder<Color>(
          valueListenable: game.barColor,
          builder: (context, barColor, child) => Scaffold(
            backgroundColor: barColor,
            body: child!,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: ClipRect(
                child: SizedBox(
                  width: 1280,
                  height: 800,
                  child: GameWidget(
                    game: game,
                    backgroundBuilder: (context) => Container(
                      color: const Color.fromARGB(255, 93, 101, 152),
                    ),
                    overlayBuilderMap: {
                      'nameInput': (context, game) {
                        final spaceGame = game as SpaceGame;
                        return NameInputOverlay(
                          title: 'Novo Jogador',
                          onConfirm: spaceGame.onNameInputConfirm,
                          onCancel: spaceGame.onNameInputCancel,
                        );
                      },
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
