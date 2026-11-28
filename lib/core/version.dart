import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'strings.dart';

/// Version de l'appli, affichée dans Réglages › À propos. La même que dans
/// pubspec.yaml (un test le vérifie).
const appVersion = '1.5.0';

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
/// page de la release. [onStep] : [updateStatus] vient de changer (à afficher).
/// Tout est noté dans kliqplayer-update.log, à côté du dossier installé.
Future<bool> prepareUpdate({void Function()? onStep}) async {
  void step(String s) {
    updateStatus = s;
    onStep?.call();
  }

  File? log;
  void note(String s) {
    try {
      log?.writeAsStringSync('${DateTime.now().toIso8601String()}  $s\n', mode: FileMode.append);
    } catch (_) {}
  }

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
    log = File('${target.parent.path}${Platform.pathSeparator}kliqplayer-update.log');
    note('$appVersion → ${newVersion ?? '?'} : ${target.path}');
    work = Directory('${target.parent.path}${Platform.pathSeparator}.kliqplayer-update');
    if (work.existsSync()) work.deleteSync(recursive: true);
    work.createSync();
    String path(String p) => '${work!.path}${Platform.pathSeparator}$p';

    // Téléchargement, avec son avancement en pour cent.
    step('0 %');
    final client = http.Client();
    try {
      final res = await client
          .send(http.Request('GET', Uri.parse('https://github.com/Perzivalle/kliqplayer/releases/latest/download/$asset')))
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';
      final total = res.contentLength ?? 0;
      final sink = File(path(asset)).openWrite();
      var got = 0, shown = -1;
      await for (final chunk in res.stream.timeout(const Duration(seconds: 60))) {
        sink.add(chunk);
        got += chunk.length;
        final percent = total > 0 ? got * 100 ~/ total : 0;
        if (percent != shown) step('${shown = percent} %');
      }
      await sink.close();
      note('téléchargé : $got octets');
    } finally {
      client.close();
    }

    step(tr('Décompression…'));
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
    if (unpack.exitCode != 0 || !File('$fresh${Platform.pathSeparator}$binary').existsSync()) {
      throw 'archive : ${unpack.exitCode} ${unpack.stderr}';
    }
    note('décompressé');
    step(tr('Redémarrage…'));

    // Lancé détaché : il survit à l'appli, attend qu'elle soit fermée, échange
    // les dossiers (remet l'ancien si ça rate), puis relance.
    // (Hors du dossier remplacé : sous Windows, un processus qui y est
    // verrouille le dossier, qu'on ne pourrait plus déplacer.)
    final args = ['$pid', target.path, fresh, path('old'), work.path, log.path];
    final env = {'KP_FAILED': tr('La mise à jour n\'a pas pu s\'installer. Détails :')};
    if (Platform.isWindows) {
      // (Avec BOM : sans lui, Windows PowerShell lit le script en ANSI.)
      File(path('swap.ps1')).writeAsStringSync('\uFEFF$_swapPs1');
      // Lanc\u00E9 par WMI : son parent est alors le service WMI, pas nous. Lanc\u00E9
      // d'ici (m\u00EAme d\u00E9tach\u00E9), Windows peut le fermer en m\u00EAme temps que l'appli,
      // et rien ne s'installait. On attend de savoir qu'il tourne bien.
      // (Le message d'\u00E9chec passe en argument : WMI ne transmet pas notre
      // environnement.)
      String q(String s) => '"${s.replaceAll('"', "'")}"';
      final cmd = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File '
          '${[path('swap.ps1'), ...args, env['KP_FAILED']!].map(q).join(' ')}';
      final launch = await Process.run('powershell', [
        '-NoProfile', '-Command', //
        r'$r = Invoke-CimMethod -ClassName Win32_Process -MethodName Create '
            r'-Arguments @{ CommandLine = $env:KP_CMD; CurrentDirectory = $env:KP_DIR } -ErrorAction Stop; '
            r'if ($r.ReturnValue -ne 0) { throw "Win32_Process.Create : $($r.ReturnValue)" }; $r.ProcessId',
      ], environment: {'KP_CMD': cmd, 'KP_DIR': target.parent.path});
      if (launch.exitCode != 0) {
        // WMI indisponible : lanc\u00E9 comme avant, en dernier recours.
        note('WMI : ${launch.stderr}'.trim());
        await Process.start(
            'powershell', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', path('swap.ps1'), ...args, env['KP_FAILED']!],
            mode: ProcessStartMode.detached, workingDirectory: target.parent.path);
      } else {
        note('script : processus ${'${launch.stdout}'.trim()}');
      }
    } else {
      File(path('swap.sh')).writeAsStringSync(Platform.isMacOS ? _swapSh.replaceFirst('"\$1/kliqplayer"', 'open "\$1"') : _swapSh);
      await Process.start('sh', [path('swap.sh'), ...args],
          mode: ProcessStartMode.detached, workingDirectory: target.parent.path, environment: env);
    }
    note('script lancé, fermeture');
    return true;
  } catch (e) {
    note('échec : $e');
    try {
      work?.deleteSync(recursive: true);
    } catch (_) {}
    updateStatus = null;
    return false;
  }
  // (Réussi : « Redémarrage… » reste affiché jusqu'à la fermeture.)
}

