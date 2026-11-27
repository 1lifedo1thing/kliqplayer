import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart' hide RepeatMode;

import '../core/player.dart';
import 'finish.dart';
import 'look.dart';
import 'model.dart';
import 'nav.dart';
import 'wheel.dart';
import '../core/strings.dart';

/// Teintes des grands baladeur à écran couleur. La 5e génération est en
/// plastique brillant, [blanc] ou [noir] ; le Classic en aluminium anodisé,
/// [argent] ou [noir] (un gris anthracite).
enum ClassicColor {
  blanc('Blanc', front: [Color(0xFFFCFCFC), Color(0xFFF8F8F8), Color(0xFFF0F0EF)], swatch: Color(0xFFF8F8F8)),
  noir('Noir', front: [Color(0xFF17191B), Color(0xFF0A0D0F), Color(0xFF050708)], swatch: Color(0xFF1B1C1E)),
  argent('Argent', front: [Color(0xFFDCDCDD), Color(0xFFD0D0D1), Color(0xFFAEAEAF)], swatch: Color(0xFFD0D0D1)),

  /// Édition U2 de la 5e génération : façade noire, molette rouge.
  u2('U2', front: [Color(0xFF17191B), Color(0xFF0A0D0F), Color(0xFF050708)], swatch: Color(0xFFCC001F));

  const ClassicColor(this.displayName, {required this.front, required this.swatch});

  final String displayName;
  final List<Color> front;
  final Color swatch;
}

/// Le Classic (2007) : façade en aluminium anodisé sablé, aux bords
/// arrondis, écran couleur 320×240. Dessiné d'après une photo de face
/// (485 × 798 px) : les cotes ci-dessous sont celles de la photo, × [_k].
class ClassicModel extends DeviceModel {
  const ClassicModel([this.color = ClassicColor.argent]);

  final ClassicColor color;

  /// Unités de dessin par pixel de la photo.
  static const double _k = 412 / 485;

  static const Size _size = Size(485 * _k, 798 * _k);
  static const Rect _screen = Rect.fromLTWH(48 * _k, 49 * _k, 382 * _k, 286 * _k);

  /// Coins bien arrondis, en pixels de la photo.
  static const double _cornerRadius = 44;

  /// Dessinée avec le boîtier : seuls les appuis se voient.
  static const WheelStyle _wheel = WheelStyle(radius: 148 * _k, buttonRadius: 53 * _k, labels: false, onBody: true);

  bool get _dark => color == ClassicColor.noir;

  // « classic » tout court pour l'argent : les préférences déjà enregistrées
  // restent valables.
  @override
  String get id => _dark ? 'classic-noir' : 'classic';

  @override
  String get family => 'classic';

  @override
  String get label => 'Classic';

  @override
  String get variantName => _dark ? 'Noir' : 'Argent';

  @override
  Color get swatch => _dark ? const Color(0xFF4C4A4D) : ClassicColor.argent.swatch;

  @override
  Size get size => _size;

  @override
  double get cornerRadius => _cornerRadius * _k;

  @override
  Rect get screen => _screen;

  /// En haut à droite (le verrou est à gauche).
  @override
  double get jackX => 325;

  /// En haut à gauche : curseur métallique.
  @override
  HoldSwitch? get hold => const HoldSwitch(84, kind: HoldKind.metal);

  @override
  Offset get wheelCenter => const Offset(243 * _k, 560 * _k);

  @override
  WheelStyle get wheel => _wheel;

  @override
  ScreenLook get look => const ClassicLook();

  @override
  CustomPainter get body => _ClassicBodyPainter(look.background, dark: _dark);

  @override
  CustomPainter? get glass => const _ClassicGlassPainter();

  @override
  bool operator ==(Object other) => other is ClassicModel && other._dark == _dark;

  @override
  int get hashCode => _dark.hashCode;
}

/// La 5e génération « vidéo » (2005) : le format du Classic, mais une façade
/// en plastique brillant, un écran plus large au cadre noir et une molette
/// plus petite, grise.
class VideoModel extends DeviceModel {
  const VideoModel([this.color = ClassicColor.blanc]);

  final ClassicColor color;

  /// Unités de dessin par pixel de la photo (coin du liseré en 114, 93).
  static const double _k = 412 / 607;

  static const Size _size = Size(607 * _k, 1013 * _k);
  static const Rect _screen = Rect.fromLTWH(60 * _k, 54 * _k, 483 * _k, 358 * _k);

  /// Dessinée avec le boîtier : seuls les appuis se voient.
  static const WheelStyle _wheel = WheelStyle(radius: 190 * _k, buttonRadius: 68 * _k, labels: false, onBody: true);

  @override
  String get id => color == ClassicColor.blanc ? 'gen5' : 'gen5-${color.name}';

  @override
  String get family => 'gen5';

  @override
  String get label => '5e génération';

  @override
  String get variantName => color.displayName;

  @override
  Color get swatch => color.swatch;

  @override
  Size get size => _size;

  @override
  double get cornerRadius => 54 * _k;

  @override
  Rect get screen => _screen;

  /// En haut à droite (le verrou est à gauche).
  @override
  double get jackX => 325;

  @override
  HoldSwitch? get hold => const HoldSwitch(84);

  @override
  Offset get wheelCenter => const Offset(304 * _k, 704 * _k);

  @override
  WheelStyle get wheel => _wheel;

  @override
  ScreenLook get look => const ClassicLook(ui: ColorUi.video);

  @override
  CustomPainter get body => _VideoBodyPainter(look.background, color);

  @override
  CustomPainter? get glass => const _VideoGlassPainter();

  @override
  bool operator ==(Object other) => other is VideoModel && other.color == color;

  @override
  int get hashCode => color.hashCode;
}

// --- Boîtier du Classic --------------------------------------------------------
//
// Dessiné en pixels de la photo de référence (coin du boîtier en 347, 40),
// puis mis à l'échelle.

const _classicOrigin = Offset(347, 40);
const _classicBody = Rect.fromLTWH(347, 40, 485, 798);
const _classicLcd = Rect.fromLTWH(395, 89, 382, 286);

Paint _stroke(Color color, double width) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..color = color;

/// Aluminium sablé éclairé par la gauche, bords arrondis sans arête, écran
/// dans son cadre noir, molette et ses inscriptions, bouton central creusé.
class _ClassicBodyPainter extends CustomPainter {
  const _ClassicBodyPainter(this.lcd, {required this.dark});

  final Color lcd;

  /// Aluminium anthracite, molette noire.
  final bool dark;

