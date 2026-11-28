import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'classic.dart';
import 'finish.dart';
import 'look.dart';
import 'mini.dart';
import 'model.dart';
import 'wheel.dart';

/// Écran monochrome de la 4e génération : 160 × 128, 6 lignes.
const _monoLook = MiniLook(size: Size(160, 128), visibleRows: 6);

/// Les deux premières générations : la police Chicago, pas encore de notes.
const _chicagoLook = MiniLook(size: Size(160, 128), visibleRows: 6, font: 'ChicagoFLF', ratings: false);

/// La 3e génération garde la police Chicago (photo officielle), avec
/// les notes en plus.
const _chicagoRatedLook = MiniLook(size: Size(160, 128), visibleRows: 6, font: 'ChicagoFLF');

/// La 1re génération (2001) : molette mécanique qui tourne vraiment,
/// entourée de quatre boutons, écran monochrome, façade blanche sous un
/// plexi transparent. Dessinée d'après une photo de face (274 × 462 px) :
/// les cotes ci-dessous sont celles de la photo, × [_k].
class FirstGenModel extends DeviceModel {
  const FirstGenModel();

  /// Unités de dessin par pixel de la photo.
  static const double _k = 412 / 274;

  static const Size _size = Size(274 * _k, 462 * _k);
  static const Rect _screen = Rect.fromLTWH(52.5 * _k, 29 * _k, 173 * _k, 139.5 * _k);

  /// Anneau des quatre boutons, disque qui tourne, bouton central (molette
  /// réduite à 97 % sur la photo).
  static const WheelStyle _wheel = WheelStyle(
    radius: 120 * 0.97 * _k,
    buttonRadius: 33.5 * 0.97 * _k,
    innerRadius: 94 * 0.97 * _k,
    labels: false,
    onBody: true,
  );

  @override
  String get id => 'gen1';

  @override
  String get family => 'gen1';

  @override
  String get label => '1re génération';

  @override
  String get variantName => 'Blanc';

  @override
  Color get swatch => const Color(0xFFF7F7F5);

  @override
  Size get size => _size;

  @override
  double get cornerRadius => 27 * _k;

  @override
  Rect get screen => _screen;

  /// Au milieu de la tranche du haut, entre le port FireWire (à gauche) et
  /// le verrou (à droite).
  @override
  double get jackX => 212;

  @override
  Offset get wheelCenter => const Offset(138 * _k, 310 * _k);

  /// Dessinée avec le boîtier : seuls les appuis se voient.
  @override
  WheelStyle get wheel => _wheel;

  /// En haut à droite.
  @override
  HoldSwitch? get hold => const HoldSwitch(330);

  @override
  ScreenLook get look => _chicagoLook;

  @override
  CustomPainter get body => _FirstGenBodyPainter(_chicagoLook.background);

  @override
  CustomPainter? get glass => const _FirstGenGlassPainter();
}

/// La 2e génération (2002) : même boîtier que la première, mais la molette
/// est tactile (elle ne tourne plus), toujours entourée de ses quatre
/// boutons.
class SecondGenModel extends DeviceModel {
  const SecondGenModel();

  @override
  String get id => 'gen2';

  @override
  String get family => 'gen2';

  @override
  String get label => '2e génération';

  @override
  String get variantName => 'Blanc';

  @override
  Color get swatch => const Color(0xFFF7F7F5);

  @override
  Size get size => FirstGenModel._size;

  @override
  double get cornerRadius => 27 * FirstGenModel._k;

  @override
  Rect get screen => FirstGenModel._screen;

  /// Au milieu de la tranche du haut, à côté de la prise télécommande ; le
  /// port FireWire (sous son volet) à gauche, le verrou à droite.
  @override
  double get jackX => 200;

  @override
  Offset get wheelCenter => const FirstGenModel().wheelCenter;

  @override
  WheelStyle get wheel => FirstGenModel._wheel;

  @override
  HoldSwitch? get hold => const HoldSwitch(330);

  @override
  ScreenLook get look => _chicagoLook;

  @override
  CustomPainter get body => _FirstGenBodyPainter(_chicagoLook.background);

  @override
  CustomPainter? get glass => const _FirstGenGlassPainter();
}

/// La 3e génération (2003) : molette tactile sans inscriptions, quatre
/// boutons ronds alignés au-dessus. Dessinée d'après une photo de face
/// (267 × 452 px) : les cotes ci-dessous sont celles de la photo, × [_k].
class ThirdGenModel extends DeviceModel {
  const ThirdGenModel();

  /// Unités de dessin par pixel de la photo.
  static const double _k = 412 / 267;

  static const Size _size = Size(267 * _k, 452 * _k);
  static const Rect _screen = Rect.fromLTWH(45 * _k, 30 * _k, 177 * _k, 144 * _k);

  @override
  String get id => 'gen3';

  @override
  String get family => 'gen3';

  @override
  String get label => '3e génération';

  @override
  String get variantName => 'Blanc';

  @override
  Color get swatch => const Color(0xFFF7F7F5);

  @override
  Size get size => _size;

  @override
  double get cornerRadius => 30 * _k;

  @override
  Rect get screen => _screen;

  /// Au milieu de la tranche du haut, entre le verrou (à gauche) et la
  /// prise télécommande (à droite).
  @override
  double get jackX => 218;

  @override
  Offset get wheelCenter => const Offset(135.5 * _k, 337.5 * _k);

  /// Dessinée avec le boîtier : la molette ne montre que l'appui au centre.
  @override
  WheelStyle get wheel =>
      const WheelStyle(radius: 87 * _k, buttonRadius: 31.4 * _k, labels: false, sideClicks: false, onBody: true);

  @override
  List<DeviceButton> get buttons => const [
        DeviceButton(WheelZone.previous, Offset(46.5 * _k, 218 * _k), 25 * _k),
        DeviceButton(WheelZone.menu, Offset(105.5 * _k, 218 * _k), 25 * _k),
        DeviceButton(WheelZone.playPause, Offset(164.5 * _k, 218 * _k), 25 * _k),
        DeviceButton(WheelZone.next, Offset(223 * _k, 218 * _k), 25 * _k),
      ];

  /// En haut à gauche.
  @override
  HoldSwitch? get hold => const HoldSwitch(82);

  @override
  CustomPainter buttonPainter(DeviceButton button, {required bool pressed, double lit = 0}) =>
      _ThirdGenButtonPainter(button.zone, pressed, lit);

  @override
  ScreenLook get look => _chicagoRatedLook;

  @override
  CustomPainter get body => _ThirdGenBodyPainter(_chicagoRatedLook.background);

  @override
  CustomPainter? get glass => const _ThirdGenGlassPainter();
}

