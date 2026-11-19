import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'classic.dart';
import 'finish.dart';
import 'look.dart';
import 'model.dart';
import 'wheel.dart';

/// Teintes du Nano de 3e génération (2007) : façade en aluminium anodisé,
/// molette blanche (noire sur le noir).
enum NanoColor {
  argent('Argent', base: Color(0xFFBFC4C6), light: Color(0xFFDFE4E5), dark: Color(0xFF8F9599)),
  noir('Noir', base: Color(0xFF26282E), light: Color(0xFF3F4148), dark: Color(0xFF131418)),
  bleu('Bleu', base: Color(0xFF60B8B8), light: Color(0xFF9DD3D8), dark: Color(0xFF2F7B83)),
  vert('Vert', base: Color(0xFFA3D3A0), light: Color(0xFFCBE9C8), dark: Color(0xFF6C9F6E)),
  rouge('Rouge', base: Color(0xFF8E1031), light: Color(0xFFBA1A49), dark: Color(0xFF5C0920)),
  rose('Rose', base: Color(0xFFB83479), light: Color(0xFFE8529E), dark: Color(0xFF8A1F58));

  const NanoColor(this.displayName, {required this.base, required this.light, required this.dark});

  final String displayName;
  final Color base;
  final Color light;
  final Color dark;
}

/// Le Nano de 3e génération, le « gros » : presque carré (52 × 70 mm),
/// écran couleur 320×240, prise casque sous l'appareil.
class NanoModel extends DeviceModel {
  const NanoModel([this.color = NanoColor.argent]);

  final NanoColor color;

  // ≈ 6,67 unités par mm.
  static const Size _size = Size(349, 466);
  static const Rect _screen = Rect.fromLTWH(39, 34, 271, 203);
  static const double _radius = 30;

  @override
  String get id => 'nano-${color.name}';

  @override
  String get family => 'nano';

  @override
  String get label => 'Nano 3G';

  @override
  String get variantName => color.displayName;

  @override
  Color get swatch => color.base;

  @override
  Size get size => _size;

  @override
  double get cornerRadius => _radius;

  @override
  Rect get screen => _screen;

  /// En bas à droite (le verrou est en bas à gauche).
  @override
  double get jackX => 297;

  @override
  bool get jackOnTop => false;

  @override
  Offset get wheelCenter => const Offset(174.5, 346);

  @override
  WheelStyle get wheel => color == NanoColor.noir
      ? const WheelStyle(
          radius: 93,
          buttonRadius: 43,
          iconScale: 0.65,
          labelSize: 11,
          labelSpacing: 0.8,
          label: Color(0xFFE1E2E4),
          recess: Color(0xFF0B0C0E),
          ring: [Color(0xFF1D1E21), Color(0xFF191A1D), Color(0xFF141518)],
          edgeLight: 0.1,
          groove: Color(0xFF0E0F12),
          // Bouton en aluminium anodisé, comme le boîtier : plus clair que la molette.
          buttonUp: [Color(0xFF4E5055), Color(0xFF3F4146)],
          buttonDown: [Color(0xFF37393D), Color(0xFF424448)],
          buttonEdge: 0.1,
        )
      : WheelStyle(
          radius: 93,
          buttonRadius: 43,
          iconScale: 0.65,
          labelSize: 11,
          labelSpacing: 0.8,
          label: const Color(0xFF95A0AC),
          recess: Color.lerp(color.dark, Colors.black, 0.2)!,
          ring: const [Color(0xFFFFFFFF), Color(0xFFFBFDFD), Color(0xFFEFF2F3)],
          groove: Color.lerp(color.dark, Colors.black, 0.25)!,
          // Bouton central en aluminium de la couleur du boîtier, un peu
          // creusé : sombre en haut, clair en bas.
          buttonUp: [Color.lerp(color.base, color.dark, 0.3)!, Color.lerp(color.base, color.light, 0.8)!],
          buttonDown: [Color.lerp(color.base, color.dark, 0.6)!, Color.lerp(color.base, color.dark, 0.15)!],
          buttonEdge: 0.18,
        );

