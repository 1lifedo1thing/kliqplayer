import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Version de l'appli, affichée dans Réglages › À propos. La même que dans
/// pubspec.yaml (un test le vérifie).
const appVersion = '1.3.0';

/// Page où télécharger la dernière version.
const releasesUrl = 'https://github.com/Perzivalle/kliqplayer/releases/latest';

/// Version publiée plus récente que celle-ci, une fois connue : le menu principal
/// affiche alors une ligne « Mise à jour ».
String? newVersion;

/// Vrai si [latest] (« v0.7.0 », « 0.10 ») dépasse [current].
bool isNewer(String latest, String current) {
  List<int> parts(String v) => [for (final p in v.replaceFirst('v', '').split('.')) int.tryParse(p) ?? 0];
  final a = parts(latest), b = parts(current);
  for (var i = 0; i < a.length || i < b.length; i++) {
    final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}

/// Demande à GitHub la dernière version publiée, au lancement. Hors ligne ou
/// réponse inattendue : on ne dit rien.
Future<void> checkForUpdate() async {
  try {
    final res = await http
        .get(Uri.parse('https://api.github.com/repos/Perzivalle/kliqplayer/releases/latest'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return;
    final tag = (jsonDecode(res.body) as Map)['tag_name'];
    if (tag is String && isNewer(tag, appVersion)) newVersion = tag.replaceFirst('v', '');
  } catch (_) {}
}

/// Où en est la mise à jour, à droite de sa ligne (null : rien en cours).
String? updateStatus;

/// Télécharge la dernière version et prépare son installation à la place de
/// celle-ci : un petit script attend que l'appli soit fermée, échange les
/// dossiers et la relance. Faux si ça ne peut pas se faire ici (version de
/// développement, dossier en lecture seule, hors ligne…) : on ouvre alors la
/// page de la release.
Future<bool> prepareUpdate() async {
  Directory? work;
  try {
    final exe = File(Platform.resolvedExecutable);
    final (asset, name, binary) = Platform.isLinux
        ? ('KliqPlayer-linux-x64.tar.gz', 'KliqPlayer', 'kliqplayer')
        : Platform.isWindows
            ? ('KliqPlayer-windows-x64.zip', 'KliqPlayer', 'kliqplayer.exe')
            : ('KliqPlayer-macos.zip', 'KliqPlayer.app', 'Contents/MacOS/KliqPlayer');
    // Le dossier remplacé : celui de l'exécutable, ou le .app sous macOS.
    final target = Platform.isMacOS ? exe.parent.parent.parent : exe.parent;
    if (!exe.path.endsWith(binary.replaceAll('/', Platform.pathSeparator)) ||
        (Platform.isMacOS && !target.path.endsWith('.app'))) {
      return false; // lancée depuis build/ : pas une version installée
    }
    // À côté du dossier, sur le même disque : l'échange n'est qu'un renommage,
    // et on sait tout de suite si on a le droit d'écrire ici.
    work = Directory('${target.parent.path}${Platform.pathSeparator}.kliqplayer-update');
    if (work.existsSync()) work.deleteSync(recursive: true);
    work.createSync();
    String path(String p) => '${work!.path}${Platform.pathSeparator}$p';

    updateStatus = '…';
    final res = await http
        .get(Uri.parse('https://github.com/Perzivalle/kliqplayer/releases/latest/download/$asset'))
        .timeout(const Duration(minutes: 5));
    if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';
    File(path(asset)).writeAsBytesSync(res.bodyBytes);

    Directory(path('new')).createSync();
    final unpack = Platform.isLinux
        ? await Process.run('tar', ['-xzf', path(asset), '-C', path('new')])
        : Platform.isMacOS
            ? await Process.run('ditto', ['-x', '-k', path(asset), path('new')])
            : await Process.run('powershell', [
                '-NoProfile', '-Command', //
                'Expand-Archive -LiteralPath \$env:A -DestinationPath \$env:D',
              ], environment: {'A': path(asset), 'D': path('new')});
    final fresh = path('new${Platform.pathSeparator}$name');
    if (unpack.exitCode != 0 || !File('$fresh${Platform.pathSeparator}$binary').existsSync()) throw 'archive';

    // Lancé détaché : il survit à l'appli, attend qu'elle soit fermée, échange
    // les dossiers (remet l'ancien si ça rate), puis relance.
    final args = ['$pid', target.path, fresh, path('old'), work.path];
    if (Platform.isWindows) {
      File(path('swap.ps1')).writeAsStringSync(_swapPs1);
      await Process.start(
          'powershell', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', path('swap.ps1'), ...args],
          mode: ProcessStartMode.detached);
    } else {
      File(path('swap.sh')).writeAsStringSync(Platform.isMacOS ? _swapSh.replaceFirst('"\$1/kliqplayer"', 'open "\$1"') : _swapSh);
      await Process.start('sh', [path('swap.sh'), ...args], mode: ProcessStartMode.detached);
    }
    return true;
  } catch (_) {
    try {
      work?.deleteSync(recursive: true);
    } catch (_) {}
    return false;
  } finally {
    updateStatus = null;
  }
}

// Arguments : pid, dossier installé, nouveau dossier, où ranger l'ancien, dossier de travail.
const _swapSh = r'''
pid=$1; shift
while kill -0 "$pid" 2>/dev/null; do sleep 0.2; done
if mv "$1" "$3"; then
  mv "$2" "$1" || mv "$3" "$1"
fi
cd / && "$1/kliqplayer" >/dev/null 2>&1 &
rm -rf "$4"
''';

const _swapPs1 = r'''
param($procId, $target, $fresh, $old, $work)
Wait-Process -Id $procId -ErrorAction SilentlyContinue
# Windows garde les fichiers verrouillés un instant après la fermeture.
for ($i = 0; $i -lt 50; $i++) {
  try { Move-Item -LiteralPath $target -Destination $old -ErrorAction Stop; break } catch { Start-Sleep -Milliseconds 200 }
}
if (Test-Path -LiteralPath $old) {
  try { Move-Item -LiteralPath $fresh -Destination $target -ErrorAction Stop } catch { Move-Item -LiteralPath $old -Destination $target }
}
Start-Process -FilePath (Join-Path $target 'kliqplayer.exe')
Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
''';