/// Teintes de la 4e génération : blanche, ou l'édition U2 (façade noire,
/// molette rouge).
enum FourthGenColor {
  blanc('Blanc', Color(0xFFF7F7F5)),
  u2('U2', Color(0xFFCC001F));

  const FourthGenColor(this.displayName, this.swatch);

  final String displayName;
  final Color swatch;
}

/// La 4e génération (2004) : la molette cliquable du Mini sur le grand
/// baladeur, inscriptions sur la molette, écran monochrome.
class FourthGenModel extends DeviceModel {
  const FourthGenModel([this.color = FourthGenColor.blanc]);

  final FourthGenColor color;

  // ≈ 6,67 unités par mm (61 × 104,1 mm).
  static const Size _size = Size(407, 694);
  static const Rect _screen = Rect.fromLTWH(70, 50, 267, 214);

  /// Celui du boîtier du 3G, qu'il reprend.
  static const double _radius = 30 * 407 / 267;

  @override
  String get id => color == FourthGenColor.blanc ? 'gen4' : 'gen4-${color.name}';

  @override
  String get family => 'gen4';

  @override
  String get label => '4e génération';

  @override
  String get variantName => color.displayName;

  @override
  Color get swatch => color.swatch;

  @override
  Size get size => _size;

  @override
  double get cornerRadius => _radius;

  @override
  Rect get screen => _screen;

  /// Au milieu de la tranche du haut, à droite de la prise télécommande
  /// (le verrou est tout à droite).
  @override
  double get jackX => 216;

  @override
  Offset get wheelCenter => const Offset(203.5, 495);

  @override
  WheelStyle get wheel => switch (color) {
    // Molette gris clair, inscriptions presque blanches.
    FourthGenColor.blanc => const WheelStyle(
      radius: 140,
      buttonRadius: 47,
      labelSize: 17,
      label: Color(0xFFFBFBFC),
      recess: Color(0xFFE3E4E5),
      ring: [Color(0xFFE2E4E6), Color(0xFFDADCDF), Color(0xFFCFD2D5)],
      edgeLight: 0.5,
      groove: Color(0xFFBDC0C4),
      buttonUp: [Color(0xFFFCFCFC), Color(0xFFF1F1F2)],
      buttonDown: [Color(0xFFDFE0E2), Color(0xFFEFF0F0)],
    ),
    // Molette rouge, inscriptions claires, bouton central noir.
    FourthGenColor.u2 => const WheelStyle(
      radius: 140,
      buttonRadius: 47,
      labelSize: 17,
      label: Color(0xFFF7ECEC),
      recess: Color(0xFF000000),
      ring: [Color(0xFFDD0023), Color(0xFFCC001F), Color(0xFFB0001A)],
      edgeLight: 0.22,
      groove: Color(0xFF2A0006),
      buttonUp: [Color(0xFF17151A), Color(0xFF090507)],
      buttonDown: [Color(0xFF050304), Color(0xFF100D10)],
      buttonEdge: 0.14,
    ),
  };

  @override
  ScreenLook get look => _monoLook;

  @override
  CustomPainter get body => switch (color) {
    FourthGenColor.blanc => _CasingBodyPainter(_size, _screen, _monoLook.background, wheelCenter, 140),
    FourthGenColor.u2 => _CasingBodyPainter(_size, _screen, _monoLook.background, wheelCenter, 140, dark: true),
  };

  @override
  CustomPainter? get glass => const _CasingGlassPainter(_size, _screen);

  /// En haut à droite (curseur noir sur l'U2).
  @override
  HoldSwitch? get hold => color == FourthGenColor.u2
      ? const HoldSwitch(346, knob: [Color(0xFF55565A), Color(0xFF2A2B2E), Color(0xFF1A1B1D)])
      : const HoldSwitch(346);

  @override
  bool operator ==(Object other) => other is FourthGenModel && other.color == color;

  @override
  int get hashCode => color.hashCode;
}

/// Le baladeur photo (fin 2004) : le boîtier de la 4e génération, molette
/// grise, et pour la première fois un écran couleur.
class PhotoModel extends DeviceModel {
  const PhotoModel();

  static const Size _size = FourthGenModel._size;
  static const Rect _screen = Rect.fromLTWH(76, 44, 256, 192);
  static const double _radius = FourthGenModel._radius;

  @override
  String get id => 'photo';

  @override
  String get family => 'photo';

  @override
  String get label => 'Photo';

  @override
  String get variantName => 'Blanc';

  @override
  Color get swatch => const Color(0xFFF7F7F5);

  @override
  Size get size => _size;

  @override
  double get cornerRadius => _radius;

  @override
  Rect get screen => _screen;

  @override
  double get jackX => 216;

  @override
  Offset get wheelCenter => const Offset(203.5, 488);

  @override
  WheelStyle get wheel => const FourthGenModel().wheel;

  @override
  HoldSwitch? get hold => const HoldSwitch(346);

  @override
  ScreenLook get look => const ClassicLook(ui: ColorUi.video, landscape: Size(256, 192));

  @override
  CustomPainter get body => _CasingBodyPainter(_size, _screen, look.background, wheelCenter, 140);

  @override
  CustomPainter? get glass => const _CasingGlassPainter(_size, _screen);
}

/// Teintes du nano de 1re génération : plastique brillant blanc ou noir.
enum Nano1Color {
  blanc('Blanc', Color(0xFFF7F7F5)),
  noir('Noir', Color(0xFF1B1C1E));

  const Nano1Color(this.displayName, this.swatch);

  final String displayName;
  final Color swatch;
}

/// Le nano de 1re génération (2005) : très fin (40 × 90 mm), façade en
/// plastique brillant sous un liseré transparent, dos chromé, petit écran
/// couleur en haut, molette grise.
class Nano1Model extends DeviceModel {
  const Nano1Model([this.color = Nano1Color.blanc]);

  final Nano1Color color;

  /// Unités de dessin par pixel de la photo (redressée, coin de l'acrylique
  /// en 209, 98).
  static const double _k = 267 / 224;

  static const Size _size = Size(224 * _k, 498 * _k);
  static const Rect _screen = Rect.fromLTWH(31 * _k, 32.5 * _k, 164.5 * _k, 125 * _k);
  static const double _radius = 16 * _k;

  @override
  String get id => color == Nano1Color.blanc ? 'nano1' : 'nano1-${color.name}';

  @override
  String get family => 'nano1';

  @override
  String get label => 'Nano 1G';

  @override
  String get variantName => color.displayName;

  @override
  Color get swatch => color.swatch;

  @override
  Size get size => _size;

  @override
  double get cornerRadius => _radius;

  @override
  Rect get screen => _screen;

  /// En bas à gauche, à côté du connecteur dock.
  @override
  double get jackX => 46;

