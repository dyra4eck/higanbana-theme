#!/usr/bin/env bash
# Higanbana, часть 6.
#   boot     — Plymouth (заставка с лилией + ввод пароля диска) и тема GRUB
#   apps     — Telegram, Obsidian, Firefox
#   widget   — часы на рабочем столе
# Запуск из распакованной папки:  ./higanbana-part6.sh            (всё)
#                                 ./higanbana-part6.sh apps widget (выборочно)
#   GRUB_TIMEOUT=5 ./higanbana-part6.sh boot   — сколько секунд показывать меню (по умолчанию 3)
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
A=$(readlink -f "$PWD/../assets")
PARTS=${*:-boot apps widget}
has() { [[ " $PARTS " == *" $1 "* ]]; }
TS=$(date +%Y%m%d-%H%M%S)

# =====================================================================
if has boot; then
echo "==> [boot] Plymouth"
sudo apt install -y plymouth
BKDIR=/var/backups/higanbana-$TS; sudo mkdir -p "$BKDIR"
sudo cp -a /etc/default/grub "$BKDIR/" 2>/dev/null || true
readlink -f /usr/share/plymouth/themes/default.plymouth | sudo tee "$BKDIR/plymouth-previous" >/dev/null || true

T=/usr/share/plymouth/themes/higanbana
sudo mkdir -p "$T"
sudo cp "$A"/plymouth/* "$T/"
sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth "$T/higanbana.plymouth" 200
sudo update-alternatives --set default.plymouth "$T/higanbana.plymouth"

# убедиться, что заставка вообще включена (quiet splash)
CUR=$(. /etc/default/grub; echo "${GRUB_CMDLINE_LINUX_DEFAULT:-}")
NEED="$CUR"
[[ " $CUR " == *" quiet "* ]]  || NEED="$NEED quiet"
[[ " $CUR " == *" splash "* ]] || NEED="$NEED splash"

echo "==> [boot] GRUB"
G=/boot/grub/themes/higanbana
sudo mkdir -p "$G"
sudo cp "$A"/grub/* "$G/"
sudo tee /etc/default/grub.d/99-higanbana.cfg >/dev/null <<EOF
# Higanbana — тема GRUB (удалить файл и выполнить sudo update-grub, чтобы откатить)
GRUB_THEME="$G/theme.txt"
GRUB_GFXMODE=auto
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=${GRUB_TIMEOUT:-3}
GRUB_CMDLINE_LINUX_DEFAULT="$(echo $NEED | xargs)"
EOF
sudo update-grub
echo "==> [boot] пересборка initramfs (может занять минуту)"
sudo update-initramfs -u

cat <<EOF
    Готово. Откат:
      sudo update-alternatives --set default.plymouth $(cat "$BKDIR/plymouth-previous" 2>/dev/null || echo /usr/share/plymouth/themes/bgrt/bgrt.plymouth)
      sudo rm /etc/default/grub.d/99-higanbana.cfg && sudo update-grub && sudo update-initramfs -u
    Предпросмотр заставки без перезагрузки:  ./higanbana-part6.sh preview
EOF
fi

# =====================================================================
if has preview; then
  # заставка откроется в отдельном окне (через XWayland). Если экран «замрёт» —
  # Ctrl+Alt+F3, войди и выполни: sudo plymouth quit
  sudo apt install -y plymouth-x11
  trap 'sudo plymouth quit 2>/dev/null || true' EXIT
  sudo --preserve-env=DISPLAY,XAUTHORITY plymouthd --kernel-command-line="quiet splash"
  sudo plymouth show-splash
  for p in 10 30 50 70 90; do sudo plymouth system-update --progress=$p; sleep 1; done
  sudo plymouth ask-for-password --prompt="Please unlock disk (preview)" >/dev/null 2>&1 &
  sleep 6
  sudo plymouth quit
fi

# =====================================================================
if has apps; then
echo "==> [apps] Telegram"
mkdir -p ~/Pictures
cp "$A/tg/Higanbana.tdesktop-theme" ~/Pictures/Higanbana.tdesktop-theme
echo "    тема лежит в ~/Pictures/Higanbana.tdesktop-theme"
echo "    открой её в Telegram: отправь файл себе в «Избранное» и нажми на него → Apply"

echo "==> [apps] Obsidian"
found=0
for cfg in ~/.config/obsidian/obsidian.json \
           ~/.var/app/md.obsidian.Obsidian/config/obsidian/obsidian.json \
           ~/snap/obsidian/current/.config/obsidian/obsidian.json; do
  [ -f "$cfg" ] || continue
  while IFS= read -r v; do
    [ -d "$v/.obsidian" ] || continue
    mkdir -p "$v/.obsidian/snippets"
    cp "$A/higanbana-obsidian.css" "$v/.obsidian/snippets/higanbana.css"
    python3 - "$v/.obsidian/appearance.json" <<'PY'
import json,sys,os
p=sys.argv[1]; d=json.load(open(p)) if os.path.exists(p) else {}
s=d.setdefault("enabledCssSnippets",[])
if "higanbana" not in s: s.append("higanbana")
d["theme"]="obsidian"
json.dump(d,open(p,"w"),indent=2)
PY
    echo "    $v — сниппет включён"; found=1
  done < <(python3 -c 'import json,sys; [print(x["path"]) for x in json.load(open(sys.argv[1])).get("vaults",{}).values()]' "$cfg")
done
[ $found = 1 ] || echo "    хранилища не найдены. Скопируй assets/higanbana-obsidian.css в <хранилище>/.obsidian/snippets/ и включи в Settings → Appearance → CSS snippets"
echo "    (если Obsidian открыт — перезапусти его)"

echo "==> [apps] Firefox"
ffound=0
for root in ~/.mozilla/firefox ~/.config/mozilla/firefox ~/snap/firefox/common/.mozilla/firefox ~/.var/app/org.mozilla.firefox/.mozilla/firefox; do
  [ -d "$root" ] || continue
  for prof in "$root"/*/; do
    [ -f "$prof/prefs.js" ] || continue
    mkdir -p "$prof/chrome"
    [ -f "$prof/chrome/userChrome.css" ] && cp "$prof/chrome/userChrome.css" "$prof/chrome/userChrome.css.bak-$TS"
    cp "$A/userChrome.css" "$prof/chrome/userChrome.css"
    touch "$prof/user.js"
    sed -i '/toolkit.legacyUserProfileCustomizations.stylesheets/d' "$prof/user.js"
    echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >> "$prof/user.js"
    echo "    $prof"; ffound=1
  done
