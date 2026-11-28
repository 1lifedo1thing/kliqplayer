import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Le petit « tic » de la molette, joué par le haut-parleur de l'appareil
/// (indépendant du volume de la musique). Le son est synthétisé au
/// démarrage : un claquement bref et sec, pas d'échantillon à fournir.
class WheelClick {
  WheelClick._();

  static final WheelClick instance = WheelClick._();

  /// Tonalités proposées (Réglages › Tonalité du clic) : facteur appliqué
  /// aux fréquences du claquement, de « Très grave » à « Très aiguë ».
  static const pitches = [0.8, 0.9, 1.0, 1.12, 1.25];
  static const pitchNames = ['Très grave', 'Grave', 'Normale', 'Aiguë', 'Très aiguë'];

  /// Un son par tonalité, synthétisés d'un coup (quelques Ko chacun).
  List<AudioSource>? _sources;

  /// Le « tac » du verrou qu'on pousse.
  AudioSource? _holdSource;
  Future<void>? _loading;

  /// Tonalité choisie (index dans [pitches]).
  int pitch = 2;

  /// Tonalité écoutée en parcourant le menu Tonalité du clic, à la place
  /// de [pitch] (null hors de ce menu).
  int? preview;

  /// Volume du clic, de 0 à 1.
  double volume = 0.55;

  /// Réglages › Clic : sans, la molette tourne en silence.
  bool enabled = true;

  Future<void> _load() async {
    final soloud = SoLoud.instance;
    await ensureSoloud();
    _sources = [
      for (var i = 0; i < pitches.length; i++)
        await soloud.loadMem('wheel-click-$i.wav', _synthesize(pitches[i])),
    ];
    _holdSource = await soloud.loadMem('hold-tack.wav', _synthesizeTack());
  }

  /// Le verrou poussé : un « tac », joué même quand le clic de la molette
  /// est coupé (c'est un bruit mécanique, comme la prise).
  void hold() {
    final source = _holdSource;
    if (source == null) {
      warmUp();
      return;
    }
    SoLoud.instance.play(source, volume: volume);
  }

  /// Joue le clic ; sans effet (et sans erreur) si l'audio n'est pas prêt.
  /// [force] : un bruit mécanique (la prise qui s'enfiche), joué même quand
  /// le clic de la molette est coupé.
  void play({bool force = false}) {
    if (!enabled && !force) return;
    final sources = _sources;
    if (sources == null) {
      _loading ??= _load().catchError((Object e) {
        debugPrint('Clic de la molette indisponible : $e');
      });
      return;
    }
    SoLoud.instance.play(sources[(preview ?? pitch).clamp(0, sources.length - 1)], volume: volume);
  }

  /// Précharge le son pour que le premier clic ne soit pas muet.
  void warmUp() => _loading ??= _load().catchError((Object e) {
        debugPrint('Clic de la molette indisponible : $e');
      });

  /// WAV mono 16 bits : souffle très bref (le contact) suivi d'une petite
  /// résonance aiguë qui s'éteint en quelques millisecondes (le boîtier).
  /// [pitch] décale les résonances (et raccourcit d'autant leur traîne).
  static Uint8List _synthesize(double pitch) {
    const rate = 44100;
    const n = rate * 18 ~/ 1000; // 18 ms
    final rnd = math.Random(7);
    final samples = Int16List(n);
    var lp = 0.0;
    for (var i = 0; i < n; i++) {
      final t = i / rate;
      final noise = rnd.nextDouble() * 2 - 1;
      lp += (noise - lp) * 0.55; // adoucit un peu le souffle
      final contact = lp * math.exp(-t / 0.0006);
      final ring = math.sin(2 * math.pi * 3100 * pitch * t) * math.exp(-t * pitch / 0.0016);
      final body = math.sin(2 * math.pi * 1250 * pitch * t) * math.exp(-t * pitch / 0.0030);
      final attack = math.min(1.0, i / 6); // évite un pop au tout début
      final v = attack * (0.75 * contact + 0.45 * ring + 0.22 * body);
      samples[i] = (v.clamp(-1.0, 1.0) * 32767).round();
    }

    return wav(samples, rate);
  }

  /// WAV mono 16 bits : un « tac » de plastique, sec et assez mat. Un choc
  /// (souffle filtré, dans les médiums) et la petite résonance du curseur
  /// qui bute au bout de sa fente, éteints en une vingtaine de millisecondes.
  static Uint8List _synthesizeTack() {
    const rate = 44100;
    const n = rate * 25 ~/ 1000; // 25 ms
    final rnd = math.Random(3);
    final samples = Int16List(n);
    var lp = 0.0, lp2 = 0.0;
    for (var i = 0; i < n; i++) {
      final t = i / rate;
      final noise = rnd.nextDouble() * 2 - 1;
      // Filtré deux fois : le choc reste dans les médiums, sans grésillement.
      lp += (noise - lp) * 0.38;
      lp2 += (lp - lp2) * 0.38;
      final knock = lp2 * 2.2 * math.exp(-t / 0.0018);
      // Résonance du boîtier, dont la hauteur tombe un peu : « tac », pas « tic ».
      final f = 820 + 380 * math.exp(-t / 0.003);
      final body = math.sin(2 * math.pi * f * t) * math.exp(-t / 0.0045);
      final click = math.sin(2 * math.pi * 1900 * t) * math.exp(-t / 0.0010);
      final attack = math.min(1.0, i / 8);
      final v = attack * (0.6 * knock + 0.55 * body + 0.3 * click);
      samples[i] = (v.clamp(-1.0, 1.0) * 32767).round();
    }
    return wav(samples, rate);
  }
}

Future<void>? _soloudInit;

/// Démarre le moteur audio des bruitages une seule fois, quel que soit le
/// son qui le demande en premier.
Future<void> ensureSoloud() => _soloudInit ??= () async {
      final soloud = SoLoud.instance;
      // Petit tampon : le clic doit partir sans délai perceptible.
      if (!soloud.isInitialized) await soloud.init(bufferSize: 512);
    }();

/// Emballe des échantillons mono 16 bits dans un fichier WAV.
Uint8List wav(Int16List samples, int rate) {
  final data = samples.buffer.asUint8List();
  final header = ByteData(44)
    ..setUint32(0, 0x52494646) // RIFF
    ..setUint32(4, 36 + data.length, Endian.little)
    ..setUint32(8, 0x57415645) // WAVE
    ..setUint32(12, 0x666d7420) // fmt
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little) // PCM
    ..setUint16(22, 1, Endian.little) // mono
    ..setUint32(24, rate, Endian.little)
    ..setUint32(28, rate * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little)
    ..setUint32(36, 0x64617461) // data
    ..setUint32(40, data.length, Endian.little);
  return Uint8List.fromList([...header.buffer.asUint8List(), ...data]);
}