  /// Petit curseur en métal, en bas à gauche.
  @override
  HoldSwitch? get hold => const HoldSwitch(35, onTop: false, kind: HoldKind.metal);

  @override
  ScreenLook get look => const ClassicLook();

  @override
  CustomPainter get body => _NanoBodyPainter(color);

  @override
  CustomPainter? get glass => const _NanoGlassPainter();

  @override
  Size get windowSize => const Size(420, 620);

  @override
  bool operator ==(Object other) => other is NanoModel && other.color == color;

  @override
  int get hashCode => color.hashCode;
}

class _NanoBodyPainter extends CustomPainter {
  const _NanoBodyPainter(this.color);

  final NanoColor color;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(NanoModel._radius));

    paintFloatShadow(canvas, outer);

    // Aluminium anodisé jusqu'au bord : face unie sur toute la largeur de
    // l'écran ; au-delà, les flancs arrondis s'assombrissent à peine
    // jusqu'au bord (photos). Arrondi aussi en haut et en bas.
    final c = color;
    final all = Offset.zero & size;
    Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
    final l = NanoModel._screen.left / size.width, r = NanoModel._screen.right / size.width;
    double y(double px) => px / size.height;
    canvas.save();
    canvas.clipRRect(outer);
    canvas.drawRect(
      all,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, 0),
          [mix(c.base, c.dark, 0.4), mix(c.base, c.dark, 0.12), c.base, c.base, mix(c.base, c.dark, 0.12), mix(c.base, c.dark, 0.4)],
          [0, l * 0.5, l, r, 1 - (1 - r) * 0.5, 1],
        ),
    );
    // Tranches du haut et du bas : à peine plus sombres au bord, un filet
    // de lumière discret juste dessous en haut.
    canvas.drawRect(
      all,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height),
          [
            Colors.black.withValues(alpha: 0.15),
            Colors.black.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.05),
            Colors.black.withValues(alpha: 0.15),
          ],
          [0, y(5), y(11), y(30), 1 - y(22), 1 - y(11), 1],
        ),
    );
    // Plus clair vers le haut, d'où vient la lumière.
    canvas.drawRect(
      all,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), [
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0),
          Colors.black.withValues(alpha: 0.10),
        ], const [0, 0.5, 1]),
    );
    paintSatin(canvas, size, strength: color == NanoColor.noir ? 0.6 : 1);
    canvas.restore();

    // Arêtes : un filet de lumière en haut, plus sombre en bas.
    canvas.drawRRect(
      outer.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), [
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.06),
          Colors.black.withValues(alpha: 0.22),
        ], const [0, 0.5, 1]),
    );
    canvas.drawRRect(
      outer.deflate(0.25),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = Colors.black.withValues(alpha: 0.35),
    );

    // Écran sous une vitre noire.
    final frame = RRect.fromRectAndRadius(NanoModel._screen.inflate(7), const Radius.circular(5));
    canvas.drawRRect(frame.inflate(1), Paint()..color = Colors.black.withValues(alpha: 0.35));
    canvas.drawRRect(frame, Paint()..color = const Color(0xFF0F1012));
  }

  @override
  bool shouldRepaint(covariant _NanoBodyPainter old) => old.color != color;
}

/// Reflet sur la vitre de l'écran.
class _NanoGlassPainter extends CustomPainter {
  const _NanoGlassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = NanoModel._screen.inflate(7);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(r, const Radius.circular(5)));
    canvas.drawPath(
      Path()
        ..moveTo(r.left, r.top)
        ..lineTo(r.left + r.width * 0.7, r.top)
        ..lineTo(r.left, r.top + r.height * 0.6)
        ..close(),
      Paint()
        ..shader = ui.Gradient.linear(
          r.topLeft,
          r.topLeft + Offset(r.width * 0.35, r.height * 0.3),
          [Colors.white.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0.03)],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