  /// Rendu une fois en image par teinte : sans ça le moteur refait les flous
  /// et le grain à chaque image de l'écran.
  /// shortcut: image à 3 × la taille de base, un peu floue au-delà (plein écran sur un écran 5K) ; la rendre à la taille affichée si ça se voit.
  static final _images = <(Color, bool), ui.Image>{};
  static const _resolution = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    paintFloatShadow(
      canvas,
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(ClassicModel._cornerRadius * size.width / _classicBody.width)),
      drop: 26,
      blur: 30,
    );
    final image = _images[(lcd, dark)] ??= _render();
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  /// Grain fin de l'aluminium sablé : des points clairs et sombres au hasard.
  static void _grain(Canvas canvas, Rect area, Path clip, int count) {
    final random = math.Random(4);
    final light = <Offset>[], darkDots = <Offset>[];
    for (var i = 0; i < count; i++) {
      final p = Offset(area.left + random.nextDouble() * area.width, area.top + random.nextDouble() * area.height);
      (random.nextBool() ? light : darkDots).add(p);
    }
    canvas.save();
    canvas.clipPath(clip);
    final dot = Paint()
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;
    canvas.drawPoints(ui.PointMode.points, light, dot..color = Colors.white.withValues(alpha: 0.04));
    canvas.drawPoints(ui.PointMode.points, darkDots, dot..color = Colors.black.withValues(alpha: 0.045));
    canvas.restore();
  }

  ui.Image _render() {
    final width = (ClassicModel._size.width * _resolution).round();
    final height = (ClassicModel._size.height * _resolution).round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(width / _classicBody.width, height / _classicBody.height);
    canvas.translate(-_classicOrigin.dx, -_classicOrigin.dy);

    // Façade : plus claire à gauche, plus sombre vers la droite et en bas.
    final body = RRect.fromRectAndRadius(_classicBody, const Radius.circular(ClassicModel._cornerRadius));
    canvas.drawRRect(
      body,
      Paint()
        ..shader = ui.Gradient.linear(const Offset(347, 0), const Offset(832, 0), dark
            ? const [Color(0xFF46474A), Color(0xFF3E3F42), Color(0xFF36373A), Color(0xFF2F3033), Color(0xFF2A2B2E)]
            : const [Color(0xFFE0E2E3), Color(0xFFD6D8DA), Color(0xFFC6C8CA), Color(0xFFB7B9BC), Color(0xFFAEB0B3)],
            const [0, 0.12, 0.45, 0.73, 1]),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = ui.Gradient.linear(const Offset(0, 40), const Offset(0, 838), [
          for (final a in const [0.04, 0.0, 0.04, 0.16]) Colors.black.withValues(alpha: a),
        ], const [0, 0.12, 0.7, 1]),
    );
    _grain(canvas, _classicBody, Path()..addRRect(body), 60000);
    // Bords arrondis, sans arête : l'aluminium s'assombrit doucement vers le
    // bord, sauf à gauche où il prend la lumière.
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRRect(
      body,
      _stroke(const Color(0xFF26272A).withValues(alpha: 0.5), 16)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Le reflet s'efface vers le bas au lieu de buter contre le coin.
    const strip = Rect.fromLTWH(347, 40, 30, 798);
    canvas.saveLayer(strip.inflate(12), Paint());
    canvas.drawRect(
      strip,
      Paint()
        ..shader = ui.Gradient.linear(const Offset(347, 0), const Offset(377, 0), [
          for (final a in dark ? const [0.18, 0.1, 0.0] : const [0.7, 0.45, 0.0]) Colors.white.withValues(alpha: a),
        ], const [0, 0.55, 1])
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRect(
      strip.inflate(12),
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(const Offset(0, 40), const Offset(0, 838), [
          Colors.white.withValues(alpha: 0.6),
          Colors.white,
          Colors.white,
          Colors.white.withValues(alpha: 0),
        ], const [0, 0.08, 0.55, 0.9]),
    );
    canvas.restore();
    canvas.restore();
    canvas.drawRRect(body.deflate(0.5), _stroke(const Color(0xFF2F3032).withValues(alpha: 0.3), 1));
    // L'arrondi du bord accroche un filet de lumière en haut à gauche.
    canvas.drawRRect(
      body.deflate(2),
      _stroke(Colors.white, 1.6)
        ..shader = ui.Gradient.linear(const Offset(347, 40), const Offset(832, 838), [
          Colors.white.withValues(alpha: 0.55),
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0),
        ], const [0, 0.4, 0.6]),
    );

    // Écran dans son cadre noir, cerclé d'un fin liseré métallique.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(381, 73, 408, 312), const Radius.circular(7)),
      _stroke(const Color(0xFF2B2C2E).withValues(alpha: 0.35), 2.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(383, 75, 404, 308), const Radius.circular(6)),
      Paint()..color = const Color(0xFF0B0B0C),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(383.5, 75.5, 403, 307), const Radius.circular(5.5)),
      _stroke(const Color(0xFF9C9D99).withValues(alpha: 0.5), 1),
    );
    canvas.drawRect(_classicLcd, Paint()..color = lcd);

    // Molette, légèrement en creux.
    const c = Offset(590, 600);
    canvas.drawCircle(
      c.translate(1, 2),
      149.5,
      _stroke(const Color(0xFF2C2D2F).withValues(alpha: 0.35), 3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawCircle(
      c,
      148,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(590, 560), 190, dark
            ? const [Color(0xFF2A2B2D), Color(0xFF242527), Color(0xFF1E1F21)]
            : const [Color(0xFFFAFBFC), Color(0xFFF2F3F5), Color(0xFFE3E5E8)],
            const [0, 0.75, 1]),
    );
    canvas.drawCircle(c, 147.5, _stroke((dark ? Colors.black : const Color(0xFF8E9399)).withValues(alpha: 0.6), 1));
    final ink = dark ? const Color(0xFFE4E5E8) : const Color(0xFFA3AAB2);
    final menu = TextPainter(
      text: TextSpan(
        text: 'MENU',
        style: TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: ink),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    menu.paint(canvas, Offset(590 - menu.width / 2, 485 - menu.computeDistanceToActualBaseline(TextBaseline.alphabetic)));
    menu.dispose();
    canvas.drawPath(
      Path()
        // ⏮
        ..addRect(const Rect.fromLTWH(461.5, 595, 2.4, 12))
        ..addPolygon(const [Offset(464, 601), Offset(472, 595), Offset(472, 607)], true)
        ..addPolygon(const [Offset(472, 601), Offset(480, 595), Offset(480, 607)], true)
        // ⏭
        ..addPolygon(const [Offset(699, 595), Offset(707, 601), Offset(699, 607)], true)
        ..addPolygon(const [Offset(707, 595), Offset(715, 601), Offset(707, 607)], true)
        ..addRect(const Rect.fromLTWH(715, 595, 2.4, 12))
        // ⏯
        ..addPolygon(const [Offset(579, 719.5), Offset(589, 726), Offset(579, 732.5)], true)
        ..addRect(const Rect.fromLTWH(592.5, 720, 3, 12))
        ..addRect(const Rect.fromLTWH(598, 720, 3, 12)),
      Paint()..color = ink,
    );

    // Bouton central très légèrement concave : ombre sous le bord en haut à
    // gauche, lumière en bas à droite.
    canvas.drawCircle(
      c,
      54,
      _stroke(const Color(0xFF3A3B3D).withValues(alpha: 0.3), 2.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    final button = Rect.fromCircle(center: c, radius: 53);
    canvas.drawOval(
      button,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(575, 580), 80, dark
            ? const [Color(0xFF2E2F31), Color(0xFF252628)]
            : const [Color(0xFFCDCFD1), Color(0xFFBDBFC2)]),
    );
    if (!dark) _grain(canvas, button, Path()..addOval(button), 4000);
    canvas.drawOval(
      button,
      Paint()
        ..shader = ui.Gradient.linear(const Offset(552, 562), const Offset(628, 638), [
          Colors.black.withValues(alpha: 0.12),
          Colors.black.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.14),
        ], const [0, 0.45, 0.6, 1]),
    );
    canvas.drawCircle(c, 52.6, _stroke(const Color(0xFF6E6F6A).withValues(alpha: 0.5), 1));
    canvas.drawCircle(
      c,
      53.4,
      _stroke(Colors.white, 1.2)
        ..shader = ui.Gradient.linear(const Offset(560, 570), const Offset(620, 630), [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.45),
        ], const [0, 0.55, 1]),
    );

    final picture = recorder.endRecording();
    final image = picture.toImageSync(width, height);
    picture.dispose();
    return image;
  }

  @override
  bool shouldRepaint(covariant _ClassicBodyPainter old) => old.lcd != lcd || old.dark != dark;
}