  @override
  bool get jackOnTop => false;

  /// En haut à droite.
  @override
  HoldSwitch? get hold => const HoldSwitch(206);

  @override
  Offset get wheelCenter => const Offset(112 * _k, 328 * _k);

  @override
  WheelStyle get wheel => switch (color) {
    // Dessinée avec le boîtier : seuls les appuis se voient.
    Nano1Color.blanc => const WheelStyle(radius: 84 * _k, buttonRadius: 37 * _k, labels: false, onBody: true),
    // Molette gris anthracite, bouton central noir.
    Nano1Color.noir => const WheelStyle(
      radius: 84 * _k,
      buttonRadius: 37 * _k,
      iconScale: 0.7,
      labelSize: 12,
      labelSpacing: 0.8,
      label: Color(0xFFE4E5E7),
      recess: Color(0xFF000000),
      ring: [Color(0xFF3B3D40), Color(0xFF313336), Color(0xFF27292B)],
      edgeLight: 0.14,
      groove: Color(0xFF050506),
      buttonUp: [Color(0xFF17181A), Color(0xFF0A0B0C)],
      buttonDown: [Color(0xFF060607), Color(0xFF111213)],
      buttonEdge: 0.14,
    ),
  };

  @override
  ScreenLook get look => const ClassicLook(ui: ColorUi.video, landscape: Size(200, 150));

  @override
  CustomPainter get body => switch (color) {
    Nano1Color.blanc => _Nano1BodyPainter(look.background),
    Nano1Color.noir => const _WhiteBodyPainter(
      _size,
      _radius,
      _screen,
      rim: 2.5,
      front: _black,
      dark: true,
    ),
  };

  @override
  CustomPainter? get glass => switch (color) {
    Nano1Color.blanc => const _Nano1GlassPainter(),
    Nano1Color.noir => const _GlassPainter(_size, _radius, _screen),
  };

  @override
  Size get windowSize => const Size(360, 720);

  @override
  bool operator ==(Object other) => other is Nano1Model && other.color == color;

  @override
  int get hashCode => color.hashCode;
}

/// Plastique noir brillant (U2, nano noir) : presque noir, relevé sur les
/// photos officielles.
const _black = [Color(0xFF18191B), Color(0xFF0B0B0D), Color(0xFF050506)];

// --- Boîtier blanc à dos chromé -------------------------------------------------

class _WhiteBodyPainter extends CustomPainter {
  const _WhiteBodyPainter(this.bodySize, this.radius, this.screen, {this.front = _ivory, this.rim = 3.5, this.dark = false});

  /// Façade noire : le cadre de l'écran et l'arrondi s'y fondent.
  final bool dark;

  final Size bodySize;

  /// Épaisseur du dos chromé visible autour de la façade.
  final double rim;
  final double radius;
  final Rect screen;

  /// Dégradé de la façade, de haut en bas.
  final List<Color> front;

  static const _ivory = [Color(0xFFFCFCFB), Color(0xFFF8F8F7), Color(0xFFEEEEEC)];

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    canvas.drawRRect(
      outer.shift(const Offset(0, 26)).deflate(10),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
    canvas.drawRRect(
      outer.shift(const Offset(0, 6)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    // Dos en acier poli, visible tout autour.
    canvas.drawRRect(
      outer,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, 0),
          const [Color(0xFF8C9095), Color(0xFFF7F8F9), Color(0xFFB4B8BC), Color(0xFFE8EAEC), Color(0xFF85898E)],
          const [0, 0.18, 0.5, 0.82, 1],
        ),
    );
    // Façade en plastique blanc, un peu plus ivoire que le Classic.
    final front = outer.deflate(rim);
    canvas.drawRRect(
      front,
      Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), this.front, const [0, 0.55, 1]),
    );
    canvas.drawRRect(
      front.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = dark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.07),
    );
    // Écran monochrome dans un cadre gris foncé.
    final frame = RRect.fromRectAndRadius(screen.inflate(9), const Radius.circular(7));
    canvas.drawRRect(frame.inflate(1), Paint()..color = dark ? const Color(0xFF2B2C2F) : const Color(0xFFD2D3D5));
    canvas.drawRRect(frame, Paint()..color = const Color(0xFF34373B));
  }

  @override
  bool shouldRepaint(covariant _WhiteBodyPainter old) =>
      old.screen != screen || old.radius != radius || old.front != front || old.rim != rim || old.dark != dark;
}

class _GlassPainter extends CustomPainter {
  const _GlassPainter(this.bodySize, this.radius, this.screen);

  final Size bodySize;
  final double radius;
  final Rect screen;

