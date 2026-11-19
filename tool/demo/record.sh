#!/bin/sh
# Filme la vidéo de présentation en une prise : le lancement (le baladeur monte,
# la prise se branche, l'écran s'allume), puis l'enchaînement de
# presentation.json. Les temps morts (préparation de la démo) se coupent au montage.
# Usage : tool/demo/record.sh [sortie.mp4]   (Hyprland, wf-recorder)
set -e
here=$(cd "$(dirname "$0")" && pwd)
out=${1:-$HOME/Videos/kliqplayer-presentation.mp4}
app=${KLIQPLAYER:-$HOME/Downloads/KliqPlayer/kliqplayer}
go=/tmp/kliqplayer-demo-go # le même que « go » dans presentation.json
rm -f "$go"
pkill -x kliqplayer || true
wf-recorder -y -f "$out" &
rec=$!
LECTEUR_DEMO="$here/presentation.json" "$app" 2>&1 | while IFS= read -r line; do
  case $line in
    *'[demo] prêt'*) touch "$go" ;;
    *'[demo] fin'*) kill -INT "$rec"; pkill -x kliqplayer; break ;;
  esac
done
wait "$rec" 2>/dev/null || true
echo "Vidéo : $out"