/// Filet de lumière en haut de l'écran, par-dessus son contenu.
class _ClassicGlassPainter extends CustomPainter {
  const _ClassicGlassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final kx = size.width / _classicBody.width, ky = size.height / _classicBody.height;
    canvas.drawRect(
      Rect.fromLTWH((_classicLcd.left - _classicOrigin.dx) * kx, (_classicLcd.top - _classicOrigin.dy) * ky, _classicLcd.width * kx, 1.5 * ky),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// --- Boîtier de la 5e génération ----------------------------------------------
//
// Dessiné en pixels de la photo de référence (coin du liseré en 114, 93), puis
// mis à l'échelle.

const _videoOrigin = Offset(114, 93);
const _videoBody = Rect.fromLTWH(114, 93, 607, 1013);
const _videoFace = Rect.fromLTWH(121.5, 100.5, 592, 998);
const _videoLcd = Rect.fromLTWH(174, 147, 483, 358);

/// Liseré transparent arrondi (on voit le dos chromé à travers), façade en
/// plastique brillant, module de l'écran, molette et ses inscriptions, bouton
/// central.
class _VideoBodyPainter extends CustomPainter {
  const _VideoBodyPainter(this.lcd, this.color);

  final Color lcd;
  final ClassicColor color;

  /// Rendu une fois en image par teinte, comme le Classic.
  /// shortcut: image à 3 × la taille de base, un peu floue au-delà (plein écran sur un écran 5K) ; la rendre à la taille affichée si ça se voit.
  static final _images = <(Color, ClassicColor), ui.Image>{};
  static const _resolution = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(54 * size.width / _videoBody.width));
    // Le liseré est transparent : l'ombre portée ne passe pas dessous.
    canvas.save();
    canvas.clipPath(Path()
      ..fillType = PathFillType.evenOdd
      ..addRect((Offset.zero & size).inflate(200))
      ..addRRect(outer));
    paintFloatShadow(canvas, outer, drop: 26, blur: 30);
    canvas.restore();
    final image = _images[(lcd, color)] ??= _render();
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  ui.Image _render() {
    final white = color == ClassicColor.blanc;
    final width = (VideoModel._size.width * _resolution).round();
    final height = (VideoModel._size.height * _resolution).round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(width / _videoBody.width, height / _videoBody.height);
    canvas.translate(-_videoOrigin.dx, -_videoOrigin.dy);

    // Liseré transparent : un filet de lumière dehors, un autre très léger dedans.
    final rim = RRect.fromRectAndRadius(_videoBody, const Radius.circular(54));
    canvas.drawRRect(
      rim,
      Paint()
        ..shader = ui.Gradient.linear(const Offset(0, 93), const Offset(0, 1106), [
          const Color(0xFFA0A0A0).withValues(alpha: 0.6),
          const Color(0xFF7A7A7A).withValues(alpha: 0.5),
          const Color(0xFF8C8C8C).withValues(alpha: 0.58),
        ], const [0, 0.5, 1]),
    );
    canvas.drawRRect(rim.deflate(0.5), _stroke(const Color(0xFFE2E2E2).withValues(alpha: 0.7), 1.2));
    canvas.drawRRect(rim.deflate(2), _stroke(Colors.white.withValues(alpha: 0.18), 1));
    canvas.drawRRect(rim.deflate(5), _stroke(const Color(0xFF202020).withValues(alpha: 0.6), 1.5));

    // Façade : un peu plus claire en haut (reflet du plafond), plus sombre en bas.
    final face = RRect.fromRectAndRadius(_videoFace, const Radius.circular(47.5));
    canvas.drawRRect(
      face,
      Paint()
        ..shader = ui.Gradient.linear(const Offset(0, 98), const Offset(0, 1101), white
            ? const [Color(0xFFFAFAF9), Color(0xFFF4F4F3), Color(0xFFEFEFEE), Color(0xFFE4E5E4)]
            : const [Color(0xFF2B2B2B), Color(0xFF1D1D1D), Color(0xFF171717), Color(0xFF0E0E0E)],
            const [0, 0.04, 0.5, 1]),
    );
    canvas.drawRRect(
      face,
      Paint()
        ..shader = ui.Gradient.linear(const Offset(121.5, 0), const Offset(713.5, 0), white
            ? [Colors.white.withValues(alpha: 0.3), Colors.white.withValues(alpha: 0), Colors.black.withValues(alpha: 0), Colors.black.withValues(alpha: 0.04)]
            : [Colors.white.withValues(alpha: 0.035), Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.04)],
            const [0, 0.15, 0.85, 1]),
    );
    canvas.drawRRect(
      face.deflate(0.5),
      _stroke((white ? const Color(0xFF8E9194) : Colors.black).withValues(alpha: 0.6), 1),
    );
    // Bord bombé : un reflet doux (une ombre sur le blanc) suit l'arrondi.
    canvas.save();
    canvas.clipRRect(face);
    canvas.drawRRect(
      face,
      _stroke(white ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.1), 10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.restore();

    // Écran : le module gris foncé se voit autour, sous la façade.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(162, 135, 507, 381), const Radius.circular(9)),
      Paint()..color = const Color(0xFF3C3C3C),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(164, 137, 503, 377), const Radius.circular(8)),
      _stroke(const Color(0xFF4C4C4C), 2),
    );
    canvas.drawRect(_videoLcd, Paint()..color = lcd);

