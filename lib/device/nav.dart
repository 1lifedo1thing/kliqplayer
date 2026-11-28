import 'dart:io';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/cover_color.dart';
import '../core/library.dart';
import '../core/player.dart';
import '../core/settings.dart';
import '../core/source.dart';
import '../core/paths.dart';
import '../core/strings.dart';
import '../core/version.dart';
import '../physics.dart';
import 'click.dart';
import 'look.dart';

sealed class DevicePage {
  String get title;
}

/// Ce que montre la moitié « image » d'un menu scindé (Classic, nano 3G
/// et 4G) quand la ligne est sélectionnée.
/// La fenêtre reste par-dessus les autres (Réglages › Premier plan, sous
/// Windows) ; la scène l'applique.
final windowOnTop = ValueNotifier(Settings.getString('window.top') == 'on');

/// Le baladeur reste là où on le lâche à l'écran, au lieu de revenir à sa place
/// à gauche, au milieu ou à droite (Réglages › Position, sous Windows).
final deviceFree = ValueNotifier(Settings.getString('window.free') == 'on');

enum MenuPreview { covers, settings, nowPlaying }

/// Mise en page d'un menu : lignes simples ; scindé (le menu d'un côté,
/// une image de l'autre, sur les écrans qui le font) ; ou lignes hautes
/// (albums avec leur vignette et l'artiste dessous).
enum MenuKind { normal, split, tall }

class MenuEntry {
  const MenuEntry(this.label,
      {this.open, this.action, this.value, this.checked, this.subtitle, this.art, this.preview = MenuPreview.covers});

  final String label;

  /// Seconde ligne (l'artiste d'un album), sur les lignes hautes.
  final String? subtitle;

  /// Vignette (la pochette d'un album), sur les lignes hautes : null tant
  /// qu'elle n'est pas lue.
  final Uint8List? Function()? art;

  /// Image d'un menu scindé pour cette ligne.
  final MenuPreview preview;

  /// Valeur affichée à droite (Réglages : « Non », « Tous »…), relue à
  /// chaque affichage.
  final String Function()? value;

  /// Coche à droite (choix en cours dans une liste d'options).
  final bool Function()? checked;

  /// Ouvre un sous-menu (affiche un chevron).
  final DevicePage Function()? open;

  /// Action immédiate (lancer un morceau…).
  final VoidCallback? action;
}

class MenuPage extends DevicePage {
  MenuPage(this.title, List<MenuEntry> Function() builder,
      {this.live = false, this.music = false, this.welcome = false, this.kind = MenuKind.normal})
      : _builder = builder;

  final MenuKind kind;

  @override
  final String title;
  final List<MenuEntry> Function() _builder;

  /// Reconstruit ses entrées à chaque affichage (menu principal).
  final bool live;

  /// Montre des albums ou des morceaux de la bibliothèque : ne vaut plus
  /// rien quand elle change.
  final bool music;

  /// Page de l'accueil du premier lancement : dessinée à part (grands
  /// boutons, comme le site), cliquable à la souris.
  final bool welcome;
  List<MenuEntry>? _cache;

  List<MenuEntry> get entries {
    if (!live) return _cache ??= _builder();
    final list = _builder();
    // Une ligne a disparu (message effacé, compte déconnecté) : la sélection
    // reste dans le menu.
    if (selected >= list.length) selected = math.max(0, list.length - 1);
    if (top > selected) top = selected;
    return list;
  }

  int selected = 0;
  int top = 0;

  // Positions animées, en lignes.
  final selSpring = Spring(0, stiffness: 1400, damping: 1);
  final topSpring = Spring(0, stiffness: 900, damping: 1);
}

/// Les pochettes des albums en enfilade : celle du milieu de face, les
/// autres de biais de chaque côté (Classic, nano 3G et 4G). Ou, avec
/// [lists], celles des listes de lecture (Musique › Listes de lecture).
class CoverFlowPage extends DevicePage {
  CoverFlowPage(this.selected, {this.lists}) : pos = Spring(selected.toDouble(), stiffness: 210, damping: 0.92);

  /// Les listes de lecture montrées à la place des albums.
  final List<SongList>? lists;

  @override
  String get title => lists == null ? 'Cover Flow' : tr('Listes de lecture');

  int count(PlayerController player) => lists?.length ?? player.albums.length;

  /// Les deux lignes sous la pochette [i] : album et artiste, ou liste et
  /// nombre de morceaux (une fois chargée).
  (String, String) label(PlayerController player, int i) {
    if (lists case final lists?) {
      final n = lists[i].tracks?.length;
      return (lists[i].name, n == null ? '' : '$n ${tr(n == 1 ? 'morceau' : 'morceaux')}');
    }
    return (player.albums[i].title, player.albums[i].artist);
  }

  /// Les morceaux au dos de la pochette [i] ; null tant qu'une liste n'est
  /// pas chargée (ou ne peut pas l'être).
  List<Track>? tracks(PlayerController player, int i) {
    if (lists case final lists?) return lists[i].tracks;
    final a = player.albums[i];
    return player.tracks.sublist(a.firstIndex, a.firstIndex + a.trackCount);
  }

  List<Uint8List> covers(PlayerController player, int i) =>
      lists == null ? [?player.albumCover(i)] : player.listCovers(lists![i]);

  /// Album (ou liste) au centre.
  int selected;

  // --- Défilement rapide : par lettre -----------------------------------------
  // À force de tourner la molette sans s'arrêter dans les albums (rangés
  // par artiste), chaque cran saute à la lettre suivante, affichée en
  // grand ; un instant sans tourner et on revient au défilement normal.

  /// Crans d'affilée (même sens, sans pause) avant de passer aux lettres.
  static const lettersAfter = 30;
  static const _pause = Duration(milliseconds: 350);
  static const _lettersHold = Duration(milliseconds: 1200);

  int _run = 0, _runSign = 0;
  DateTime _lastScroll = DateTime(0), _lettersUntil = DateTime(0);

  /// La molette saute de lettre en lettre.
  bool get letters => clock.now().isBefore(_lettersUntil);

  /// Apparition de la lettre : 0 cachée, 1 affichée.
  final letterSpring = Spring(0, stiffness: 600, damping: 1);

  /// Initiale de l'artiste de l'album [i] ; « # » pour un chiffre ou un signe.
  String letter(PlayerController player, int i) {
    final name = player.albums[i].artist.trim();
    final c = name.isEmpty ? '#' : name[0].toUpperCase();
    return c == c.toLowerCase() ? '#' : c;
  }