  @override
  void paint(Canvas canvas, Size size) {
    final front = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(3.5);
    canvas.save();
    canvas.clipRRect(front);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * 0.78, 0)
        ..lineTo(0, size.height * 0.36)
        ..close(),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width * 0.4, size.height * 0.24),
          [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0)],
          const [0, 0.7, 1],
        ),
    );
    // L'écran est en retrait sous la façade.
    canvas.drawRect(
      Rect.fromLTWH(screen.left, screen.top, screen.width, 7),
      Paint()
        ..shader = ui.Gradient.linear(
          screen.topLeft,
          screen.topLeft + const Offset(0, 7),
          [Colors.black.withValues(alpha: 0.22), Colors.black.withValues(alpha: 0)],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// --- 3e génération ---------------------------------------------------------------
//
// Tout est dessiné en pixels de la photo de référence (coin du boîtier en
// 264, 73), puis mis à l'échelle.

const _photoOrigin = Offset(264, 73);
const _photoBody = Rect.fromLTWH(264, 73, 267, 452);
const _buttonXs = [310.5, 369.5, 428.5, 487.0];

/// Halo flou autour de ce qui est un peu enfoncé (boutons, molette, écran).
Paint _hollow(double alpha) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 3
  ..color = const Color(0xFF7D8481).withValues(alpha: alpha)
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);

Paint _line(Color color, double width) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..color = color;

/// Boîtier, cadre de l'écran, creux des boutons, molette et bouton central :
/// rien n'y bouge.
class _ThirdGenBodyPainter extends CustomPainter {
  const _ThirdGenBodyPainter(this.lcd);

  /// Fond de l'écran, sous les bords que l'écran ne couvre pas tout à fait.
  final Color lcd;

  /// Reflet du bord gauche : une bande nette qui suit les coins du haut et
  /// du bas en s'affinant jusqu'à une pointe.
  static final _stripe = Path()
    ..moveTo(272, 100)
    ..cubicTo(274, 90, 283, 83.7, 296, 84)
    ..cubicTo(285, 88.5, 279.5, 95, 279, 101)
    ..lineTo(279, 497)
    ..cubicTo(279.5, 503, 285, 509.5, 296, 514)
    ..cubicTo(283, 514.3, 274, 508, 272, 498)
    ..close();

  /// Rendu une fois en image : sans ça le moteur refait les flous à chaque
  /// image de l'écran, même quand le boîtier ne change pas.
  /// shortcut: image à 3 × la taille de base, un peu floue au-delà (plein écran sur un écran 5K) ; la rendre à la taille affichée si ça se voit.
  static ui.Image? _image;
  static Color? _imageLcd;
  static const _resolution = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    paintFloatShadow(
      canvas,
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(30 * size.width / _photoBody.width)),
      drop: 26,
      blur: 30,
    );
    if (_image == null || _imageLcd != lcd) {
      _image?.dispose();
      _image = _render();
      _imageLcd = lcd;
    }
    final image = _image!;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  /// Le boîtier seul (plastique, bords qui s'enroulent dans l'ombre, reflet
  /// gauche), en pixels de la photo : repris par la 4e génération et le Photo.
  /// [dark] : plastique noir brillant (U2), le reflet y est plus discret.
  static void casing(Canvas canvas, {bool dark = false}) {
    final body = RRect.fromRectAndRadius(_photoBody, const Radius.circular(30));

    // Plastique plus clair à gauche, un peu voilé en haut et en bas.
    canvas.drawRRect(
      body,
      Paint()
        ..shader = ui.Gradient.linear(const Offset(264, 0), const Offset(531, 0), dark
            ? const [Color(0xFF1A1B1D), Color(0xFF131416), Color(0xFF0F1012), Color(0xFF0B0C0D), Color(0xFF08090A)]
            : const [Color(0xFFEBEDEA), Color(0xFFE4E6E3), Color(0xFFDADCD9), Color(0xFFCFD1CE), Color(0xFFC9CBC8)],
            const [0, 0.45, 0.72, 0.9, 1]),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = ui.Gradient.linear(const Offset(0, 73), const Offset(0, 525), [
          for (final a in const [0.05, 0.03, 0.0, 0.0, 0.01, 0.045]) Colors.black.withValues(alpha: a),
        ], const [0, 0.1, 0.3, 0.4, 0.55, 1]),
    );
    canvas.save();
    canvas.clipRRect(body);
    // Les bords droit et bas s'enroulent dans l'ombre : tout ce qui est hors
    // du boîtier décalé vers le haut-gauche, flouté.
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(_photoBody.inflate(40))
        ..addRRect(body.shift(const Offset(-6, -6))),
      Paint()
        ..color = (dark ? Colors.black : const Color(0xFF1D2A2C)).withValues(alpha: dark ? 0.75 : 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Arête du haut.
    canvas.drawRect(
      const Rect.fromLTWH(264, 73, 267, 24),
      Paint()
        ..shader = ui.Gradient.linear(const Offset(0, 73), const Offset(0, 97), [
          for (final a in const [0.55, 0.27, 0.13, 0.05, 0.0]) (dark ? Colors.black : const Color(0xFF272D2D)).withValues(alpha: a),
        ], const [0, 0.21, 0.38, 0.55, 1]),
    );
    // Reflet du bord gauche : lueur douce, puis la bande nette.
    canvas.drawRect(
      const Rect.fromLTWH(264, 73, 40, 452),
      Paint()
        ..shader = ui.Gradient.linear(const Offset(264, 0), const Offset(304, 0), [
          for (final a in const [0.0, 0.25, 0.3, 0.12, 0.0]) Colors.white.withValues(alpha: dark ? a * 0.8 : a),
        ], const [0, 0.18, 0.38, 0.7, 1]),
    );
    // Sur le noir laqué, le reflet est un blanc gris pâle et net (d'après
    // photo) : c'est le contraste qui fait le brillant.
    canvas.drawPath(_stripe, Paint()..color = dark ? const Color(0xFFC9CCCF).withValues(alpha: 0.9) : const Color(0xFFF9FBF6));
    // Laque : un voile de lumière très doux en haut à gauche, comme un reflet
    // de la pièce dans le vernis.
    if (dark) {
      canvas.drawRRect(
        body,
        Paint()
          ..shader = ui.Gradient.linear(const Offset(264, 73), const Offset(480, 330), [
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0.0),
          ]),
      );
    }
    canvas.restore();
    canvas.drawRRect(
      body.deflate(0.5),
      _line(dark ? const Color(0xFF5A5D60).withValues(alpha: 0.4) : const Color(0xFFA9AEAC).withValues(alpha: 0.25), 1),
    );
  }

  ui.Image _render() {
    final width = (ThirdGenModel._size.width * _resolution).round();
    final height = (ThirdGenModel._size.height * _resolution).round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(width / _photoBody.width, height / _photoBody.height);
    canvas.translate(-_photoOrigin.dx, -_photoOrigin.dy);
    casing(canvas);

    // Écran dans son cadre noir, posé dans un léger creux.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(303.5, 97.5, 188.5, 154.5), const Radius.circular(5)),
      _hollow(0.3)..strokeWidth = 2.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(305.5, 99.5, 184.5, 150.5), const Radius.circular(3.5)),
      Paint()..color = const Color(0xFF0C1010),
    );
    canvas.drawRect(const Rect.fromLTWH(309, 103, 177, 144), Paint()..color = lcd);

    // Creux des quatre boutons (leur dessus : _ThirdGenButtonPainter).
    for (final x in _buttonXs) {
      canvas.drawCircle(Offset(x, 291), 26.2, _hollow(0.27));
    }

    // Molette : même plastique que le boîtier, cernée d'une rainure.
    const wheel = Offset(399.5, 410);
    canvas.drawCircle(wheel, 88.5, _hollow(0.3));
    canvas.drawCircle(wheel, 86.9, _line(const Color(0xFFA9ADAA), 1.2));
    canvas.drawCircle(wheel, 85.6, _line(const Color(0xFFF6F8F5), 1.1));
    canvas.drawCircle(wheel, 84.4, _line(const Color(0xFFCFD2CF), 0.8));

    // Bouton central, creusé : plus sombre en haut à gauche.
    const center = Offset(399.5, 411);
    canvas.drawCircle(center, 33, _hollow(0.18));
    canvas.drawCircle(
      center,
      31.4,
      Paint()
        ..shader = ui.Gradient.radial(
          center.translate(6.3, 9.4),
          44,
          const [Color(0xFFE4E6E3), Color(0xFFD4D6D3)],
        ),
    );
    canvas.drawCircle(center, 31.4, _line(const Color(0xFFB6BAB7), 1.3));
    canvas.drawCircle(center, 29.7, _line(const Color(0xFFF4F6F3), 1.1));
    final picture = recorder.endRecording();
    final image = picture.toImageSync(width, height);
    picture.dispose();
    return image;
  }

  @override
  bool shouldRepaint(covariant _ThirdGenBodyPainter old) => old.lcd != lcd;
}