done
[ $ffound = 1 ] || echo "    профиль Firefox не найден"
echo "    перезапусти Firefox; тема: Настройки → Расширения и темы → «Системная тема — авто»"
fi

# =====================================================================
if has widget; then
echo "==> [widget] часы Higanbana"
if kpackagetool6 -t Plasma/Applet -s dev.higanbana.clock >/dev/null 2>&1; then
  kpackagetool6 -t Plasma/Applet -u "$A/clock"
else
  kpackagetool6 -t Plasma/Applet -i "$A/clock"
fi
read -r -d '' JS <<'EOF' || true
var ds = desktops();
for (var i = 0; i < ds.length; i++) {
  var d = ds[i];
  if (d.screen != 0) continue;
  if (d.widgets("dev.higanbana.clock").length > 0) continue;
  var g = screenGeometry(0);
  d.addWidget("dev.higanbana.clock", Math.round(g.width * 0.06), Math.round(g.height * 0.34), 460, 240);
}
EOF
dbus-send --session --print-reply --dest=org.kde.plasmashell /PlasmaShell \
  org.kde.PlasmaShell.evaluateScript "string:$JS" >/dev/null && echo "    добавлены на рабочий стол (перетащить: зажми и тяни; удалить: правый клик → Remove)"
fi

echo
echo "Готово: $PARTS"
has boot && echo "  boot: перезагрузись — увидишь меню GRUB, затем заставку с лилией."
true
