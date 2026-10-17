#!/usr/bin/env bash
# Higanbana, часть 2: Kvantum (полупрозрачные окна с размытием), красные папки Papirus,
# GTK-приложения (Firefox и др.) в цветах схемы.
set -euo pipefail
OPACITY=${OPACITY:-18}   # насколько прозрачны окна, 0–90 (больше = прозрачнее)

echo "==> пакеты"
sudo apt install -y qt-style-kvantum qt-style-kvantum-themes breeze-gtk-theme kde-config-gtk-style

BK=~/.config/higanbana-backup-$(date +%Y%m%d-%H%M%S)-p2
mkdir -p "$BK"; cp -a ~/.config/kdeglobals "$BK/" 2>/dev/null || true
[ -d ~/.config/Kvantum ] && cp -a ~/.config/Kvantum "$BK/" || true
echo "    бэкап: $BK"

echo "==> Kvantum-тема HiganbanaKv"
BASE=""
for t in KvDarkRed KvFlatRed KvArcDark KvGnomeDark KvSimplicityDark; do
  [ -f /usr/share/Kvantum/$t/$t.kvconfig ] && { BASE=$t; break; }
done
[ -n "$BASE" ] || { echo "не нашёл базовую тему в /usr/share/Kvantum"; ls /usr/share/Kvantum; exit 1; }
echo "    основа: $BASE"
D=~/.config/Kvantum/HiganbanaKv
mkdir -p "$D"
cp "/usr/share/Kvantum/$BASE/$BASE.svg" "$D/HiganbanaKv.svg"
cp "/usr/share/Kvantum/$BASE/$BASE.kvconfig" "$D/HiganbanaKv.kvconfig"
K="$D/HiganbanaKv.kvconfig"

setkv() { # section key value
  python3 - "$K" "$1" "$2" "$3" <<'PY'
import sys,re
f,sec,key,val=sys.argv[1:]
lines=open(f).read().split('\n'); out=[]; insec=False; done=False
for i,l in enumerate(lines):
    if l.strip().startswith('['):
        if insec and not done: out.append(f'{key}={val}'); done=True
        insec = (l.strip()==f'[{sec}]')
    elif insec and re.match(rf'\s*{re.escape(key)}\s*=',l):
        if not done: out.append(f'{key}={val}'); done=True
        continue
    out.append(l)
if not done:
    if not insec: out.append(f'[{sec}]')
    out.append(f'{key}={val}')
open(f,'w').write('\n'.join(out))
PY
}
# прозрачность и размытие
setkv %General translucent_windows true
setkv %General blurring true
setkv %General popup_blurring true
setkv %General reduce_window_opacity "$OPACITY"
setkv %General reduce_menu_opacity 10
setkv %General composite true
# палитра Higanbana
for kv in \
  window.color=#0b0b0d base.color=#0f0f12 alt.base.color=#161619 button.color=#1a1a1e \
  light.color=#26262b mid.light.color=#1f1f23 dark.color=#050506 mid.color=#141417 \
  highlight.color=#8c1016 inactive.highlight.color=#4a0e12 \
  text.color=#e6e1df window.text.color=#e6e1df button.text.color=#e6e1df \
  disabled.text.color=#5a5658 tooltip.text.color=#e6e1df highlight.text.color=#ffffff \
  link.color=#e85a5e link.visited.color=#a0484c progress.indicator.text.color=#ffffff; do
  setkv GeneralColors "${kv%%=*}" "${kv#*=}"
done

mkdir -p ~/.config/Kvantum
printf '[General]\ntheme=HiganbanaKv\n' > ~/.config/Kvantum/kvantum.kvconfig
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum

echo "==> красные папки Papirus"
if ! command -v papirus-folders >/dev/null; then
  T=$(mktemp -d)
  git clone -q --depth 1 https://github.com/PapirusDevelopmentTeam/papirus-folders.git "$T/pf"
  sudo install -m 755 "$T/pf/papirus-folders" /usr/local/bin/papirus-folders
  rm -rf "$T"
fi
sudo papirus-folders -C red --theme Papirus-Dark

echo
echo "Готово. Перезапусти приложения (или перелогинься)."
echo "Firefox: Настройки → Расширения и темы → Темы → «Системная тема — авто»."
echo "Откат Kvantum: kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Breeze"
