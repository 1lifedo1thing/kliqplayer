import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecteur/core/player.dart';
import 'package:lecteur/device/classic.dart';
import 'package:lecteur/device/device.dart';
import 'package:lecteur/device/nav.dart';
import 'package:lecteur/device/vintage.dart';

void main() {
  group('découpe de la fenêtre', () {
    test('l\'appareil et son câble : un seul contour, du câble étroit au boîtier large', () {
      final outline = outlineOf(const [
        Rect.fromLTRB(100, 200, 500, 900), // l'appareil
        Rect.fromLTRB(350, 0, 450, 200), // le câble, jusqu'en haut
      ]);
      expect(outline, const [
        Offset(450, 0), Offset(450, 200), Offset(500, 200), Offset(500, 900),
        Offset(100, 900), Offset(100, 200), Offset(350, 200), Offset(350, 0),
      ]);
    });

    test('des zones qui se chevauchent : le bord le plus à gauche et le plus à droite à chaque hauteur', () {
      final outline = outlineOf(const [Rect.fromLTRB(0, 0, 100, 100), Rect.fromLTRB(50, 50, 200, 150)]);
      expect(outline, const [
        Offset(100, 0), Offset(100, 50), Offset(200, 50), Offset(200, 100), Offset(200, 150),
        Offset(50, 150), Offset(50, 100), Offset(0, 100), Offset(0, 50), Offset(0, 0),
      ]);
    });

    test('rien à englober : pas de contour', () {
      expect(outlineOf(const [Rect.zero]), isEmpty);
    });
  });

  group('zone de travail', () {
    const first = (bounds: Rect.fromLTWH(0, 0, 1920, 1080), work: Rect.fromLTWH(0, 0, 1920, 1032));
    const second = (bounds: Rect.fromLTWH(1920, 0, 2560, 1440), work: Rect.fromLTWH(1920, 0, 2560, 1392));

    test('celle de l\'écran où est la fenêtre', () {
      expect(workAreaFor(const Rect.fromLTWH(700, 200, 400, 700), [first, second]), first.work);
      expect(workAreaFor(const Rect.fromLTWH(2500, 200, 400, 700), [first, second]), second.work);
    });

    test('barre des tâches masquée : une ligne de moins que l\'écran, pour ne pas passer pour du plein écran', () {
      const hidden = (bounds: Rect.fromLTWH(0, 0, 1920, 1080), work: Rect.fromLTWH(0, 0, 1920, 1080));
      expect(workAreaFor(const Rect.fromLTWH(0, 0, 400, 700), [hidden]), const Rect.fromLTWH(0, 0, 1920, 1079));
    });

    test('aucun écran connu : rien', () {
      expect(workAreaFor(const Rect.fromLTWH(0, 0, 400, 700), const []), isNull);
    });
  });

  group('rangée par Windows, ou seulement déplacée', () {
    const area = Rect.fromLTWH(0, 0, 1920, 1032);
    const fill = Size(1920, 1032);

    test('elle couvre la zone de travail (même agrandie, à quelques points près) : plein écran', () {
      expect(windowFit(area, area, fill), WindowFit.fills);
      expect(windowFit(area.inflate(8), area, fill), WindowFit.fills);
    });

    test('rangée à gauche, dans un quart ou dans une colonne : elle y reste', () {
      expect(windowFit(const Rect.fromLTWH(0, 0, 960, 1032), area, fill), WindowFit.docked);
      expect(windowFit(const Rect.fromLTWH(960, 516, 960, 516), area, fill), WindowFit.docked);
      expect(windowFit(const Rect.fromLTWH(1280, 0, 640, 1032), area, fill), WindowFit.docked);
    });

    test('rangée en haut ou en bas (toute la largeur, la moitié de la hauteur) : elle y reste', () {
      expect(windowFit(const Rect.fromLTWH(0, 0, 1920, 516), area, fill), WindowFit.docked);
    });

    test('passée sur un écran plus grand en gardant sa taille : on la recale', () {
      const bigger = Rect.fromLTWH(1920, 0, 2560, 1392);
      expect(windowFit(const Rect.fromLTWH(2240, 180, 1920, 1032), bigger, fill), WindowFit.refit);
    });

    test('sortie de sa zone à la souris, à sa taille de plein écran : on la recale', () {
      expect(windowFit(const Rect.fromLTWH(300, 120, 1920, 1032), area, fill), WindowFit.refit);
    });

    test('plus grande que l\'écran où elle arrive : on la recale', () {
      expect(windowFit(const Rect.fromLTWH(0, 0, 2560, 1392), area, const Size(2560, 1392)), WindowFit.refit);
    });
  });

  group('lâché après avoir été tenu', () {
    const window = Size(1400, 800);

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 200; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    testWidgets('l\'baladeur part d\'où on l\'a posé et glisse jusqu\'à sa place', (tester) async {
      tester.view
        ..physicalSize = window
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            type: MaterialType.transparency,
            child: DeviceStage(player: PlayerController.preview(), initial: const ClassicModel()),
          ),
        ),
      );
      await settle(tester);
      final home = tester.getRect(find.byType(DeviceBody));

      // Lâché 300 à droite et 120 plus bas que sa place, dans la même fenêtre.
      final dynamic stage = tester.state(find.byType(DeviceStage));
      stage.debugGlideHome(home.center + const Offset(300, 120), Offset.zero & window);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final start = tester.getRect(find.byType(DeviceBody));
      expect(start.center.dx, greaterThan(home.center.dx + 250));
      expect(start.center.dy, greaterThan(home.center.dy + 90));

      // En chemin : entre les deux.
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final midway = tester.getRect(find.byType(DeviceBody));
      expect(midway.center.dx, lessThan(start.center.dx));
      expect(midway.center.dx, greaterThan(home.center.dx));

      await settle(tester);
      final end = tester.getRect(find.byType(DeviceBody));
      expect(end.center.dx, closeTo(home.center.dx, 0.5));
      expect(end.center.dy, closeTo(home.center.dy, 0.5));
    });

    testWidgets('position libre : lâché, il reste là, entier dans la fenêtre ; position fixe, il revient à sa place', (tester) async {
      tester.view
        ..physicalSize = window
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      DeviceStage.debugDragInside = true;
      deviceFree.value = true;
      addTearDown(() {
        DeviceStage.debugDragInside = false;
        deviceFree.value = false;
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            type: MaterialType.transparency,
            child: DeviceStage(player: PlayerController.preview(), initial: const ClassicModel()),
          ),
        ),
      );
      await settle(tester);
      final home = tester.getRect(find.byType(DeviceBody));

      // (Peu de jeu en hauteur : le baladeur prend presque toute la fenêtre.)
      final gesture = await tester.startGesture(Offset(home.left + 12, home.center.dy));
      await gesture.moveBy(const Offset(-30, 5));
      await gesture.moveBy(const Offset(-220, 10));
      await tester.pump();
      final held = tester.getRect(find.byType(DeviceBody));
      await gesture.up();
      await settle(tester);
      expect(tester.getRect(find.byType(DeviceBody)).center, held.center, reason: 'il reste où on l\'a lâché');

      // Tiroir sorti : il ne retourne pas au milieu.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await settle(tester);
      final open = tester.getRect(find.byType(DeviceBody));
      expect(open.center.dx, closeTo(held.center.dx, 1), reason: 'la place ne manque pas à droite : il ne bouge pas');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await settle(tester);
      expect(tester.getRect(find.byType(DeviceBody)).center, held.center, reason: 'tiroir rentré : de retour où on l\'a lâché');

      // Lancé loin hors de la fenêtre : il y reste à moitié sorti, mais
      // garde au moins un quart de lui dedans.
      final out = await tester.startGesture(held.center - const Offset(60, 0));
      await out.moveBy(const Offset(30, 10));
      await out.moveBy(const Offset(4000, 0));
      await tester.pump();
      await out.up();
      await settle(tester);
      final kept = tester.getRect(find.byType(DeviceBody));
      expect(kept.right, greaterThan(window.width), reason: 'il peut dépasser du bord');
      expect(kept.left, lessThanOrEqualTo(window.width - kept.width / 4 + 0.5), reason: 'un quart reste visible');

      // Là, contre le bord droit, le tiroir n'a pas la place : le baladeur s'écarte juste assez, puis y retourne.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await settle(tester);
      final pushed = tester.getRect(find.byType(DeviceBody));
      expect(pushed.center.dx, lessThan(kept.center.dx));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await settle(tester);
      expect(tester.getRect(find.byType(DeviceBody)).center.dx, closeTo(kept.center.dx, 1));

      // Position fixe : il retourne à sa place.
      deviceFree.value = false;
      await settle(tester);
      final end = tester.getRect(find.byType(DeviceBody));
      expect(end.center.dx, closeTo(home.center.dx, 0.5));
      expect(end.center.dy, closeTo(home.center.dy, 0.5));
    });

    testWidgets('tenu, il suit le pointeur dans la fenêtre ; lâché, il revient à sa place', (tester) async {
      tester.view
        ..physicalSize = window
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      DeviceStage.debugDragInside = true;
      addTearDown(() => DeviceStage.debugDragInside = false);
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            type: MaterialType.transparency,
            child: DeviceStage(player: PlayerController.preview(), initial: const ClassicModel()),
          ),
        ),
      );
      await settle(tester);
      final home = tester.getRect(find.byType(DeviceBody));

      // Attrapé par le boîtier, à côté de l'écran.
      final gesture = await tester.startGesture(Offset(home.left + 12, home.center.dy));
      await gesture.moveBy(const Offset(30, 10));
      await gesture.moveBy(const Offset(220, 70));
      await tester.pump();
      // Il a suivi, en largeur comme en hauteur, et y reste tant qu'on le tient.
      final held = tester.getRect(find.byType(DeviceBody));
      expect(held.center.dx - home.center.dx, greaterThan(200));
      expect(held.center.dy - home.center.dy, greaterThan(60));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getRect(find.byType(DeviceBody)).center, held.center);

      await gesture.up();
      await settle(tester);
      final end = tester.getRect(find.byType(DeviceBody));
      expect(end.center.dx, closeTo(home.center.dx, 0.5));
      expect(end.center.dy, closeTo(home.center.dy, 0.5));
    });

    testWidgets('grande fenêtre : chaque modèle garde la taille qu\'il a dans sa propre fenêtre', (tester) async {
      tester.view
        ..physicalSize = window
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      DeviceStage.debugDragInside = true;
      addTearDown(() => DeviceStage.debugDragInside = false);
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            type: MaterialType.transparency,
            child: DeviceStage(player: PlayerController.preview(), initial: const FirstGenModel()),
          ),
        ),
      );
      await settle(tester);
      // 680 de haut dessiné ; dans sa fenêtre de 740 (148 pour le câble, 40
      // de marge), il en fait 552. Pareil ici, malgré toute la place.
      expect(tester.getRect(find.byType(DeviceBody)).height, closeTo(552, 0.5));
    });

    testWidgets('position libre : les poignées des coins du bas agrandissent et rapetissent le baladeur', (tester) async {
      tester.view
        ..physicalSize = window
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      DeviceStage.debugDragInside = true;
      deviceFree.value = true;
      addTearDown(() {
        DeviceStage.debugDragInside = false;
        deviceFree.value = false;
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            type: MaterialType.transparency,
            child: DeviceStage(player: PlayerController.preview(), initial: const ClassicModel()),
          ),
        ),
      );
      await settle(tester);
      final home = tester.getRect(find.byType(DeviceBody));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);

      // Le pointeur approche du coin du bas à droite : sa poignée sort ; on la tire en biais.
      final grip = home.bottomRight + const Offset(6, 6);
      await mouse.moveTo(grip - const Offset(20, 20));
      await settle(tester);
      await mouse.moveTo(grip);
      await tester.pump(const Duration(milliseconds: 200));
      await mouse.down(grip);
      await mouse.moveBy(const Offset(-30, -30));
      await mouse.moveBy(const Offset(-60, -60));
      await mouse.up();
      await settle(tester);
      final smaller = tester.getRect(find.byType(DeviceBody));
      expect(smaller.height, lessThan(home.height * 0.9), reason: 'tirée vers l\'intérieur : plus petit');
      expect(smaller.center.dx, closeTo(home.center.dx, 1), reason: 'autour de son centre');

      // Le coin du bas à gauche, tiré vers l'extérieur : il regrandit.
      final left = smaller.bottomLeft + const Offset(-6, 6);
      await mouse.moveTo(left + const Offset(20, -20));
      await settle(tester);
      await mouse.moveTo(left);
      await tester.pump(const Duration(milliseconds: 200));
      await mouse.down(left);
      await mouse.moveBy(const Offset(-20, 20));
      await mouse.moveBy(const Offset(-40, 40));
      await mouse.up();
      await settle(tester);
      expect(tester.getRect(find.byType(DeviceBody)).height, greaterThan(smaller.height * 1.1));
    });
  });
}