    // Molette : grise sur le blanc, noire mate sur le noir, rouge sur l'U2.
    const c = Offset(418, 797);
    canvas.drawCircle(
      c,
      191,
      _stroke(Colors.black.withValues(alpha: white ? 0.15 : 0.5), 3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawCircle(
      c,
      190,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(418, 740), 230, switch (color) {
          ClassicColor.u2 => const [Color(0xFFD8002A), Color(0xFFB0001A)],
          ClassicColor.blanc => const [Color(0xFFCBCED1), Color(0xFFBDC0C4)],
          _ => const [Color(0xFF191919), Color(0xFF111111)],
        }),
    );
    canvas.drawCircle(
      c,
      189,
      _stroke(switch (color) {
        ClassicColor.u2 => const Color(0xFF6E0010).withValues(alpha: 0.7),
        ClassicColor.blanc => const Color(0xFFA9ACB0).withValues(alpha: 0.7),
        _ => const Color(0xFF2C2C2C).withValues(alpha: 0.7),
      }, 1.4),
    );
    final ink = switch (color) {
      ClassicColor.u2 => const Color(0xFFF7ECEC),
      ClassicColor.blanc => const Color(0xFFFBFBFC),
      _ => const Color(0xFFC9C7C2),
    };
    final menu = TextPainter(
      text: TextSpan(
        text: 'MENU',
        style: TextStyle(fontFamily: _font, fontSize: 23, fontWeight: FontWeight.w700, letterSpacing: 1, color: ink),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    menu.paint(canvas, Offset(418 - menu.width / 2, 644 - menu.computeDistanceToActualBaseline(TextBaseline.alphabetic)));
    menu.dispose();
    final inkPaint = Paint()..color = ink;
    void icon(Offset at, Path path) {
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.scale(1.12);
      canvas.drawPath(path, inkPaint);
      canvas.restore();
    }

    icon(const Offset(268, 798), Path()
      ..addRect(const Rect.fromLTWH(-14, -8.5, 3.4, 17))
      ..addPolygon(const [Offset(-10.6, 0), Offset(0, -8.5), Offset(0, 8.5)], true)
      ..addPolygon(const [Offset(0, 0), Offset(10.6, -8.5), Offset(10.6, 8.5)], true));
    icon(const Offset(570, 797), Path()
      ..addPolygon(const [Offset(-10.6, -8.5), Offset(0, 0), Offset(-10.6, 8.5)], true)
      ..addPolygon(const [Offset(0, -8.5), Offset(10.6, 0), Offset(0, 8.5)], true)
      ..addRect(const Rect.fromLTWH(10.6, -8.5, 3.4, 17)));
    icon(const Offset(422, 958), Path()
      ..addPolygon(const [Offset(-16, -9), Offset(-2, 0), Offset(-16, 9)], true)
      ..addRect(const Rect.fromLTWH(2.5, -8.5, 4.2, 17))
      ..addRect(const Rect.fromLTWH(10, -8.5, 4.2, 17)));

    // Bouton central, même plastique que la façade, cerclé d'une fine rainure.
    const center = Offset(420, 797);
    canvas.drawCircle(center, 68, Paint()..color = white ? const Color(0xFFF7F7F6) : const Color(0xFF151515));
    canvas.drawCircle(center, 68, _stroke(white ? const Color(0xFFB4B7BA) : const Color(0xFF2E2E2E), 1.6));
    canvas.drawCircle(
      center.translate(0, 1),
      66.6,
      _stroke((white ? const Color(0xFF8E9194) : Colors.black).withValues(alpha: white ? 0.25 : 0.6), 1.2),
    );

    final picture = recorder.endRecording();
    final image = picture.toImageSync(width, height);
    picture.dispose();
    return image;
  }

  @override
  bool shouldRepaint(covariant _VideoBodyPainter old) => old.lcd != lcd || old.color != color;
}

/// Par-dessus l'écran : filet de lumière en haut de l'écran et très léger
/// reflet en biais de la couche transparente sur toute la façade.
class _VideoGlassPainter extends CustomPainter {
  const _VideoGlassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _videoBody.width, size.height / _videoBody.height);
    canvas.translate(-_videoOrigin.dx, -_videoOrigin.dy);
    canvas.drawRect(
      Rect.fromLTWH(_videoLcd.left, _videoLcd.top, _videoLcd.width, 1.5),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(_videoFace, const Radius.circular(47.5)),
      Paint()
        ..shader = ui.Gradient.linear(const Offset(119, 98), const Offset(716, 700), [
          Colors.white.withValues(alpha: 0.09),
          Colors.white.withValues(alpha: 0.025),
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0),
        ], const [0, 0.42, 0.43, 1]),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// --- Écran -------------------------------------------------------------------

const double _barH = 22;

/// Hauteur de la bande de pochettes du nano 5G (un cinquième de l'écran,
/// d'après photo).
const double _stripH = 80;
const double _stripFade = 6;
const _ink = Color(0xFF111111);
const _font = 'Noto Sans';

/// Les deux interfaces des écrans couleur : celle de 2004-2006 (baladeur
/// photo, 5e génération, nano 1G et 2G), et celle de 2007 (Classic, nano
/// 3G et 4G) avec ses menus scindés, Cover Flow et les albums en vignettes.
enum ColorUi { video, classic }

class ClassicLook extends ScreenLook {
  const ClassicLook({this.portrait = false, this.tall = false, this.ui = ColorUi.classic, this.landscape = const Size(320, 240)});

  /// Écran vertical, 240 × 320 (nano de 4e génération).
  final bool portrait;

  /// Écran vertical allongé, 240 × 376 (nano de 5e génération).
  final bool tall;

  final ColorUi ui;

  /// Taille logique de l'écran horizontal : plus petite que 320 × 240 sur
  /// les petits écrans (nano 1G et 2G, photo), pour que le texte y garde à
  /// peu près la taille qu'il a sur le 5G au lieu d'y être miniaturisé.
  final Size landscape;

  bool get _modern => ui == ColorUi.classic;

  @override
  double get barHeight => _barH;

  @override
  int rowsFor(MenuKind kind) => switch (kind) {
        MenuKind.tall when _modern => portrait ? (tall ? 8 : 7) : 5,
        MenuKind.split when tall => ((size.height - _stripH - _barH) / rowHeight).floor(),
        _ => visibleRows,
      };

  @override
  double rowHeightFor(MenuKind kind) =>
      kind == MenuKind.tall && _modern ? (size.height - _barH) / rowsFor(kind) : rowHeight;

  @override
  ({Rect menu, Rect image})? split(Size screen) {
    // Nano 5G : le menu en haut, une bande de pochettes en bas.
    if (tall) {
      final top = screen.height - _stripH;
      // La bande déborde vers le haut de [_stripFade] : le blanc du menu y
      // fond au noir.
      return (menu: Rect.fromLTRB(0, _barH, screen.width, top), image: Rect.fromLTRB(0, top - _stripFade, screen.width, screen.height));
    }
    // (Pas sur l'écran vertical du nano 4G : menu pleine largeur.)
    if (!_modern || portrait) return null;
    // L'image prend toute la hauteur : la barre de titre s'arrête à elle.
    final w = screen.width / 2;
    return (
      menu: Rect.fromLTRB(0, _barH, w, screen.height),
      image: Rect.fromLTRB(w, 0, screen.width, screen.height),
    );
  }

  @override
  Widget preview(MenuEntry entry, PlayerController player, {required bool active}) =>
      tall ? _AlbumStrip(player: player, active: active) : _Preview(kind: entry.preview, seed: entry.label, player: player, active: active);

  @override
  List<NowPlayingMode> get centerCycle => _modern
      ? const [NowPlayingMode.scrub, NowPlayingMode.rating, NowPlayingMode.shuffle]
      : const [NowPlayingMode.scrub, NowPlayingMode.art, NowPlayingMode.rating];

  @override
  Size get size => portrait ? Size(240, tall ? 376 : 320) : landscape;

  /// Lignes plus hautes et texte plus gros sur l'écran allongé du nano 5G
  /// (photo : 11 lignes environ).
  @override
  double get rowHeight => tall ? 32 : 24;

  @override
  int get visibleRows => portrait ? (tall ? 11 : 12) : ((landscape.height - _barH) / rowHeight).floor();

  @override
  double get scrollbarWidth => 9;

  @override
  TextStyle get textStyle =>
      TextStyle(fontFamily: _font, color: _ink, fontSize: tall ? 17 : 14, fontWeight: FontWeight.w600, height: 1);

  @override
  Color get background => Colors.white;

  @override
  Color get nowPlayingBackground => portrait ? const Color(0xFF0E0F12) : background;

  @override
  bool get coverFlow => _modern;

  @override
  Widget statusBar({
    required String title,
    required bool playing,
    required bool hasTrack,
    bool nowPlaying = false,
    bool locked = false,
  }) =>
      portrait && nowPlaying
          ? _DarkStatusBar(title: title, playing: playing, hasTrack: hasTrack, locked: locked)
          : _StatusBar(title: title, playing: playing, hasTrack: hasTrack, locked: locked, modern: _modern);

  @override
  Widget highlight() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7DBBF5), Color(0xFF3A8BE6), Color(0xFF1F6BD3)],
            stops: [0, 0.5, 1],
          ),
          border: Border(top: BorderSide(color: Color(0xFF5FA2EC)), bottom: BorderSide(color: Color(0xFF1857B3))),
        ),
      );

  @override
  Widget row(MenuEntry entry, {required bool selected, MenuKind kind = MenuKind.normal}) =>
      _Row(entry: entry, selected: selected, tall: kind == MenuKind.tall && _modern);

  @override
  CustomPainter scrollbar(double start, double extent) => _ScrollbarPainter(start, extent);

  @override
  Widget empty() => Center(
        child: Text(tr('Aucun élément'), style: const TextStyle(color: Color(0xFF8A8F95))),
      );

  @override
  Widget nowPlaying(PlayerController player, NowPlayingMode mode) =>
      portrait ? _NowPlayingPortrait(player: player, mode: mode, tall: tall) : _NowPlaying(player: player, mode: mode, modern: _modern, height: size.height - _barH);
}