  /// Un cran de molette de plus dans le sens [sign] : dit s'il se compte en
  /// lettres. (Pas pour les listes de lecture : elles ne sont pas rangées.)
  bool _byLetter(int sign) {
    final now = clock.now();
    _run = sign == _runSign && now.difference(_lastScroll) < _pause ? _run + 1 : 1;
    _runSign = sign;
    _lastScroll = now;
    if (lists != null || !(letters || _run > lettersAfter)) return false;
    _lettersUntil = now.add(_lettersHold);
    return true;
  }

  /// L'album où mène un saut de lettre depuis [selected] : le premier de la
  /// lettre suivante, ou (en arrière) le premier de la lettre d'avant, ou de
  /// la sienne si on était au milieu.
  int _letterJump(PlayerController player, int sign) {
    final count = player.albums.length;
    var i = selected;
    if (sign > 0) {
      final from = letter(player, i);
      while (i < count - 1 && letter(player, i) == from) {
        i++;
      }
      return letter(player, i) == from ? selected : i; // (dernière lettre : on ne bouge pas)
    }
    if (i == 0) return 0;
    final to = letter(player, i - 1);
    while (i > 0 && letter(player, i - 1) == to) {
      i--;
    }
    return i;
  }

  /// Position animée, en albums.
  final Spring pos;

  // --- Pochette retournée : la liste des morceaux de l'album au dos -----------

  /// Lignes de morceaux visibles au dos.
  static const backRows = 6;

  /// L'album du milieu est retourné (valider le retourne, MENU le remet).
  bool flipped = false;

  /// Retournement animé : 0 de face, 1 de dos.
  final flip = Spring(0, stiffness: 120, damping: 0.86);

  /// Morceau sélectionné au dos (rang dans l'album) et première ligne
  /// visible.
  int track = 0;
  int trackTop = 0;
  final trackSpring = Spring(0, stiffness: 1400, damping: 1);
  final trackTopSpring = Spring(0, stiffness: 900, damping: 1);
}

/// Ce que montre le bas de l'écran « En lecture ». Le bouton central fait
/// passer de l'un à l'autre, selon le modèle ([ScreenLook.centerCycle]) :
/// recherche dans le morceau, note en étoiles, pochette en grand, lecture
/// aléatoire.
enum NowPlayingMode { progress, volume, scrub, rating, art, shuffle }

/// La recherche (Musique › Recherche) : une réglette de lettres parcourue
/// à la molette, le bouton central ajoute la lettre ; les morceaux trouvés
/// s'affichent au-dessus, « OK » ouvre leur liste.
class SearchPage extends DevicePage {
  @override
  String get title => tr('Recherche');

  static const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  /// Cases après les lettres : espace, effacer, terminer.
  static const space = 36, delete = 37, done = 38, cells = 39;

  static String cellLabel(int i) => switch (i) {
        space => '␣',
        delete => '⌫',
        done => 'OK',
        _ => letters[i],
      };

  String query = '';
  int cell = 0;
  final cellSpring = Spring(0, stiffness: 1400, damping: 1);

  /// Les morceaux trouvés pour [query].
  List<Track> results = const [];
}

/// Durées possibles du rétroéclairage, en secondes (0 : toujours allumé).
const backlightChoices = [0, 2, 5, 10, 15, 20, 30];

String backlightLabel(int seconds) => seconds == 0 ? tr('Toujours allumé') : trSeconds(seconds);

/// Les lettres qui pilotent le baladeur, en plus des flèches : monter,
/// descendre, entrer (valider) et revenir (MENU).
class KeyLayout {
  const KeyLayout(this.name, this.label, {required this.up, required this.down, required this.enter, required this.back});

  /// Quatre touches choisies une à une (Touches › Autres) : haut, bas, avant, arrière.
  KeyLayout.custom(List<LogicalKeyboardKey> k)
      : this('custom', [for (final x in k) x.keyLabel.toUpperCase()].join(' '), up: k[0], down: k[1], enter: k[2], back: k[3]);

  static const wasd = KeyLayout('wasd', 'W A S D', up: LogicalKeyboardKey.keyW, down: LogicalKeyboardKey.keyS, enter: LogicalKeyboardKey.keyD, back: LogicalKeyboardKey.keyA);
  static const zqsd = KeyLayout('zqsd', 'Z Q S D', up: LogicalKeyboardKey.keyZ, down: LogicalKeyboardKey.keyS, enter: LogicalKeyboardKey.keyD, back: LogicalKeyboardKey.keyQ);
  static const hjkl = KeyLayout('hjkl', 'H J K L', up: LogicalKeyboardKey.keyK, down: LogicalKeyboardKey.keyJ, enter: LogicalKeyboardKey.keyL, back: LogicalKeyboardKey.keyH);
  static const presets = [wasd, zqsd, hjkl];

  /// Nom gardé dans les préférences (« custom » : les touches sont à côté, dans device.customKeys).
  final String name;
  final String label;
  final LogicalKeyboardKey up, down, enter, back;

  /// Les touches gardées dans les préférences ; H J K L sinon.
  static KeyLayout load() {
    final name = Settings.getString('device.keys');
    if (name == 'custom') {
      final ids = [for (final s in (Settings.getString('device.customKeys') ?? '').split(',')) int.tryParse(s)];
      if (ids.length == 4 && !ids.contains(null)) {
        return KeyLayout.custom([for (final id in ids) LogicalKeyboardKey.findKeyByKeyId(id!) ?? LogicalKeyboardKey(id)]);
      }
    }
    return presets.firstWhere((p) => p.name == name, orElse: () => hjkl);
  }
}

class NowPlayingPage extends DevicePage {
  @override
  String get title => tr('En lecture');
}

/// Navigation dans les menus, pilotée par la molette et le clavier.
/// L'écran ne fait que dessiner cet état en l'animant.
class DeviceNav extends ChangeNotifier {
  DeviceNav(this.player, {required this.look, bool? welcome}) : coverFlow = look.coverFlow {
    // Premier lancement : la langue, puis les touches, avant le menu principal.
    stack = [welcome ?? (!JsonStore.inTest && Settings.getString('welcome') == null) ? _welcome() : _root()];
    backlight = int.tryParse(Settings.getString('device.backlight') ?? '') ?? 10;
    keys = KeyLayout.load();
    WheelClick.instance.enabled = Settings.getString('device.clicker') != 'off';
    WheelClick.instance.pitch =
        (int.tryParse(Settings.getString('device.clickPitch') ?? '') ?? 2).clamp(0, WheelClick.pitches.length - 1);
    _libraryVersion = player.libraryVersion;
    player.addListener(_onPlayer);
  }