/// Filet de lumière en haut de l'écran, par-dessus son contenu.
class _ThirdGenGlassPainter extends CustomPainter {
  const _ThirdGenGlassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _photoBody.width;
    canvas.drawRect(
      Rect.fromLTWH((309 - _photoOrigin.dx) * scale, (103 - _photoOrigin.dy) * scale, 177 * scale, 1.5 * scale),
      Paint()..color = const Color(0xFFDFE6EF).withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Dessus d'un des quatre boutons (photo : 50 px de diamètre) : bombé, cerclé
/// de gris puis d'un liseré clair, inscription rouge, rétroéclairée quand
/// [lit] monte (lueur orangée qui déborde un peu sur la touche).
class _ThirdGenButtonPainter extends CustomPainter {
  const _ThirdGenButtonPainter(this.zone, this.pressed, this.lit);

  final WheelZone zone;
  final bool pressed;
  final double lit;

  static const _red = Color(0xFFDF442D);
  static const _glow = Color(0xFFFF6A3D);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.width / 50);
    canvas.drawCircle(
      Offset.zero,
      25,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(0, -2.5),
          30,
          pressed ? const [Color(0xFFD3D5D2), Color(0xFFCBCDCA)] : const [Color(0xFFE0E2DF), Color(0xFFD6D8D5)],
        ),
    );
    canvas.drawCircle(Offset.zero, 24.7, _line(const Color(0xFFAEB2AF), 1.1));
    canvas.drawCircle(Offset.zero, 23.5, _line(const Color(0xFFF5F7F4).withValues(alpha: pressed ? 0.4 : 1), 1));
    // Lumière diffuse sous la touche, autour de l'inscription.
    if (lit > 0) {
      canvas.drawCircle(
        Offset.zero,
        16,
        Paint()
          ..shader = ui.Gradient.radial(Offset.zero, 16, [
            _glow.withValues(alpha: 0.12 * lit),
            _glow.withValues(alpha: 0),
          ]),
      );
    }
    // Halo flou, puis le trait net, plus vif quand c'est allumé.
    if (lit > 0) {
      _symbol(canvas, Paint()
        ..color = _glow.withValues(alpha: 0.45 * lit)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2));
    }
    _symbol(canvas, Paint()..color = Color.lerp(_red, _glow, lit)!);
    canvas.restore();
  }

  void _symbol(Canvas canvas, Paint ink) {
    if (zone == WheelZone.menu) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'MENU',
          style: TextStyle(fontFamily: 'Noto Sans', fontSize: 9.4, fontWeight: FontWeight.w700, letterSpacing: 0.2, foreground: ink),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, 3.6 - tp.computeDistanceToActualBaseline(TextBaseline.alphabetic)));
      tp.dispose();
    } else {
      canvas.save();
      canvas.translate(0, 0.2);
      canvas.scale(1.15);
      final icon = Path();
      switch (zone) {
        case WheelZone.previous:
          icon
            ..addRect(const Rect.fromLTWH(-6, -3.1, 1.5, 6.2))
            ..addPolygon(const [Offset(-4.4, 0), Offset(-0.2, -3.1), Offset(-0.2, 3.1)], true)
            ..addPolygon(const [Offset(-0.2, 0), Offset(4, -3.1), Offset(4, 3.1)], true);
        case WheelZone.next:
          icon
            ..addPolygon(const [Offset(-4, -3.1), Offset(0.2, 0), Offset(-4, 3.1)], true)
            ..addPolygon(const [Offset(0.2, -3.1), Offset(4.4, 0), Offset(0.2, 3.1)], true)
            ..addRect(const Rect.fromLTWH(4.5, -3.1, 1.5, 6.2));
        case WheelZone.playPause:
          icon
            ..addPolygon(const [Offset(-6.2, -3.3), Offset(-0.4, 0), Offset(-6.2, 3.3)], true)
            ..addRect(const Rect.fromLTWH(1.3, -3.1, 1.6, 6.2))
            ..addRect(const Rect.fromLTWH(4.4, -3.1, 1.6, 6.2));
        case WheelZone.menu || WheelZone.center || WheelZone.none:
          break;
      }
      canvas.drawPath(icon, ink);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ThirdGenButtonPainter old) =>
      old.pressed != pressed || old.zone != zone || old.lit != lit;
}

// --- 1re et 2e générations -------------------------------------------------------
//
// Dessinées en pixels de la photo de référence (coin du plexi en 57, 161),
// puis mises à l'échelle.

const _gen1Origin = Offset(57, 161);
const _gen1Plexi = Rect.fromLTWH(57, 161, 274, 462);
const _gen1Face = Rect.fromLTWH(64, 170, 261, 443);
const _gen1Lcd = Rect.fromLTWH(109.5, 190, 173, 139.5);
const _gen1Wheel = Offset(195, 471);

/// Tout ce qui ne bouge pas : plexi, façade, cadre de l'écran, anneau des
/// boutons et ses inscriptions, disque, bouton central.
class _FirstGenBodyPainter extends CustomPainter {
  const _FirstGenBodyPainter(this.lcd);

  final Color lcd;