// --- Barre de titre ----------------------------------------------------------

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.title,
    required this.playing,
    required this.hasTrack,
    required this.locked,
    required this.modern,
  });

  final String title;
  final bool playing;
  final bool hasTrack;
  final bool locked;

  /// Interface de 2007 : le titre à gauche, l'icône de lecture à côté de
  /// la batterie. Avant : le titre au milieu, l'icône à gauche.
  final bool modern;

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2E6FCB);
    final text = Text(
      title,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    );
    final play = Icon(playing ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 15, color: blue);
    const lock = Icon(Icons.lock_rounded, size: 11, color: Color(0xFF4A4F55));
    return Container(
      height: _barH,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFDFDFD), Color(0xFFE4E7EA), Color(0xFFCDD1D6)],
        ),
        border: Border(bottom: BorderSide(color: Color(0xFF8F949A))),
      ),
      child: Stack(
        children: [
          if (modern) ...[
            Positioned.fill(
              left: 8,
              right: 38.0 + (hasTrack ? 16 : 0) + (locked ? 14 : 0),
              child: Align(alignment: Alignment.centerLeft, child: text),
            ),
            if (hasTrack) Positioned(right: 34, top: 0, bottom: 0, child: play),
            if (locked) Positioned(right: hasTrack ? 51 : 36, top: 0, bottom: 0, child: lock),
          ] else ...[
            // Entre l'icône de lecture et la batterie ; coupé par « … » si trop long.
            Positioned.fill(left: 26, right: locked ? 50 : 38, child: Center(child: text)),
            if (hasTrack) Positioned(left: 6, top: 0, bottom: 0, child: play),
            if (locked) const Positioned(right: 36, top: 0, bottom: 0, child: lock),
          ],
          const Positioned(right: 7, top: 6, child: CustomPaint(size: Size(24, 10), painter: _BatteryPainter())),
        ],
      ),
    );
  }
}

/// Barre noire de l'écran « En lecture » du nano 4G : titre blanc, l'icône
/// de lecture à côté de la batterie.
class _DarkStatusBar extends StatelessWidget {
  const _DarkStatusBar({required this.title, required this.playing, required this.hasTrack, required this.locked});

  final String title;
  final bool playing;
  final bool hasTrack;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _barH,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF55585E), Color(0xFF2C2E33), Color(0xFF17181B)],
        ),
        border: Border(bottom: BorderSide(color: Color(0xFF000000))),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            left: 30,
            right: 52,
            child: Center(
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFF2F3F5)),
              ),
            ),
          ),
          if (hasTrack)
            Positioned(
              right: 33,
              top: 0,
              bottom: 0,
              child: Icon(playing ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 15, color: const Color(0xFFE9EBEE)),
            ),
          if (locked)
            const Positioned(left: 7, top: 0, bottom: 0, child: Icon(Icons.lock_rounded, size: 11, color: Color(0xFFE9EBEE))),
          const Positioned(right: 7, top: 6, child: CustomPaint(size: Size(24, 10), painter: _BatteryPainter())),
        ],
      ),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  const _BatteryPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width - 2, size.height), const Radius.circular(2));
    canvas.drawRRect(body, Paint()..color = const Color(0xFF6B7076));
    final inner = body.deflate(1.2);
    canvas.drawRRect(
      inner,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB8F08A), Color(0xFF4FB320), Color(0xFF2F8A12)],
        ).createShader(inner.outerRect),
    );
    canvas.drawRect(Rect.fromLTWH(size.width - 2, 3, 2, size.height - 6), Paint()..color = const Color(0xFF6B7076));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _Row extends StatelessWidget {
  const _Row({required this.entry, required this.selected, this.tall = false});

  final MenuEntry entry;
  final bool selected;

  /// Ligne haute : la vignette de l'album, son titre, et l'artiste dessous.
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : _ink;
    if (tall) {
      return Padding(
        padding: const EdgeInsets.only(left: 5, right: 4),
        child: LayoutBuilder(builder: (context, box) {
          final art = box.maxHeight - 8;
          return Row(
            children: [
              _Artwork(bytes: entry.art?.call(), size: art),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Marquee(entry.label, active: selected, style: TextStyle(color: color)),
                    if (entry.subtitle case final sub?) ...[
                      const SizedBox(height: 4),
                      Text(
                        sub,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: selected ? const Color(0xFFE3EEFB) : const Color(0xFF6A6F75),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (entry.open != null) Icon(Icons.chevron_right_rounded, size: 18, color: color),
            ],
          );
        }),
      );
    }
    final value = entry.value?.call();
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 4),
      child: Row(
        children: [
          Expanded(child: Marquee(entry.label, active: selected, style: TextStyle(color: color))),
          if (value != null)
            Padding(
              padding: EdgeInsets.only(left: 8, right: entry.open == null ? 4 : 0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Text(
                  value,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: selected ? Colors.white : const Color(0xFF6A6F75), fontWeight: FontWeight.w500),
                ),
              ),
            ),
          if (entry.checked?.call() ?? false)
            Padding(padding: const EdgeInsets.only(right: 4), child: Icon(Icons.check_rounded, size: 16, color: color)),
          if (entry.open != null) Icon(Icons.chevron_right_rounded, size: 18, color: color),
        ],
      ),
    );
  }
}