  @override
  void dispose() {
    player.removeListener(_onPlayer);
    super.dispose();
  }

  int _libraryVersion = 0;

  /// La bibliothèque a changé (autre source, rafraîchie) : les pages qui
  /// montraient l'ancienne (albums, morceaux, Cover Flow) se referment. On
  /// reste sur En lecture si on y était.
  void _onPlayer() {
    if (player.libraryVersion == _libraryVersion) return;
    _libraryVersion = player.libraryVersion;
    final at = stack.indexWhere((p) => p is CoverFlowPage || p is SearchPage || (p is MenuPage && p.music));
    if (at < 1) return;
    final top = stack.last;
    stack.removeRange(at, stack.length);
    if (top is NowPlayingPage) stack.add(top);
    leaving = null;
    notifyListeners();
  }

  final PlayerController player;

  /// L'écran du modèle en main : il décide du nombre de lignes, des menus
  /// scindés, de ce que fait le bouton central sur « En lecture »…
  ScreenLook look;

  /// Nombre de lignes visibles dans un menu simple.
  int get visibleRows => look.visibleRows;

  /// Nombre de lignes visibles de [p] (moins dans un menu scindé à la
  /// verticale ou à lignes hautes).
  int rowsOf(MenuPage p) => look.rowsFor(p.kind);

  // --- Verrou (Hold) -------------------------------------------------------------

  /// Le verrou est mis : molette et boutons ne font plus rien, un cadenas
  /// s'affiche dans la barre de titre.
  bool locked = false;

  void toggleLock() {
    locked = !locked;
    notifyListeners();
  }

  /// L'écran sait afficher Cover Flow (écran couleur).
  bool coverFlow;

  // --- Rétroéclairage ----------------------------------------------------------

  /// Secondes avant que l'écran s'éteigne (0 : toujours allumé).
  int backlight = 10;

  DateTime lastInput = clock.now();

  bool get lit => !_dark && (backlight == 0 || clock.now().difference(lastInput) < Duration(seconds: backlight));

  /// Éteint à la main (entrée « Rétroéclairage » du menu principal des
  /// écrans monochromes), jusqu'au prochain geste.
  bool _dark = false;

  void darken() {
    _dark = true;
    notifyListeners();
  }

  /// Une main sur l'appareil : l'écran se rallume.
  void touch() {
    final wasLit = lit;
    _dark = false;
    lastInput = clock.now();
    if (!wasLit) notifyListeners();
  }

  /// Un autre appareil prend la navigation : même écran, même sélection,
  /// recadrée pour son nombre de lignes. Sans Cover Flow (écran
  /// monochrome), on en ressort.
  void fitLook(ScreenLook look) {
    this.look = look;
    coverFlow = look.coverFlow;
    if (!coverFlow) {
      final at = stack.indexWhere((p) => p is CoverFlowPage);
      if (at > 0) {
        stack.removeRange(at, stack.length);
        leaving = null;
      }
    }
    if (!look.centerCycle.contains(mode) && mode != NowPlayingMode.volume) mode = NowPlayingMode.progress;
    for (final p in stack.whereType<MenuPage>()) {
      final rows = rowsOf(p);
      if (p.selected >= p.top + rows) p.top = p.selected - rows + 1;
      p.top = p.top.clamp(0, math.max(0, p.entries.length - rows));
      p.topSpring
        ..value = p.top.toDouble()
        ..velocity = 0;
    }
    notifyListeners();
  }
  late final List<DevicePage> stack;

  DevicePage get page => stack.last;

  /// Page qui sort pendant une transition, et sens (+1 entrée, -1 retour).
  DevicePage? leaving;
  int direction = 1;
  int transition = 0;

  NowPlayingMode mode = NowPlayingMode.progress;
  DateTime _modeUntil = DateTime(0);