  /// Rendu une fois en image, comme le boîtier du 3G (voir
  /// [_ThirdGenBodyPainter]) ; partagé par la 1re et la 2e génération.
  /// shortcut: image à 3 × la taille de base, un peu floue au-delà (plein écran sur un écran 5K) ; la rendre à la taille affichée si ça se voit.
  static ui.Image? _image;
  static Color? _imageLcd;
  static const _resolution = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(27 * size.width / _gen1Plexi.width));
    // Le plexi est transparent : l'ombre portée ne passe pas dessous.
    canvas.save();
    canvas.clipPath(Path()
      ..fillType = PathFillType.evenOdd
      ..addRect((Offset.zero & size).inflate(200))
      ..addRRect(outer));
    paintFloatShadow(canvas, outer, drop: 26, blur: 30);
    canvas.restore();
    if (_image == null || _imageLcd != lcd) {
      _image?.dispose();
      _image = _render();
      _imageLcd = lcd;
    }
    final image = _image!;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  ui.Image _render() {
    final width = (FirstGenModel._size.width * _resolution).round();
    final height = (FirstGenModel._size.height * _resolution).round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(width / _gen1Plexi.width, height / _gen1Plexi.height);
    canvas.translate(-_gen1Origin.dx, -_gen1Origin.dy);

    // Plexi transparent qui déborde de la façade, un peu laiteux, et sa
    // tranche du bas et de droite dans l'ombre.
    final plexi = RRect.fromRectAndRadius(_gen1Plexi, const Radius.circular(27));
    canvas.drawRRect(
      plexi,
      Paint()
        ..shader = ui.Gradient.linear(const Offset(0, 161), const Offset(0, 623), [
          const Color(0xFFF4F1EC).withValues(alpha: 0.55),
          const Color(0xFFE8E4DE).withValues(alpha: 0.3),
          const Color(0xFFD8D2CA).withValues(alpha: 0.25),
        ], const [0, 0.5, 1]),
    );
    canvas.save();
    canvas.clipRRect(plexi);
    canvas.drawRRect(
      plexi.shift(const Offset(2, 3)),
      _line(const Color(0xFF5C554B).withValues(alpha: 0.35), 6)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(57.6, 161.6, 272.8, 460.8), const Radius.circular(26.4)),
      _line(const Color(0xFFF3F0EA).withValues(alpha: 0.6), 1.2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(59.5, 163.5, 269, 457), const Radius.circular(24.5)),
      _line(const Color(0xFF8D867C).withValues(alpha: 0.3), 1),
    );

    // Façade blanche, plus sombre en bas, ombrée le long des bords sous le plexi.
    final face = RRect.fromRectAndRadius(_gen1Face, const Radius.circular(19));
    canvas.drawRRect(
      face,
      Paint()
        ..shader = ui.Gradient.linear(const Offset(0, 170), const Offset(0, 613), const [
          Color(0xFFEBE8E2), Color(0xFFE9E6E0), Color(0xFFE2DED7), Color(0xFFCDC7BE),
        ], const [0, 0.5, 0.86, 1]),
    );
    canvas.drawRRect(
      face,
      Paint()
        ..shader = ui.Gradient.linear(const Offset(64, 0), const Offset(325, 0), [
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0),
          Colors.black.withValues(alpha: 0),
          Colors.black.withValues(alpha: 0.04),
        ], const [0, 0.12, 0.85, 1]),
    );
    canvas.save();
    canvas.clipRRect(face);
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(_gen1Face.inflate(20))
        ..addRRect(face),
      Paint()
        ..color = const Color(0xFF4A463F).withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
    );
    canvas.restore();
    canvas.drawRRect(face.inflate(0.5), _line(const Color(0xFF6F695F).withValues(alpha: 0.6), 1.2));

    // Écran en retrait : le cadre sombre laisse voir sa paroi du haut.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(103.5, 182.5, 185, 151), const Radius.circular(5)),
      _line(const Color(0xFF6D675D).withValues(alpha: 0.3), 2.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(105, 184, 182, 148), const Radius.circular(4)),
      Paint()..color = const Color(0xFF3F3C36),
    );
    canvas.drawRect(_gen1Lcd, Paint()..color = lcd);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(105, 184, 182, 6), const Radius.circular(3)),
      Paint()..color = const Color(0xFF2F2C27),
    );

    // Molette, réduite à 97 % autour de son centre.
    canvas.translate(_gen1Wheel.dx, _gen1Wheel.dy);
    canvas.scale(0.97);
    // Anneau des quatre boutons : ombre sur la façade, bord gris, bombé.
    canvas.drawCircle(
      const Offset(1, 1.5),
      121,
      _line(const Color(0xFF5F594F).withValues(alpha: 0.38), 3.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4),
    );
    canvas.drawCircle(
      Offset.zero,
      120,
      Paint()
        ..shader = ui.Gradient.linear(const Offset(0, -120), const Offset(0, 120), const [
          Color(0xFFF3F1EC), Color(0xFFEFECE7), Color(0xFFDDD7CF),
        ], const [0, 0.55, 1]),
    );
    canvas.drawCircle(Offset.zero, 119.6, _line(const Color(0xFF8A847A).withValues(alpha: 0.8), 1));
    canvas.drawCircle(
      Offset.zero,
      107,
      _line(Colors.black, 26)
        ..shader = ui.Gradient.radial(Offset.zero, 120, [
          const Color(0xFF7A746A).withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.2),
          const Color(0xFF7A746A).withValues(alpha: 0.22),
        ], const [0.78, 0.84, 0.92, 1]),
    );
    // Fentes en diagonale entre les boutons : un trait sombre, un filet clair.
    for (final (dx, dy) in const [(-1.0, -1.0), (1.0, -1.0), (-1.0, 1.0), (1.0, 1.0)]) {
      canvas.drawLine(Offset(67.2 * dx, 67.2 * dy), Offset(84 * dx, 84 * dy), _line(const Color(0xFF3A362F), 1.2));
      canvas.drawLine(
        Offset(67.2 * dx + 0.8, 67.2 * dy + 0.8),
        Offset(84 * dx + 0.8, 84 * dy + 0.8),
        _line(const Color(0xFFFBFAF7).withValues(alpha: 0.45), 0.7),
      );
    }
    const ink = Color(0xFF98948B);
    final menu = TextPainter(
      text: const TextSpan(
        text: 'menu',
        style: TextStyle(fontFamily: 'Noto Sans', fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: ink),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    menu.paint(canvas, Offset(-menu.width / 2, -101.5 - menu.computeDistanceToActualBaseline(TextBaseline.alphabetic)));
    menu.dispose();
    canvas.drawPath(
      Path()
        // ⏮
        ..addRect(const Rect.fromLTWH(-113.2, -3.1, 1.6, 7.2))
        ..addPolygon(const [Offset(-111.4, 0.5), Offset(-106.8, -3.1), Offset(-106.8, 4.1)], true)
        ..addPolygon(const [Offset(-106.9, 0.5), Offset(-102.3, -3.1), Offset(-102.3, 4.1)], true)
        // ⏭
        ..addPolygon(const [Offset(102.3, -3.1), Offset(106.9, 0.5), Offset(102.3, 4.1)], true)
        ..addPolygon(const [Offset(106.9, -3.1), Offset(111.5, 0.5), Offset(106.9, 4.1)], true)
        ..addRect(const Rect.fromLTWH(111.6, -3.1, 1.6, 7.2))
        // ⏯
        ..addPolygon(const [Offset(-6.6, 102.2), Offset(-0.4, 106), Offset(-6.6, 109.8)], true)
        ..addRect(const Rect.fromLTWH(1.4, 102.4, 1.7, 7.2))
        ..addRect(const Rect.fromLTWH(4.7, 102.4, 1.7, 7.2)),
      Paint()..color = ink,
    );
    // Disque qui tourne, cerné d'une rainure sombre.
    canvas.drawCircle(
      Offset.zero,
      94,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(0, -31), 120, const [Color(0xFFE5E2DC), Color(0xFFDBD7CF)]),
    );
    canvas.drawCircle(Offset.zero, 94, _line(const Color(0xFF3E3A33), 1.3));
    canvas.drawCircle(Offset.zero, 92.8, _line(const Color(0xFFF6F3EE).withValues(alpha: 0.55), 0.9));
    // Bouton central.
    const center = Offset(0, -1);
    canvas.drawCircle(
      center,
      33.5,
      Paint()..shader = ui.Gradient.radial(const Offset(0, -11), 40, const [Color(0xFFF1EEE9), Color(0xFFE7E3DC)]),
    );
    canvas.drawCircle(center, 33.5, _line(const Color(0xFF4A463F), 1.1));
    canvas.drawCircle(center, 32.4, _line(const Color(0xFFFBFAF7).withValues(alpha: 0.7), 0.9));

    final picture = recorder.endRecording();
    final image = picture.toImageSync(width, height);
    picture.dispose();
    return image;
  }

  @override
  bool shouldRepaint(covariant _FirstGenBodyPainter old) => old.lcd != lcd;
}