class _ScrollbarPainter extends CustomPainter {
  const _ScrollbarPainter(this.start, this.extent);

  final double start;
  final double extent;

  @override
  void paint(Canvas canvas, Size size) {
    final track = Offset.zero & size;
    canvas.drawRect(
      track,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFC9CDD2), Color(0xFFEFF1F3)]).createShader(track),
    );
    canvas.drawLine(Offset.zero, Offset(0, size.height), Paint()..color = const Color(0xFF9DA2A8));
    final h = (size.height * extent).clamp(12.0, size.height);
    final y = (size.height - h) * (start / (1 - extent)).clamp(0.0, 1.0);
    final thumb = RRect.fromRectAndRadius(Rect.fromLTWH(1.5, y + 1, size.width - 3, h - 2), const Radius.circular(3));
    canvas.drawRRect(
      thumb,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF3F8EE8), Color(0xFF7DBBF5), Color(0xFF2E78D8)])
            .createShader(thumb.outerRect),
    );
  }

  @override
  bool shouldRepaint(covariant _ScrollbarPainter old) => old.start != start || old.extent != extent;
}

// --- En lecture --------------------------------------------------------------

String _time(Duration d) {
  final s = d.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

class _NowPlaying extends StatelessWidget {
  const _NowPlaying({required this.player, required this.mode, required this.modern, required this.height});

  final PlayerController player;
  final NowPlayingMode mode;

  /// Hauteur sous la barre de titre.
  final double height;

  /// Interface de 2007 : la pochette de biais, avec son reflet.
  final bool modern;

  @override
  Widget build(BuildContext context) {
    final track = player.current;
    if (track == null) {
      return Center(child: Text(tr('Aucun morceau')));
    }
    // La pochette en grand (bouton central, 5e génération et consorts).
    if (mode == NowPlayingMode.art) {
      return LayoutBuilder(
        builder: (context, box) => Center(child: _Artwork(bytes: player.cover, size: box.maxHeight - 14)),
      );
    }
    // Rang dans ce qui a été lancé (l'album, la liste…), comme sur un vrai
    // baladeur ; rien si le morceau a été lancé ailleurs (appli Spotify).
    final position = player.queueIndex >= 0 ? trOf(player.queueIndex + 1, player.nowPlaying.length) : '';

    // Sur les petits écrans (nano 1G et 2G), la pochette rapetisse et le
    // texte remonte pour rester au-dessus de la barre de progression.
    final art = math.min(modern ? 108.0 : 116.0, height - 74);
    // Sans pochette, l'interface 2004-2006 centre le texte sur toute la
    // largeur (photos du 5G), sans vignette vide.
    final bare = !modern && player.cover == null;
    final small = height < 160;
    final gaps = small ? 4.0 : 18.0;
    final double textTop = bare ? 20 + math.max(0.0, (height - 66 - 55 - gaps) / 2) : math.min(40.0, height - 122);
    // Centré : trois lignes de même taille et même graisse, comme sur le 5G.
    const bareStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF33363B));
    Widget line(String text, TextStyle style) =>
        bare ? Center(child: Marquee(text, style: small ? style : bareStyle)) : Marquee(text, style: style);
    return Stack(
      children: [
        Positioned(
          left: 8,
          top: 5,
          child: Text(position, style: const TextStyle(fontSize: 11, color: Color(0xFF4A4F55))),
        ),
        // L'aléatoire et la répétition, s'ils sont mis.
        Positioned(right: 8, top: 4, child: _PlayIcons(player: player, color: const Color(0xFF2E6FCB), size: 13)),
        if (modern)
          Positioned(left: 12, top: 22, child: _TiltedArtwork(bytes: player.cover, size: art))
        else if (!bare)
          Positioned(left: 10, top: 24, child: _Artwork(bytes: player.cover, size: art)),
        Positioned(
          left: bare ? 8 : 10 + art + 12,
          right: 8,
          top: textTop,
          child: Column(
            crossAxisAlignment: bare ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              line(track.title, const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              SizedBox(height: small ? 2 : 10),
              line(track.artist, const TextStyle(fontSize: 13)),
              SizedBox(height: small ? 2 : 8),
              line(track.album, const TextStyle(fontSize: 13, color: Color(0xFF5A5F66))),
            ],
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 10,
          height: 36,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: switch (mode) {
              NowPlayingMode.volume => _VolumeBar(key: const ValueKey('vol'), volume: player.volume / 100),
              NowPlayingMode.rating => _Stars(
                  key: const ValueKey('stars'),
                  stars: player.rating(track),
                  size: 22,
                  on: const Color(0xFF2E6FCB),
                  off: const Color(0xFFB4B9BF),
                ),
              NowPlayingMode.shuffle => _ShuffleChoice(key: const ValueKey('shuffle'), on: player.shuffle, color: _ink),
              _ => _Progress(key: const ValueKey('prog'), player: player, scrub: mode == NowPlayingMode.scrub),
            },
          ),
        ),
      ],
    );
  }
}

/// Les icônes aléatoire et répétition de l'écran « En lecture ».
class _PlayIcons extends StatelessWidget {
  const _PlayIcons({required this.player, required this.color, required this.size});

  final PlayerController player;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (player.shuffling) Icon(Icons.shuffle_rounded, size: size, color: color),
          if (player.repeat != RepeatMode.off)
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Icon(
                player.repeat == RepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                size: size,
                color: color,
              ),
            ),
        ],
      );
}

/// La note du morceau : cinq étoiles, pleines jusqu'à [stars], des points
/// au-delà (la molette en ajoute ou en retire).
class _Stars extends StatelessWidget {
  const _Stars({super.key, required this.stars, required this.size, required this.on, required this.off});

  final int stars;
  final double size;
  final Color on, off;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 5; i++)
              SizedBox(
                width: size + 4,
                height: size,
                child: Center(
                  child: i < stars
                      ? Icon(Icons.star_rounded, size: size, color: on)
                      : DecoratedBox(
                          decoration: BoxDecoration(color: off, shape: BoxShape.circle),
                          child: SizedBox.square(dimension: size * 0.22),
                        ),
                ),
              ),
          ],
        ),
      );
}

/// Lecture aléatoire, réglée depuis « En lecture » (la molette la met ou
/// l'enlève).
class _ShuffleChoice extends StatelessWidget {
  const _ShuffleChoice({super.key, required this.on, required this.color, this.fontSize = 13});

  final bool on;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shuffle_rounded, size: fontSize + 3, color: color),
            const SizedBox(width: 6),
            Text(
              '${tr('Lecture aléatoire')} : ${on ? tr('Morceaux') : tr('Non')}',
              maxLines: 1,
              softWrap: false,
              style: TextStyle(fontSize: fontSize, color: color),
            ),
          ],
        ),
      );
}

/// La pochette tournée d'un quart vers la droite, et son reflet sur le
/// fond blanc (Classic, nano 3G).
class _TiltedArtwork extends StatelessWidget {
  const _TiltedArtwork({required this.bytes, required this.size});