// Arguments : pid, dossier installé, nouveau dossier, où ranger l'ancien,
// dossier de travail, journal. Chaque étape est notée dans le journal ; un
// échec est signalé (notification) et l'ancienne version relancée.
const _swapSh = r'''
pid=$1; shift
log=$5
note() { echo "$(date '+%Y-%m-%dT%H:%M:%S')  $*" >> "$log"; }
# Au plus 20 s pour que l'appli se ferme, sinon on la ferme.
n=0
while kill -0 "$pid" 2>/dev/null; do
  n=$((n + 1)); [ $n -gt 100 ] && { note "toujours ouverte : arrêt forcé"; kill -9 "$pid" 2>/dev/null; }
  sleep 0.2
done
note "appli fermée"
ok=0
if mv "$1" "$3" 2>>"$log"; then
  if mv "$2" "$1" 2>>"$log"; then ok=1; else mv "$3" "$1"; fi
fi
if [ $ok = 1 ]; then note "installée"; else
  note "échec de l'échange, ancienne version gardée"
  msg="$KP_FAILED $log"
  command -v notify-send >/dev/null && notify-send KliqPlayer "$msg"
  command -v osascript >/dev/null && osascript -e "display notification \"$msg\" with title \"KliqPlayer\""
fi
cd / && "$1/kliqplayer" >/dev/null 2>&1 &
note "relancée"
rm -rf "$4"
''';

const _swapPs1 = r'''
param($procId, $target, $fresh, $old, $work, $log, $failed)
# Journal à côté du dossier, ou dans %TEMP% si on ne peut pas y écrire.
function Note($s) {
  $line = "{0:s}  {1}" -f (Get-Date), $s
  try { Add-Content -LiteralPath $log -Value $line -ErrorAction Stop }
  catch { Add-Content -LiteralPath (Join-Path $env:TEMP 'kliqplayer-update.log') -Value "$line  ($_)" -ErrorAction SilentlyContinue }
}
Note 'script démarré'
$problem = $null
# Au plus 20 s pour que l'appli se ferme, sinon on la ferme.
Wait-Process -Id $procId -Timeout 20 -ErrorAction SilentlyContinue
if (Get-Process -Id $procId -ErrorAction SilentlyContinue) {
  Note 'toujours ouverte : arrêt forcé'
  Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
  Start-Sleep -Milliseconds 500
}
Note 'appli fermée'
# Le dossier installé reste en place : on copie la nouvelle version par-dessus.
# kliqplayer.exe garde ainsi son chemin (et reste le même fichier), et les
# raccourcis vers lui restent bons ; renommer le dossier les faisait suivre
# l'ancien. L'ancien contenu est d'abord sauvegardé, pour le remettre si ça rate.
function CopyOver($from, $to) {
  Get-ChildItem -LiteralPath $from -Force | Copy-Item -Destination $to -Recurse -Force -ErrorAction Stop
}
$moved = $false
try {
  New-Item -ItemType Directory -Path $old -Force -ErrorAction Stop | Out-Null
  CopyOver $target $old
  # Windows garde les fichiers verrouillés un instant après la fermeture.
  for ($i = 0; $i -lt 50; $i++) {
    try { CopyOver $fresh $target; $moved = $true; break }
    catch { $problem = $_; Start-Sleep -Milliseconds 200 }
  }
  if ($moved) {
    # Ce que la nouvelle version n'a plus.
    $keep = @(Get-ChildItem -LiteralPath $fresh -Force -Recurse | ForEach-Object { $_.FullName.Substring($fresh.Length) })
    Get-ChildItem -LiteralPath $target -Force -Recurse | Sort-Object { $_.FullName.Length } -Descending |
      Where-Object { $keep -notcontains $_.FullName.Substring($target.Length) } |
      Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Note 'installée'
  } else {
    CopyOver $old $target
  }
} catch { $problem = $_; $moved = $false }
if (-not $moved) { Note "échec de l'installation, ancienne version gardée : $problem" }
# Relancée par l'Explorateur, comme d'un double-clic : lancée d'ici, elle
# hériterait de la fenêtre cachée de ce script et ne s'afficherait pas.
try {
  Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + (Join-Path $target 'kliqplayer.exe') + '"') -ErrorAction Stop
  Note 'relancée'
} catch { $problem = $_; $moved = $false; Note "relance impossible : $problem" }
if (-not $moved) {
  Add-Type -AssemblyName System.Windows.Forms
  [System.Windows.Forms.MessageBox]::Show("$failed`n`n$problem`n`n$log", 'KliqPlayer') | Out-Null
}
Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
''';