/// Reflet du plexi en haut de l'écran, par-dessus son contenu.
class _FirstGenGlassPainter extends CustomPainter {
  const _FirstGenGlassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _gen1Plexi.width;
    canvas.drawRect(
      Rect.fromLTWH((_gen1Lcd.left - _gen1Origin.dx) * scale, (_gen1Lcd.top - _gen1Origin.dy) * scale, _gen1Lcd.width * scale, 1.2 * scale),
      Paint()..color = const Color(0xFFE6E0CC).withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// --- Boîtier du 3G sur la 4e génération et le Photo --------------------------

/// Le boîtier du 3G ([_ThirdGenBodyPainter.casing]) à la taille de l'appareil,
/// avec son écran dans un cadre noir et le léger creux de la molette (la
/// molette elle-même : [WheelPainter]).
class _CasingBodyPainter extends CustomPainter {
  const _CasingBodyPainter(this.bodySize, this.screen, this.lcd, this.wheelCenter, this.wheelRadius, {this.dark = false});

  /// Façade en plastique noir (U2).
  final bool dark;

  final Size bodySize;
  final Rect screen;
  final Color lcd;
  final Offset wheelCenter;
  final double wheelRadius;

  /// Rendu une fois en image par appareil, comme le boîtier du 3G.
  /// shortcut: image à 3 × la taille de base, un peu floue au-delà (plein écran sur un écran 5K) ; la rendre à la taille affichée si ça se voit.
  static final _images = <(Size, Rect, Color, bool), ui.Image>{};
  static const _resolution = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    paintFloatShadow(
      canvas,
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(30 * size.width / _photoBody.width)),
      drop: 26,
      blur: 30,
    );
    final image = _images[(bodySize, screen, lcd, dark)] ??= _render();
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  ui.Image _render() {
    final width = (bodySize.width * _resolution).round();
    final height = (bodySize.height * _resolution).round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(width / _photoBody.width, height / _photoBody.height);
    canvas.translate(-_photoOrigin.dx, -_photoOrigin.dy);
    _ThirdGenBodyPainter.casing(canvas, dark: dark);
    // Creux : gris sur le plastique blanc, noir sur le noir.
    Paint hollow(double alpha) => dark ? (_hollow(1)..color = Colors.black.withValues(alpha: 0.6)) : _hollow(alpha);

    // Repère de l'appareil → pixels de la photo.
    final kx = bodySize.width / _photoBody.width, ky = bodySize.height / _photoBody.height;
    final lcdRect = Rect.fromLTWH(
      _photoOrigin.dx + screen.left / kx,
      _photoOrigin.dy + screen.top / ky,
      screen.width / kx,
      screen.height / ky,
    );
    // Écran dans son cadre noir, posé dans un léger creux (comme le 3G).
    canvas.drawRRect(RRect.fromRectAndRadius(lcdRect.inflate(5.5), const Radius.circular(5)), hollow(0.3)..strokeWidth = 2.5);
    canvas.drawRRect(RRect.fromRectAndRadius(lcdRect.inflate(3.5), const Radius.circular(3.5)), Paint()..color = const Color(0xFF0C1010));
    canvas.drawRect(lcdRect, Paint()..color = lcd);
    // Creux autour de la molette.
    final wheel = Offset(_photoOrigin.dx + wheelCenter.dx / kx, _photoOrigin.dy + wheelCenter.dy / ky);
    canvas.drawCircle(wheel, (wheelRadius + 1.5) / kx + 1, hollow(0.3));

    final picture = recorder.endRecording();
    final image = picture.toImageSync(width, height);
    picture.dispose();
    return image;
  }

  @override
  bool shouldRepaint(covariant _CasingBodyPainter old) =>
      old.bodySize != bodySize || old.screen != screen || old.lcd != lcd || old.wheelCenter != wheelCenter || old.dark != dark;
}

/// Filet de lumière en haut de l'écran, par-dessus son contenu (comme le 3G).
class _CasingGlassPainter extends CustomPainter {
  const _CasingGlassPainter(this.bodySize, this.screen);

  final Size bodySize;
  final Rect screen;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / bodySize.width;
    canvas.drawRect(
      Rect.fromLTWH(screen.left * k, screen.top * k, screen.width * k, 1.5 * size.height / _photoBody.height),
      Paint()..color = const Color(0xFFDFE6EF).withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _CasingGlassPainter old) => old.screen != screen || old.bodySize != bodySize;
}

// --- Nano de 1re génération, blanc ---------------------------------------------
//
// Dessiné en pixels de la photo de référence redressée (coin de l'acrylique
// en 209, 98), puis mis à l'échelle.

const _nano1Origin = Offset(209, 98);
const _nano1Plexi = Rect.fromLTWH(209, 98, 224, 498);
const _nano1Face = Rect.fromLTWH(212.5, 101.5, 217, 491);
const _nano1Lcd = Rect.fromLTWH(240, 130.5, 164.5, 125);

/// Liseré d'acrylique transparent, façade blanche, cadre de l'écran, molette
/// grise et ses inscriptions, bouton central : rien n'y bouge.
class _Nano1BodyPainter extends CustomPainter {
  const _Nano1BodyPainter(this.lcd);

  final Color lcd;