  final dynamic bytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    const reflection = 34.0;
    return Transform(
      alignment: Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0016)
        ..rotateY(-0.38),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Artwork(bytes: bytes, size: size),
          const SizedBox(height: 1),
          SizedBox(
            width: size,
            height: reflection,
            child: ClipRect(
              child: Stack(
                children: [
                  // La pochette à l'envers : son bas touche le bas de l'autre.
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Transform.scale(scaleY: -1, child: _Artwork(bytes: bytes, size: size)),
                  ),
                  // …qui se perd dans le blanc.
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x99FFFFFF), Color(0xFFFFFFFF)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// L'image d'un menu scindé : la pochette d'un album qui glisse lentement,
/// remplacée par une autre de temps en temps ; la pochette en cours pour
/// « En lecture » ; un engrenage pour les Réglages.
class _Preview extends StatefulWidget {
  const _Preview({
    required this.kind,
    required this.seed,
    required this.player,
    required this.active,
  });

  final MenuPreview kind;

  /// La ligne du menu : en changer fait passer à une autre pochette.
  final String seed;
  final PlayerController player;

  /// Écran allumé : l'image bouge.
  final bool active;

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  /// Durée d'une pochette, en secondes.
  static const _stay = 9;

  Timer? _timer;
  DateTime _start = clock.now();
  Object? _shown;
  int _serial = 0;

  /// Les pochettes de la ligne en cours, tirées au hasard : tous les albums
  /// passent une fois avant qu'un seul ne revienne.
  final _random = math.Random();
  final _picks = <int>[];
  final _bag = <int>[];
  int _count = 0;

  int _album(int n, int count) {
    if (count != _count) {
      _count = count;
      _picks.clear();
      _bag.clear();
    }
    while (_picks.length <= n) {
      if (_bag.isEmpty) {
        _bag
          ..addAll(Iterable.generate(count))
          ..shuffle(_random);
        // Jamais deux fois de suite la même, d'un tour au suivant.
        if (count > 1 && _bag.last == _lastPick) _bag.insert(0, _bag.removeLast());
      }
      _picks.add(_lastPick = _bag.removeLast());
    }
    return _picks[n];
  }

  int? _lastPick;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_Preview old) {
    super.didUpdateWidget(old);
    if (old.seed != widget.seed || old.kind != widget.kind) {
      _start = clock.now();
      _picks.clear();
    }
    _sync();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Vingt images par seconde suffisent à un glissement aussi lent, et
  /// seulement tant que l'écran est allumé.
  void _sync() {
    final moving = widget.active && widget.kind != MenuPreview.settings;
    if (moving == (_timer != null)) return;
    _timer?.cancel();
    _timer = moving
        ? Timer.periodic(const Duration(milliseconds: 50), (_) {
            if (mounted) setState(() {});
          })
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final t = clock.now().difference(_start).inMilliseconds / 1000;
    final Widget image;
    final Object key;
    switch (widget.kind) {
      case MenuPreview.settings:
        key = 'réglages';
        image = DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF2F4F6), Color(0xFFC3C9D0)],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, box) => Center(
              child: Icon(Icons.settings_rounded, size: math.min(96, box.maxHeight * 0.72), color: const Color(0xFF8A929B)),
            ),
          ),
        );
      case MenuPreview.nowPlaying:
        key = 'en lecture';
        image = _Pan(bytes: player.cover, phase: (t % (_stay * 2)) / (_stay * 2), back: false);
      case MenuPreview.covers:
        final count = player.albums.length;
        if (count == 0) {
          key = 'vide';
          image = const _Pan(bytes: null, phase: 0, back: false);
        } else {
          final turn = t ~/ _stay;
          int album(int n) => _album(n, count);
          player.albumCover(album(turn + 1)); // la suivante se prépare
          key = album(turn);
          image = _Pan(bytes: player.albumCover(album(turn)), phase: (t % _stay) / _stay, back: turn.isOdd);
        }
    }
    // Un numéro neuf à chaque changement d'image : la même peut revenir
    // pendant que la précédente s'efface encore.
    if (key != _shown) {
      _shown = key;
      _serial++;
    }
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            child: KeyedSubtree(key: ValueKey(_serial), child: image),
          ),
          // L'ombre du menu sur l'image, le long de leur bord commun.
          const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0x59000000), Color(0x00000000)]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bande de pochettes sous le menu du nano 5G : les albums défilent
/// lentement de droite à gauche, côte à côte.
class _AlbumStrip extends StatefulWidget {
  const _AlbumStrip({required this.player, required this.active});

  final PlayerController player;

  /// Écran allumé : la bande défile.
  final bool active;

  @override
  State<_AlbumStrip> createState() => _AlbumStripState();
}

class _AlbumStripState extends State<_AlbumStrip> {
  static const _speed = 12.0; // pixels par seconde
  static const _gap = 2.0;

  final DateTime _start = clock.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_AlbumStrip old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _sync() {
    if (widget.active == (_timer != null)) return;
    _timer?.cancel();
    _timer = widget.active
        ? Timer.periodic(const Duration(milliseconds: 50), (_) {
            if (mounted) setState(() {});
          })
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final count = player.albums.length;
    return LayoutBuilder(builder: (context, box) {
      final side = box.maxHeight - _stripFade;
      final step = side + _gap;
      final shift = clock.now().difference(_start).inMilliseconds / 1000 * _speed;
      final first = shift ~/ step;
      return ClipRect(
        child: Column(
          children: [
            // Le blanc du menu fond au noir, juste au-dessus des pochettes.
            const SizedBox(
              height: _stripFade,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x000E0F12), Color(0xFF0E0F12)],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: const Color(0xFF0E0F12),
                child: Stack(
                  children: [
                    for (var k = 0; k * step < box.maxWidth + step; k++)
                      Positioned(
                        left: (first + k) * step - shift,
                        top: 0,
                        child: _Artwork(bytes: count == 0 ? null : player.albumCover((first + k) % count), size: side),
                      ),
                    // Et une ombre sur le haut des pochettes : elles passent sous le menu.
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x99000000), Color(0x00000000)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Une pochette plus grande que son cadre, qui le traverse lentement en
/// biais ([phase] de 0 à 1 ; [back] : dans l'autre sens).
class _Pan extends StatelessWidget {
  const _Pan({required this.bytes, required this.phase, required this.back});

  final dynamic bytes;
  final double phase;
  final bool back;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      if (bytes == null) {
        return const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE9ECEF), Color(0xFFB9BFC6)],
            ),
          ),
          child: Center(child: Icon(Icons.music_note_rounded, size: 72, color: Colors.white)),
        );
      }
      final side = math.max(box.maxWidth, box.maxHeight) * 1.25;
      final p = back ? 1 - phase : phase;
      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: side,
          maxWidth: side,
          minHeight: side,
          maxHeight: side,
          child: Transform.translate(
            offset: Offset(-(side - box.maxWidth) * p, -(side - box.maxHeight) * (0.15 + 0.7 * p)),
            child: Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true, filterQuality: FilterQuality.medium),
          ),
        ),
      );
    });
  }
}