  /// Retour à l'affichage de la progression après un moment d'inactivité.
  bool expireMode() {
    if (mode != NowPlayingMode.progress && clock.now().isAfter(_modeUntil)) {
      mode = NowPlayingMode.progress;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Recherche par appui long : montre le losange sur la barre.
  void showScrub() {
    if (page is! NowPlayingPage) return;
    _setMode(NowPlayingMode.scrub, const Duration(milliseconds: 1500));
    notifyListeners();
  }

  void _setMode(NowPlayingMode m, Duration hold) {
    mode = m;
    _modeUntil = clock.now().add(hold);
  }

  // --- Commandes de la molette ---------------------------------------------

  /// Renvoie false si rien n'a bougé (bout de liste) : pas de clic.
  bool scroll(int delta) {
    switch (page) {
      case final CoverFlowPage p when p.flipped:
        final count = p.tracks(player, p.selected)?.length ?? 0;
        if (count == 0) return false;
        final t = (p.track + delta).clamp(0, count - 1);
        if (t == p.track) return false;
        p.track = t;
        if (t < p.trackTop) p.trackTop = t;
        if (t >= p.trackTop + CoverFlowPage.backRows) p.trackTop = t - CoverFlowPage.backRows + 1;
      case final CoverFlowPage p:
        final sel = p.count(player) > 0 && p._byLetter(delta.sign)
            ? p._letterJump(player, delta.sign)
            : (p.selected + delta).clamp(0, math.max(0, p.count(player) - 1)).toInt();
        if (sel == p.selected) return false;
        p.selected = sel;
      case final MenuPage p:
        final count = p.entries.length;
        if (count == 0) return false;
        final sel = (p.selected + delta).clamp(0, count - 1);
        if (sel == p.selected) return false;
        p.selected = sel;
        if (sel < p.top) p.top = sel;
        final rows = rowsOf(p);
        if (sel >= p.top + rows) p.top = sel - rows + 1;
      case final SearchPage p:
        final cell = (p.cell + delta).clamp(0, SearchPage.cells - 1);
        if (cell == p.cell) return false;
        p.cell = cell;
      case NowPlayingPage() when mode == NowPlayingMode.rating:
        final track = player.current;
        if (track == null) return false;
        final stars = (player.rating(track) + delta.sign).clamp(0, 5);
        _setMode(NowPlayingMode.rating, const Duration(seconds: 4));
        if (stars == player.rating(track)) return false;
        player.setRating(track, stars);
      case NowPlayingPage() when mode == NowPlayingMode.shuffle:
        _setMode(NowPlayingMode.shuffle, const Duration(seconds: 4));
        if (player.shuffle == delta > 0) return false;
        player.setShuffle(delta > 0);
      case NowPlayingPage():
        if (mode == NowPlayingMode.scrub) {
          final total = player.duration.inMilliseconds;
          if (total > 0) {
            final pos = player.smoothPosition.inMilliseconds + delta * 3000;
            player.seekProgress(pos / total);
          }
          _setMode(NowPlayingMode.scrub, const Duration(seconds: 4));
        } else {
          player.setVolume(player.volume + delta * 3);
          _setMode(NowPlayingMode.volume, const Duration(milliseconds: 1600));
        }
    }
    _syncPreview();
    notifyListeners();
    return true;
  }

  void select() {
    switch (page) {
      case final MenuPage p:
        if (p.entries.isEmpty) return;
        final e = p.entries[p.selected];
        if (e.open != null) {
          _push(e.open!());
        } else {
          e.action?.call();
          notifyListeners(); // une valeur a pu changer (Réglages)
        }
      case final CoverFlowPage p when p.flipped:
        // On joue le morceau sans quitter le dos de la pochette.
        final list = p.lists?[p.selected];
        if (list == null) {
          player.playAlbum(p.selected, p.track);
        } else if (list.tracks case final tracks?) {
          player.playTracks(tracks, p.track, uri: list.uri);
        } else if (list.uri case final uri? when list.error != null) {
          player.playUri(uri); // pas parcourable (liste suivie) : on la joue entière
        }
        notifyListeners();
      case final CoverFlowPage p:
        if (p.count(player) == 0) return;
        // Une liste charge ses morceaux à la première ouverture (Spotify).
        final list = p.lists?[p.selected];
        if (list != null && list.tracks == null && list.error == null) list.load(onDone: notifyListeners).ignore();
        // La pochette se retourne, sur le morceau en cours s'il en est.
        final playing = p.tracks(player, p.selected)?.indexWhere((t) => t.id == player.current?.id) ?? -1;
        p
          ..flipped = true
          ..track = math.max(0, playing)
          ..trackTop = math.max(0, p.track - CoverFlowPage.backRows + 1);
        p.trackSpring
          ..value = p.track.toDouble()
          ..velocity = 0;
        p.trackTopSpring
          ..value = p.trackTop.toDouble()
          ..velocity = 0;
        notifyListeners();
      case final SearchPage p:
        switch (p.cell) {
          case SearchPage.done:
            if (p.results.isNotEmpty) _push(_tracks(p.query.trim(), p.results));
            return;
          case SearchPage.delete:
            if (p.query.isNotEmpty) p.query = p.query.substring(0, p.query.length - 1);
          case SearchPage.space:
            if (p.query.isNotEmpty && !p.query.endsWith(' ')) p.query += ' ';
          default:
            if (p.query.length < 24) p.query += SearchPage.letters[p.cell];
        }
        p.results = _search(p.query);
        notifyListeners();
      case NowPlayingPage():
        // Le bouton central passe d'un affichage au suivant, puis revient
        // à la progression.
        final cycle = look.centerCycle;
        final at = cycle.indexOf(mode) + 1;
        if (at < cycle.length) {
          _setMode(cycle[at], Duration(seconds: cycle[at] == NowPlayingMode.art ? 3600 : 4));
        } else {
          mode = NowPlayingMode.progress;
        }
        notifyListeners();
    }
  }

  /// Les morceaux dont le titre, l'artiste ou l'album contient [query].
  List<Track> _search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    bool has(String s) => s.toLowerCase().contains(q);
    return [
      for (final t in player.tracks)
        if (has(t.title) || has(t.artist) || has(t.album)) t,
    ]..sort((a, b) => _cmp(a.title, b.title));
  }

  void menu() {
    if (page case final CoverFlowPage p when p.flipped) {
      p.flipped = false; // la pochette se remet de face
      notifyListeners();
      return;
    }
    if (stack.length < 2) return;
    leaving = stack.removeLast();
    direction = -1;
    transition++;
    mode = NowPlayingMode.progress;
    _syncPreview();
    notifyListeners();
  }

  void _push(DevicePage p) {
    leaving = page;
    stack.add(p);
    direction = 1;
    transition++;
    mode = NowPlayingMode.progress;
    _syncPreview();
    notifyListeners();
  }

  void transitionDone() => leaving = null;

  /// Teinte du baladeur en main, s'il a Couleur au hasard (nano 4G et 5G).
  Color? get coverColor => _coverColor;

  /// Toutes les teintes du modèle en main (voir DeviceModel.coverPalette).
  List<Color> coverPalette = const [];
  Color? _coverColor;

  /// En pleine Couleur au hasard, une autre teinte : la suite de la file
  /// prend ses pochettes à elle, dès le morceau suivant.
  set coverColor(Color? color) {
    final was = _coverColor;
    _coverColor = color;
    if (color != null && color != was && _colorQueue != null && identical(player.nowPlaying, _colorQueue)) {
      _recolor(color);
    }
  }

  /// La file lancée par Couleur au hasard, tant que c'est elle qui joue.
  List<Track>? _colorQueue;
  int _recolors = 0;

  Future<void> _recolor(Color color) async {
    final ticket = ++_recolors;
    final albums = await player.albumsMatching(color, palette: coverPalette);
    // Une autre teinte entre-temps, ou une autre musique lancée.
    if (ticket != _recolors || !identical(player.nowPlaying, _colorQueue)) return;
    final playing = player.current;
    final upcoming = [for (final t in spreadAlbums(albums)) if (t.id != playing?.id) t];
    if (upcoming.isEmpty) return;
    if (await player.replaceUpcoming(upcoming)) _colorQueue = player.nowPlaying;
  }

  /// Couleur au hasard : les morceaux des albums dont la pochette est
  /// assortie au baladeur, les pochettes variant d'un morceau à l'autre. Le temps de lire les pochettes, une
  /// page « Chargement… ».
  Future<void> _colorShuffle(Color color) async {
    final wait = MenuPage(tr('Morceau au hasard (couleur)'), () => [MenuEntry(tr('Chargement…'))]);
    _push(wait);
    final list = spreadAlbums(await player.albumsMatching(color, palette: coverPalette));
    if (!identical(page, wait)) return; // on est reparti entre-temps
    stack.removeLast();
    if (list.isEmpty) return _push(MenuPage(tr('Morceau au hasard (couleur)'), () => [MenuEntry(tr('Aucun élément'))]));
    _play(list, 0);
    _colorQueue = list;
  }

  /// Joue [list] depuis le morceau [index] et passe à En lecture.
  void _play(List<Track> list, int index, {String? uri}) {
    player.playTracks(list, index, uri: uri);
    _push(NowPlayingPage());
  }

  // --- Menus ---------------------------------------------------------------

  MenuPage _root() => MenuPage(tr('Lecteur'), live: true, kind: MenuKind.split, () => [
        // Ce qui n'a pas marché (pas d'appareil Spotify…) ; valider l'efface.
        if (player.notice case final notice?)
          MenuEntry(notice, action: player.dismissNotice),
        // Une version plus récente est publiée : valider l'installe et relance
        // l'appli, ou ouvre sa page si ça ne peut pas se faire ici.
        if (newVersion case final version?)
          MenuEntry(tr('Mise à jour'), value: () => updateStatus ?? version, action: _update),
        MenuEntry(tr('Musique'), open: _music),
        MenuEntry(tr('Réglages'), open: _settings, preview: MenuPreview.settings),
        MenuEntry(tr('Morceau au hasard'), action: () {
          if (player.tracks.isEmpty) return;
          _play(player.tracks, math.Random().nextInt(player.tracks.length));
        }),
        if (coverColor case final color?) MenuEntry(tr('Morceau au hasard (couleur)'), action: () => _colorShuffle(color)),
        // Sur les écrans monochromes, le rétroéclairage s'éteint d'ici.
        if (look.mono) MenuEntry(tr('Rétroéclairage'), action: darken),
        if (player.current != null)
          MenuEntry(tr('En lecture'), open: NowPlayingPage.new, preview: MenuPreview.nowPlaying),
      ]);

  Future<void> _update() async {
    if (updateStatus != null) return; // déjà en train de télécharger
    if (!await prepareUpdate(onStep: notifyListeners)) {
      notifyListeners();
      launchUrl(Uri.parse(releasesUrl));
      return;
    }
    // « Redémarrage… » reste un instant à l'écran avant que l'appli se ferme.
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    // Comme en quittant par Échap : le script attend qu'on soit fermé.
    for (final a in player.accounts) {
      a.shutdown();
    }
    Settings.flush();
    exit(0);
  }

  MenuPage _music() => MenuPage(tr('Musique'), live: true, kind: MenuKind.split, () => [
        if (coverFlow && player.albums.isNotEmpty)
          MenuEntry('Cover Flow', open: () => CoverFlowPage(math.max(0, player.currentAlbum))),
        // En pochettes sur les écrans qui ont Cover Flow.
        MenuEntry(tr('Listes de lecture'), open: coverFlow ? _playlistFlow : _playlists),
        MenuEntry(tr('Artistes'), open: _artists),
        MenuEntry(tr('Albums'), open: () => _albumList(tr('Albums'), _sortedAlbums(null))),
        MenuEntry(tr('Morceaux'), open: _songs),
        // (Seulement si les fichiers en donnent : Spotify n'en a pas par morceau.)
        if (player.tracks.any((t) => t.genre != null)) MenuEntry(tr('Genres'), open: _genres),
        MenuEntry(tr('Recherche'), open: SearchPage.new),
      ]);

  MenuPage _genres() => MenuPage(tr('Genres'), music: true, () {
        final names = <String, String>{};
        for (final t in player.tracks) {
          if (t.genre case final g?) names.putIfAbsent(g.toLowerCase(), () => g);
        }
        final sorted = names.values.toList()..sort(_cmp);
        return [
          for (final g in sorted)
            MenuEntry(g, open: () => _tracks(g, [for (final t in player.tracks) if (t.genre?.toLowerCase() == g.toLowerCase()) t])),
        ];
      });

  MenuPage _playlists() => MenuPage(tr('Listes de lecture'), music: true, () => [
        MenuEntry(tr('Ajouts récents'), open: () => _tracks(tr('Ajouts récents'), player.recentlyAdded(25))),
        MenuEntry(tr('Les plus écoutés'), open: () => _tracks(tr('Les plus écoutés'), player.mostPlayed(25))),
        for (final l in player.playlists) MenuEntry(l.name, open: () => _songList(l)),
      ]);

  /// Les mêmes listes, en Cover Flow.
  CoverFlowPage _playlistFlow() => CoverFlowPage(0, lists: [
        SongList(tr('Ajouts récents'), player.recentlyAdded(25)),
        SongList(tr('Les plus écoutés'), player.mostPlayed(25)),
        ...player.playlists,
      ]);

  /// Une liste de lecture : ses morceaux, chargés à la première ouverture
  /// si la source les donne à la demande (Spotify).
  MenuPage _songList(SongList l) => MenuPage(l.name, live: true, music: true, () {
        final tracks = l.tracks;
        if (tracks != null) {
          return [for (var i = 0; i < tracks.length; i++) MenuEntry(tracks[i].title, action: () => _play(tracks, i, uri: l.uri))];
        }
        // Pas parcourable (liste suivie, pas à soi) : on peut la jouer
        // entière quand même.
        if (l.error != null) {
          return [
            if (l.uri case final uri?)
              MenuEntry(tr('Lire la liste'), action: () {
                player.playUri(uri);
                _push(NowPlayingPage());
              })
            else
              MenuEntry(tr('Aucun élément')),
          ];
        }
        l.load(onDone: notifyListeners).ignore();
        return [MenuEntry(tr('Chargement…'))];
      });

  // --- Réglages ------------------------------------------------------------

  /// La page Réglages ouverte : on y revient d'un coup après avoir choisi
  /// une bibliothèque.
  MenuPage? _settingsPage;

  MenuPage _settings() => _settingsPage = MenuPage(tr('Réglages'), live: true, kind: MenuKind.split, () => [
        MenuEntry(tr('À propos'), open: _about),
        MenuEntry(
          tr('Bibliothèque'),
          value: () => player.loading ? tr('Lecture…') : _sourceName(),
          open: _library,
        ),
        MenuEntry(
          tr('Lecture aléatoire'),
          value: () => player.shuffle ? tr('Morceaux') : tr('Non'),
          action: () => player.setShuffle(!player.shuffle),
        ),
        MenuEntry(
          tr('Répéter'),
          value: () => switch (player.repeat) {
            RepeatMode.off => tr('Non'),
            RepeatMode.one => tr('Un'),
            RepeatMode.all => tr('Tous'),
          },
          action: () => player.setRepeat(RepeatMode.values[(player.repeat.index + 1) % RepeatMode.values.length]),
        ),
        MenuEntry(tr('Rétroéclairage'), value: () => backlight == 0 ? tr('Allumé') : '$backlight s', open: _backlightMenu),
        MenuEntry(tr('Commandes'), open: _controlsMenu),
        if (Platform.isWindows) MenuEntry(tr('Fenêtre'), open: _windowMenu),
        MenuEntry(tr('Langue'), value: () => Lang.current.nativeName, open: _languageMenu),
      ]);

  /// Réglages › Commandes : la molette (clic) et le clavier (touches).
  MenuPage _controlsMenu() => MenuPage(tr('Commandes'), live: true, () => [
        MenuEntry(tr('Clic'), value: () => WheelClick.instance.enabled ? tr('Haut-parleur') : tr('Non'), open: _clickMenu),
        MenuEntry(tr('Touches'), value: () => keys.label, open: _keysMenu),
      ]);

  /// Réglages › Fenêtre (Windows).
  MenuPage _windowMenu() => MenuPage(tr('Fenêtre'), live: true, () => [
        // Sous Windows, rien ne réserve de place au baladeur : on peut le garder
        // par-dessus les autres fenêtres.
        MenuEntry(
          tr('Premier plan'),
          value: () => windowOnTop.value ? tr('Oui') : tr('Non'),
          action: () {
            windowOnTop.value = !windowOnTop.value;
            Settings.setString('window.top', windowOnTop.value ? 'on' : 'off');
          },
        ),
        // Et le poser où l'on veut, plutôt qu'à l'une de ses trois places.
        MenuEntry(
          tr('Position'),
          value: () => deviceFree.value ? tr('Libre') : tr('Fixe'),
          action: () {
            deviceFree.value = !deviceFree.value;
            Settings.setString('window.free', deviceFree.value ? 'on' : 'off');
          },
        ),
      ]);

  /// Réglages › Clic : l'allumer ou l'éteindre, et sa tonalité.
  MenuPage _clickMenu() => MenuPage(tr('Clic'), live: true, () => [
        MenuEntry(
          tr('Clic'),
          value: () => WheelClick.instance.enabled ? tr('Haut-parleur') : tr('Non'),
          action: () {
            final on = !WheelClick.instance.enabled;
            WheelClick.instance.enabled = on;
            Settings.setString('device.clicker', on ? 'on' : 'off');
          },
        ),
        MenuEntry(
          tr('Tonalité du clic'),
          value: () => tr(WheelClick.pitchNames[WheelClick.instance.pitch]),
          open: _pitchMenu,
        ),
      ]);

  /// Les lettres de déplacement choisies (Réglages › Touches).
  late KeyLayout keys;

  /// [done] : ce qui suit le choix (retour aux Réglages ; au premier
  /// lancement, le menu principal).
  MenuPage _keysMenu({VoidCallback? done}) {
    final then = done ?? _backToSettings;
    final page = MenuPage(tr('Touches'), live: true, welcome: done != null, () => [
          for (final k in KeyLayout.presets)
            MenuEntry(k.label, checked: () => k.name == keys.name, action: () {
              _setKeys(k);
              then();
            }),
          MenuEntry(tr('Autres'), value: keys.name == 'custom' ? () => keys.label : null, open: () => _capture(then, welcome: done != null)),
        ]);
    final at = KeyLayout.presets.indexWhere((k) => k.name == keys.name);
    _focus(page, at < 0 ? KeyLayout.presets.length : at);
    return page;
  }

  void _setKeys(KeyLayout k) {
    keys = k;
    Settings.setString('device.keys', k.name);
    if (k.name == 'custom') Settings.setString('device.customKeys', [k.up, k.down, k.enter, k.back].map((x) => x.keyId).join(','));
  }

  // --- Touches › Autres : quatre touches au choix --------------------------

  MenuPage? _capturePage;
  List<LogicalKeyboardKey?> _captured = const [];
  VoidCallback? _captureDone;

  /// Touches qui gardent leur rôle (flèches, Entrée, Retour arrière, Espace, T, Échap).
  static final _reserved = {
    LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.enter, LogicalKeyboardKey.numpadEnter, LogicalKeyboardKey.backspace, LogicalKeyboardKey.space,
    LogicalKeyboardKey.keyT, LogicalKeyboardKey.escape,
  };

  /// Quatre lignes ; la ligne sélectionnée attend sa touche (« ? »).
  MenuPage _capture(VoidCallback done, {bool welcome = false}) {
    _captured = List.filled(4, null);
    _captureDone = done;
    const names = ['Haut', 'Bas', 'Avant', 'Arrière'];
    return _capturePage = MenuPage(tr('Autres'), live: true, welcome: welcome, () => [
          for (var i = 0; i < 4; i++) MenuEntry(tr(names[i]), value: () => _captured[i]?.keyLabel.toUpperCase() ?? '?'),
        ]);
  }

  /// Une touche enfoncée pendant Touches › Autres : elle va à la ligne
  /// sélectionnée. Faux si la page n'attend rien (ou touche réservée).
  bool captureKey(LogicalKeyboardKey key) {
    final p = _capturePage;
    if (p == null || !identical(page, p) || _reserved.contains(key)) return false;
    if (_captured.indexOf(key) case final at when at >= 0 && at != p.selected) return true; // déjà prise
    _captured[p.selected] = key;
    final next = _captured.indexOf(null);
    if (next < 0) {
      _setKeys(KeyLayout.custom(_captured.cast()));
      _capturePage = null;
      _captureDone!();
    } else {
      scroll(next - p.selected);
      notifyListeners();
    }
    return true;
  }

  // --- Premier lancement ---------------------------------------------------

  /// Comme un baladeur qu'on allume pour la première fois : la langue, puis les touches.
  MenuPage _welcome() => MenuPage('Language', welcome: true, () => [
        for (final l in Lang.values)
          MenuEntry(l.nativeName, action: () {
            Lang.set(l);
            _push(_keysMenu(done: () => _push(_welcomeSource())));
          }),
      ]);

  /// Dernier écran de l'accueil : d'où vient la musique. On arrive ensuite
  /// dans Réglages › Bibliothèque › ce choix, pour se connecter ou choisir un dossier.
  MenuPage _welcomeSource() => MenuPage(tr('Musique'), welcome: true, () => [
        for (final a in player.accounts) MenuEntry(a.label, action: () => _endWelcome([_library(), _account(a)])),
        MenuEntry(tr('Musique locale'), action: () => _endWelcome([_library(), _local()])),
      ]);

  /// L'écran montre l'accueil : il prend les clics.
  bool get welcoming => page is MenuPage && (page as MenuPage).welcome;

  /// Clic sur la ligne [i] de la page : la sélectionne et la valide.
  void tap(int i) {
    final p = page;
    if (p is! MenuPage) return;
    scroll(i - p.selected);
    select();
  }

  /// [then] : les pages ouvertes par-dessus Réglages (le choix de la musique).
  void _endWelcome([List<MenuPage> then = const []]) {
    Settings.setString('welcome', 'fait');
    leaving = page;
    stack
      ..clear()
      ..add(_root());
    if (then.isNotEmpty) stack.addAll([_settings(), ...then]);
    direction = 1;
    transition++;
    _syncPreview();
    notifyListeners();
  }

  /// Page Tonalité du clic : parcourir la liste fait entendre chaque
  /// tonalité ; valider la garde (on reste là pour comparer).
  MenuPage? _pitchPage;

  MenuPage _pitchMenu() {
    final click = WheelClick.instance;
    final page = _pitchPage = MenuPage(tr('Tonalité du clic'), live: true, () => [
          for (var i = 0; i < WheelClick.pitches.length; i++)
            MenuEntry(tr(WheelClick.pitchNames[i]), checked: () => i == click.pitch, action: () {
              click.pitch = i;
              Settings.setString('device.clickPitch', '$i');
            }),
        ]);
    _focus(page, click.pitch);
    return page;
  }

  /// Le clic prend la tonalité survolée tant qu'on est dans son menu.
  void _syncPreview() {
    final p = page;
    WheelClick.instance.preview = p is MenuPage && identical(p, _pitchPage) ? p.selected : null;
  }

  MenuPage _languageMenu() {
    final page = MenuPage(tr('Langue'), live: true, () => [
          for (final l in Lang.values)
            MenuEntry(l.nativeName, checked: () => l == Lang.current, action: () {
              if (l == Lang.current) return;
              Lang.set(l);
              _relabel();
            }),
        ]);
    _focus(page, Lang.current.index);
    return page;
  }

  /// Nouvelle langue : les pages ouvertes (Lecteur › Réglages › Langue)
  /// sont reconstruites avec leurs titres traduits, à la même place.
  void _relabel() {
    final fresh = <MenuPage>[_root(), _settings(), _languageMenu()];
    for (var i = 0; i < fresh.length && i < stack.length; i++) {
      final old = stack[i], now = fresh[i];
      if (old is! MenuPage) continue;
      now
        ..selected = old.selected
        ..top = old.top;
      now.selSpring.value = old.selSpring.value;
      now.topSpring.value = old.topSpring.value;
    }
    stack
      ..clear()
      ..addAll(fresh);
    leaving = null;
  }

  /// Ouvre [page] sur la ligne [at] (le choix en cours).
  void _focus(MenuPage page, int at) {
    at = math.max(0, at);
    page
      ..selected = at
      ..top = math.max(0, at - rowsOf(page) + 1);
    page.selSpring.value = at.toDouble();
    page.topSpring.value = page.top.toDouble();
  }

  MenuPage _backlightMenu() {
    final page = MenuPage(tr('Rétroéclairage'), live: true, () => [
          for (final s in backlightChoices)
            MenuEntry(backlightLabel(s), checked: () => s == backlight, action: () {
              backlight = s;
              Settings.setString('device.backlight', '$s');
              menu(); // choisi : on revient aux Réglages
            }),
        ]);
    // On arrive sur le choix en cours.
    _focus(page, backlightChoices.indexOf(backlight));
    return page;
  }

  // --- Bibliothèque : choisir le dossier de musique ---------------------------

  static String _folderName(String path) => lastSegment(path);

  /// On écoute la musique du dossier [path] (et pas un service en ligne).
  bool _usingFolder(String path) => path == player.musicDir && player.source.id == 'local';

  /// D'où vient la musique : le service en ligne, ou le nom du dossier.
  String _sourceName() {
    for (final a in player.accounts) {
      if (a.sourceId == player.source.id) return a.label;
    }
    return _folderName(player.musicDir);
  }

  /// Deux choix : le service en ligne ou les fichiers ; coché, celui qu'on écoute.
  MenuPage _library() => MenuPage(tr('Bibliothèque'), live: true, () => [
        for (final a in player.accounts)
          MenuEntry(a.label, checked: () => player.source.id == a.sourceId, open: () => _account(a)),
        MenuEntry(tr('Musique locale'), checked: () => !player.accounts.any((a) => a.sourceId == player.source.id), open: _local),
      ]);

  MenuPage _local() => MenuPage(tr('Musique locale'), () => [
        MenuEntry(tr('Dossier actuel'), value: () => _folderName(player.musicDir), open: () => _folder(player.musicDir)),
        MenuEntry(tr('Sélectionner un dossier'), open: _places),
      ]);

  /// Points de départ : le dossier personnel, les disques
  /// branchés, la racine (sous Windows : les lecteurs C:, D:…). Cherchés une
  /// fois à l'ouverture de la page, pas à chaque image.
  MenuPage _places() => MenuPage(tr('Dossiers'), () {
        final user = Platform.environment['USER'] ?? '';
        return [
          MenuEntry(tr('Dossier personnel'), open: () => _folder(homeDir())),
          if (Platform.isWindows)
            for (final drive in windowsDrives()) MenuEntry(drive, open: () => _folder(drive))
          else ...[
            for (final (label, path) in [
              (tr('Disques'), '/run/media/$user'),
              (tr('Disques'), '/media/$user'),
              (tr('Disques'), '/Volumes'),
            ])
              if (user.isNotEmpty || !path.endsWith('/')) // pas de « /media/ » sans nom
                if (Directory(path).existsSync()) MenuEntry(label, open: () => _folder(path)),
            MenuEntry(tr('Racine'), open: () => _folder('/')),
          ],
        ];
      });

  // --- Comptes en ligne (Spotify…) -------------------------------------------

  /// Un service en ligne : se connecter, l'utiliser.
  MenuPage _account(RemoteAccount a) => MenuPage(a.label, live: true, () {
        if (a.connecting) return [MenuEntry(tr('Connexion…'), value: () => tr('navigateur'))];
        if (a.needsKey) {
          // Chacun sa clé (Spotify n'en accepte que cinq comptes par appli) :
          // un guide dans le navigateur pour la créer, puis on la colle ici.
          return [
            MenuEntry(tr('Créer ma clé'), value: () => tr('guide'), action: () {
              a.openKeyGuide().catchError((Object e) {
                _keyMessage = '$e';
                notifyListeners();
              });
            }),
            MenuEntry(tr('Coller la clé'), value: () => _keyMessage ?? '', action: () {
              a.pasteKey().then((_) {
                _keyMessage = null;
              }, onError: (Object e) {
                _keyMessage = '$e';
              }).whenComplete(notifyListeners);
            }),
          ];
        }
        if (!a.connected) {
          return [
            MenuEntry(tr('Se connecter'), action: () {
              a.connect().then((_) {
                if (a.connected) player.useSource(a.sourceId);
              }, onError: (Object e) {
                player.notice = '$e';
              }).whenComplete(notifyListeners);
              notifyListeners();
            }),
            if (a.keyHint case final key?) MenuEntry(tr('Changer de clé'), value: () => key, action: () => a.forgetKey()),
          ];
        }
        final inUse = player.source.id == a.sourceId;
        return [
          MenuEntry(tr('Utiliser %s').replaceFirst('%s', a.label), checked: () => inUse, action: () {
            if (!inUse) player.useSource(a.sourceId);
            _backToSettings();
          }),
          // Ce qu'on vient d'ajouter au compte, depuis une autre appli.
          if (inUse)
            MenuEntry(tr('Actualiser'), action: () {
              player.loadLibrary();
              _backToSettings();
            }),
          MenuEntry(tr('Compte'), value: () => a.userName ?? ''),
          if (a.keyHint case final key?) MenuEntry(tr('Clé'), value: () => key),
          MenuEntry(tr('Se déconnecter'), action: () {
            a.disconnect();
            if (inUse) player.useSource('local');
            notifyListeners();
          }),
        ];
      });

  /// Ce qu'a donné « Coller la clé » (rien dans le presse-papiers…).
  String? _keyMessage;

  /// Un dossier : « Utiliser ce dossier », puis ses sous-dossiers.
  MenuPage _folder(String path) => MenuPage(_folderName(path), () {
        List<Directory> subs;
        try {
          subs = Directory(path)
              .listSync(followLinks: false)
              .whereType<Directory>()
              .where((d) => !_folderName(d.path).startsWith('.'))
              .toList()
            ..sort((a, b) => _cmp(_folderName(a.path), _folderName(b.path)));
        } catch (_) {
          subs = const []; // illisible : on peut quand même le choisir
        }
        return [
          // (Coché seulement si c'est vraiment ce dossier qu'on écoute :
          // depuis Spotify, choisir le même dossier y revient.)
          MenuEntry(tr('Utiliser ce dossier'), checked: () => _usingFolder(path), action: () {
            if (!_usingFolder(path)) player.setMusicDir(path);
            _backToSettings();
          }),
          for (final d in subs) MenuEntry(_folderName(d.path), open: () => _folder(d.path)),
        ];
      });

  /// Revient d'un coup aux Réglages (en glissant vers la droite).
  void _backToSettings() {
    // (La page elle-même, pas son titre : un dossier peut s'appeler pareil.)
    final at = stack.lastIndexWhere((p) => identical(p, _settingsPage));
    if (at < 0 || at == stack.length - 1) return;
    leaving = stack.last;
    stack.removeRange(at + 1, stack.length);
    direction = -1;
    transition++;
    notifyListeners();
  }

  MenuPage _about() => MenuPage(tr('À propos'), () {
        final artists = {for (final a in player.albums) a.artist.toLowerCase()};
        return [
          MenuEntry(tr('Morceaux'), value: () => '${player.tracks.length}'),
          MenuEntry(tr('Albums'), value: () => '${player.albums.length}'),
          MenuEntry(tr('Artistes'), value: () => '${artists.length}'),
          MenuEntry(tr('Listes'), value: () => '${player.playlists.length}'),
          MenuEntry('Version', value: () => appVersion),
        ];
      });

  static int _cmp(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

  MenuPage _artists() => MenuPage(tr('Artistes'), music: true, () {
        final names = <String, String>{};
        for (final a in player.albums) {
          names.putIfAbsent(a.artist.toLowerCase(), () => a.artist);
        }
        final sorted = names.values.toList()..sort(_cmp);
        return [for (final n in sorted) MenuEntry(n, open: () => _artist(n))];
      });

  /// Index (dans player.albums) triés par titre, éventuellement d'un artiste.
  List<int> _sortedAlbums(String? artist) {
    final albums = player.albums;
    final ids = [
      for (var i = 0; i < albums.length; i++)
        if (artist == null || albums[i].artist.toLowerCase() == artist.toLowerCase()) i,
    ]..sort((a, b) => _cmp(albums[a].title, albums[b].title));
    return ids;
  }

  MenuPage _artist(String artist) {
    final ids = _sortedAlbums(artist);
    return MenuPage(artist, music: true, () => [
          MenuEntry(tr('Tous'), open: () => _tracks(artist, [for (final i in ids) ..._albumTracks(player.albums[i])])),
          for (final i in ids) MenuEntry(player.albums[i].title, open: () => _album(i)),
        ]);
  }

  /// Des albums : sur les écrans qui le montrent, chacun avec sa vignette
  /// et son artiste.
  MenuPage _albumList(String title, List<int> ids) => MenuPage(title, music: true, kind: MenuKind.tall, () => [
        for (final i in ids)
          MenuEntry(
            player.albums[i].title,
            subtitle: player.albums[i].artist,
            art: () => player.albumCover(i),
            open: () => _album(i),
          ),
      ]);

  List<Track> _albumTracks(Album a) => player.tracks.sublist(a.firstIndex, a.firstIndex + a.trackCount);

  /// Un album : le lancer joue cet album (l'album entier chez la source,
  /// s'il en a un).
  MenuPage _album(int i) {
    final a = player.albums[i];
    final list = _albumTracks(a);
    return MenuPage(a.title, music: true, () => [
          for (var k = 0; k < list.length; k++) MenuEntry(list[k].title, action: () => _play(list, k, uri: a.uri)),
        ]);
  }

  MenuPage _songs() => MenuPage(tr('Morceaux'), music: true, () {
        final list = [...player.tracks]..sort((a, b) => _cmp(a.title, b.title));
        return [for (var i = 0; i < list.length; i++) MenuEntry(list[i].title, action: () => _play(list, i))];
      });

  MenuPage _tracks(String title, List<Track> list) =>
      MenuPage(title, music: true, () => [for (var i = 0; i < list.length; i++) MenuEntry(list[i].title, action: () => _play(list, i))]);
}