  /// Rendu une fois en image, comme le boîtier du 3G.
  /// shortcut: image à 3 × la taille de base, un peu floue au-delà (plein écran sur un écran 5K) ; la rendre à la taille affichée si ça se voit.
  static ui.Image? _image;
  static Color? _imageLcd;
  static const _resolution = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(16 * size.width / _nano1Plexi.width));
    // L'acrylique est transparent : l'ombre portée ne passe pas dessous.
    canvas.save();
    canvas.clipPath(Path()
      ..fillType = PathFillType.evenOdd
      ..addRect((Offset.zero & size).inflate(200))
      ..addRRect(outer));
    paintFloatShadow(canvas, outer, drop: 22, blur: 24);
    canvas.restore();
    if (_image == null || _imageLcd != lcd) {
      _image?.dispose();
      _image = _render();
      _imageLcd = lcd;
    }
    final image = _image!;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  ui.Image _render() {
    final width = (Nano1Model._size.width * _resolution).round();
    final height = (Nano1Model._size.height * _resolution).round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(width / _nano1Plexi.width, height / _nano1Plexi.height);
    canvas.translate(-_nano1Origin.dx, -_nano1Origin.dy);

    // Liseré d'acrylique : un peu laiteux, tranche du bas et de droite dans l'ombre.
    final plexi = RRect.fromRectAndRadius(_nano1Plexi, const Radius.circular(16));
    canvas.drawRRect(
      plexi,
      Paint()
        ..shader = ui.Gradient.linear(const Offset(0, 98), const Offset(0, 596), [
          const Color(0xFFF6F7F8).withValues(alpha: 0.6),
          const Color(0xFFE9EBED).withValues(alpha: 0.4),
          const Color(0xFFD6D9DC).withValues(alpha: 0.4),
        ], const [0, 0.5, 1]),
    );
    canvas.save();
    canvas.clipRRect(plexi);
    canvas.drawRRect(
      plexi.shift(const Offset(1.5, 2)),
      _line(const Color(0xFF4F565C).withValues(alpha: 0.35), 4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(209.5, 98.5, 223, 497), const Radius.circular(15.5)),
      _line(const Color(0xFFF5F6F7).withValues(alpha: 0.65), 1),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(211, 100, 220, 494), const Radius.circular(14)),
      _line(const Color(0xFF7D848A).withValues(alpha: 0.3), 0.8),
    );

    // Façade blanche, ombrée le long des bords sous l'acrylique.
    final face = RRect.fromRectAndRadius(_nano1Face, const Radius.circular(12.5));
    canvas.drawRRect(
      face,
      Paint()
        ..shader = ui.Gradient.linear(const Offset(0, 101), const Offset(0, 592), const [
          Color(0xFFF2F3F2), Color(0xFFEEEFEE), Color(0xFFE2E4E4),
        ], const [0, 0.55, 1]),
    );
    canvas.drawRRect(
      face,
      Paint()
        ..shader = ui.Gradient.linear(const Offset(212, 0), const Offset(430, 0), [
          Colors.white.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0),
          Colors.black.withValues(alpha: 0),
          Colors.black.withValues(alpha: 0.05),
        ], const [0, 0.1, 0.88, 1]),
    );
    canvas.save();
    canvas.clipRRect(face);
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(_nano1Face.inflate(20))
        ..addRRect(face),
      Paint()
        ..color = const Color(0xFF3F454B).withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8),
    );
    canvas.restore();
    canvas.drawRRect(face.inflate(0.5), _line(const Color(0xFF6C737A).withValues(alpha: 0.5), 1));

    // Écran dans son cadre noir.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(234, 124, 177, 136), const Radius.circular(5)),
      Paint()..color = const Color(0xFF141517),
    );
    canvas.drawRect(_nano1Lcd, Paint()..color = lcd);

    // Molette : disque gris à fleur de façade, inscriptions blanches.
    const c = Offset(321, 426);
    canvas.drawCircle(
      c,
      85,
      _line(const Color(0xFF5E656B).withValues(alpha: 0.18), 2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );
    canvas.drawCircle(
      c,
      84,
      Paint()..shader = ui.Gradient.radial(const Offset(321, 400), 110, const [Color(0xFFC4C6C9), Color(0xFFB8BBBE)]),
    );
    canvas.drawCircle(c, 83.6, _line(const Color(0xFFA6A9AD).withValues(alpha: 0.7), 0.8));
    const ink = Color(0xFFFBFBFB);
    final menu = TextPainter(
      text: const TextSpan(
        text: 'MENU',
        style: TextStyle(fontFamily: 'Noto Sans', fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: ink),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    menu.paint(canvas, Offset(321 - menu.width / 2, 364 - menu.computeDistanceToActualBaseline(TextBaseline.alphabetic)));
    menu.dispose();
    canvas.drawPath(
      Path()
        // ⏮
        ..addRect(const Rect.fromLTWH(247.8, 422, 2, 10))
        ..addPolygon(const [Offset(250, 427), Offset(256.2, 422), Offset(256.2, 432)], true)
        ..addPolygon(const [Offset(256, 427), Offset(262.2, 422), Offset(262.2, 432)], true)
        // ⏭
        ..addPolygon(const [Offset(379.8, 422), Offset(386, 427), Offset(379.8, 432)], true)
        ..addPolygon(const [Offset(386, 422), Offset(392.2, 427), Offset(386, 432)], true)
        ..addRect(const Rect.fromLTWH(392.2, 422, 2, 10))
        // ⏯
        ..addPolygon(const [Offset(312.5, 488.8), Offset(320.5, 494), Offset(312.5, 499.2)], true)
        ..addRect(const Rect.fromLTWH(323, 489, 2.4, 10))
        ..addRect(const Rect.fromLTWH(327.4, 489, 2.4, 10)),
      Paint()..color = ink,
    );
    // Bouton central blanc.
    canvas.drawCircle(
      c,
      37,
      Paint()..shader = ui.Gradient.radial(const Offset(321, 412), 44, const [Color(0xFFF8F8F7), Color(0xFFEFEFEE)]),
    );
    canvas.drawCircle(c, 36.6, _line(const Color(0xFFB3B6B9).withValues(alpha: 0.8), 0.8));

    final picture = recorder.endRecording();
    final image = picture.toImageSync(width, height);
    picture.dispose();
    return image;
  }

  @override
  bool shouldRepaint(covariant _Nano1BodyPainter old) => old.lcd != lcd;
}

/// Par-dessus l'écran : filet de lumière en haut de l'écran et très léger
/// reflet en biais de l'acrylique sur toute la façade.
class _Nano1GlassPainter extends CustomPainter {
  const _Nano1GlassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _nano1Plexi.width, size.height / _nano1Plexi.height);
    canvas.translate(-_nano1Origin.dx, -_nano1Origin.dy);
    canvas.drawRect(
      Rect.fromLTWH(_nano1Lcd.left, _nano1Lcd.top, _nano1Lcd.width, 1.2),
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(_nano1Face, const Radius.circular(12.5)),
      Paint()
        ..shader = ui.Gradient.linear(const Offset(209, 98), const Offset(433, 380), [
          Colors.white.withValues(alpha: 0.22),
          Colors.white.withValues(alpha: 0.06),
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0),
        ], const [0, 0.45, 0.46, 1]),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