/// En lecture sur l'écran vertical du nano 4G : pochette carrée bord à
/// bord, puis sur fond noir le titre et l'artiste centrés, et une seule
/// ligne temps écoulé · barre · temps restant.
class _NowPlayingPortrait extends StatelessWidget {
  const _NowPlayingPortrait({required this.player, required this.mode, this.tall = false});

  final PlayerController player;
  final NowPlayingMode mode;

  /// Écran allongé du nano 5G : titre, artiste et album en haut, sous la
  /// barre de titre, puis la pochette. Sinon (nano 4G) la pochette d'abord,
  /// le titre et l'artiste dessous, sur son reflet.
  final bool tall;

  static const _white = Color(0xFFF2F3F5);
  static const _grey = Color(0xFFB4B8BE);
  static const _bg = Color(0xFF0E0F12);

  @override
  Widget build(BuildContext context) {
    final track = player.current;
    if (track == null) {
      return ColoredBox(
        color: const Color(0xFF0E0F12),
        child: Center(child: Text(tr('Aucun morceau'), style: const TextStyle(color: _white))),
      );
    }
    const art = 240.0;
    final top = tall ? 50.0 : 0.0;
    final cover = _Artwork(bytes: player.cover, size: art);
    final title = Marquee(track.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _white));
    final artist = Marquee(track.artist, style: const TextStyle(fontSize: 11, color: _grey));
    return ColoredBox(
      color: _bg,
      child: Stack(
        children: [
          Positioned(left: 0, top: top, child: cover),
          // Le reflet de la pochette, comme posée sur une table noire : il
          // occupe tout le bas de l'écran, sous le texte et la barre.
          Positioned(left: 0, top: top + art, width: art, bottom: 0, child: _Reflection(size: art, child: cover)),
          Positioned(
            left: 8,
            right: 8,
            top: tall ? 4 : art + 3,
            child: Column(
              children: [
                title,
                const SizedBox(height: 2),
                artist,
                if (tall && track.album.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Marquee(track.album, style: const TextStyle(fontSize: 11, color: _grey)),
                ],
              ],
            ),
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: 5,
            height: 14,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: switch (mode) {
                NowPlayingMode.volume => _VolumeLine(key: const ValueKey('vol'), volume: player.volume / 100),
                NowPlayingMode.rating => _Stars(
                    key: const ValueKey('stars'),
                    stars: player.rating(track),
                    size: 14,
                    on: _white,
                    off: const Color(0xFF8A8F96),
                  ),
                NowPlayingMode.shuffle =>
                  _ShuffleChoice(key: const ValueKey('shuffle'), on: player.shuffle, color: _white, fontSize: 10.5),
                _ => _ProgressLine(key: const ValueKey('prog'), player: player, scrub: mode == NowPlayingMode.scrub),
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Le haut du reflet de [child] (un carré de côté [size]) : retourné, sous
/// un voile qui se fond dans le fond de l'écran.
class _Reflection extends StatelessWidget {
  const _Reflection({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: size,
            maxHeight: size,
            child: Transform.flip(flipY: true, child: child),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x990E0F12), _NowPlayingPortrait._bg],
              stops: [0, 0.9],
            ),
          ),
        ),
      ],
    );
  }
}

/// 0:21 ━━━━━━━━━ -2:15, sur une ligne.
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({super.key, required this.player, required this.scrub});

  final PlayerController player;
  final bool scrub;

  @override
  Widget build(BuildContext context) {
    final pos = player.smoothPosition;
    final remaining = player.duration - pos;
    const time = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _NowPlayingPortrait._white);
    return Row(
      children: [
        SizedBox(width: 30, child: Text(_time(pos), style: time)),
        Expanded(child: SizedBox(height: 8, child: CustomPaint(size: Size.infinite, painter: _BarPainter(player.progress, scrub)))),
        SizedBox(
          width: 34,
          child: Text(
            '-${_time(remaining.isNegative ? Duration.zero : remaining)}',
            style: time,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _VolumeLine extends StatelessWidget {
  const _VolumeLine({super.key, required this.volume});

  final double volume;

  @override
  Widget build(BuildContext context) {
    const icon = Color(0xFFD5D8DC);
    return Row(
      children: [
        const Icon(Icons.volume_mute_rounded, size: 13, color: icon),
        const SizedBox(width: 4),
        Expanded(child: SizedBox(height: 8, child: CustomPaint(size: Size.infinite, painter: _BarPainter(volume, false)))),
        const SizedBox(width: 4),
        const Icon(Icons.volume_up_rounded, size: 13, color: icon),
      ],
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.bytes, required this.size});

  final dynamic bytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Widget image = bytes == null
        ? DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE9ECEF), Color(0xFFB9BFC6)],
              ),
            ),
            child: Center(child: Icon(Icons.music_note_rounded, size: math.min(48, size * 0.42), color: Colors.white)),
          )
        : Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true, filterQuality: FilterQuality.medium);
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(border: Border.all(color: const Color(0x33000000))),
        child: image,
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({super.key, required this.player, required this.scrub});

  final PlayerController player;
  final bool scrub;

  @override
  Widget build(BuildContext context) {
    final pos = player.smoothPosition;
    final remaining = player.duration - pos;
    return Column(
      children: [
        SizedBox(height: 12, child: CustomPaint(size: Size.infinite, painter: _BarPainter(player.progress, scrub))),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_time(pos), style: const TextStyle(fontSize: 11)),
            Text('-${_time(remaining.isNegative ? Duration.zero : remaining)}', style: const TextStyle(fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _VolumeBar extends StatelessWidget {
  const _VolumeBar({super.key, required this.volume});

  final double volume;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.volume_mute_rounded, size: 14, color: Color(0xFF4A4F55)),
        const SizedBox(width: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: SizedBox(height: 12, child: CustomPaint(size: Size.infinite, painter: _BarPainter(volume, false))),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.volume_up_rounded, size: 14, color: Color(0xFF4A4F55)),
      ],
    );
  }
}

/// Barre bombée façon verre : creux gris, remplissage bleu brillant.
class _BarPainter extends CustomPainter {
  const _BarPainter(this.value, this.diamond);

  final double value;
  final bool diamond;

  @override
  void paint(Canvas canvas, Size size) {
    final r = const Radius.circular(2);
    final track = RRect.fromRectAndRadius(Offset.zero & size, r);
    canvas.drawRRect(
      track,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFBFC4CA), Color(0xFFF4F5F7)],
        ).createShader(track.outerRect),
    );
    final fillW = size.width * value.clamp(0.0, 1.0);
    if (fillW > 0) {
      final fill = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, fillW, size.height), r);
      canvas.drawRRect(
        fill,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9CCCF8), Color(0xFF3A8BE6), Color(0xFF2167CC)],
            stops: [0, 0.5, 1],
          ).createShader(fill.outerRect),
      );
    }
    canvas.drawRRect(
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF7D838A),
    );
    if (diamond) {
      final c = Offset(fillW, size.height / 2);
      final h = size.height / 2 + 3;
      final path = Path()
        ..moveTo(c.dx, c.dy - h)
        ..lineTo(c.dx + h * 0.75, c.dy)
        ..lineTo(c.dx, c.dy + h)
        ..lineTo(c.dx - h * 0.75, c.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = Colors.white);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFF33383E),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) => old.value != value || old.diamond != diamond;
}

