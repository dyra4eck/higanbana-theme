#!/usr/bin/env bash
# Higanbana, шаг 8:
#   monitors — живые обои (и их настройки) с основного экрана на все остальные мониторы
#   flat     — строгий минимализм: стиль Breeze вместо Kvantum (без градиентов и прозрачности окон),
#              без контуров у рамок окон
#   overview — горячий угол без случайных срабатываний + диагностика просадки FPS
# Запуск: ./steps/08-monitors-flat-overview.sh                  (всё)
#         ./steps/08-monitors-flat-overview.sh flat             (выборочно)
set -euo pipefail
PARTS=${*:-monitors flat overview}
has() { [[ " $PARTS " == *" $1 "* ]]; }
TS=$(date +%Y%m%d-%H%M%S)
cp ~/.config/plasma-org.kde.plasma.desktop-appletsrc ~/.config/plasma-org.kde.plasma.desktop-appletsrc.bak-$TS
cp ~/.config/kdeglobals ~/.config/kdeglobals.bak-$TS
cp ~/.config/kwinrc ~/.config/kwinrc.bak-$TS

js() { dbus-send --session --print-reply --dest=org.kde.plasmashell /PlasmaShell \
         org.kde.PlasmaShell.evaluateScript "string:$1" >/dev/null; }

# =====================================================================
if has monitors; then
echo "==> [monitors] обои на все экраны"
read -r -d '' JS <<'EOF' || true
var all = desktops();
var src = null;
for (var i = 0; i < all.length; i++) if (all[i].screen == 0) { src = all[i]; break; }
if (src) {
  var plugin = src.wallpaperPlugin;
  src.currentConfigGroup = ["Wallpaper", plugin, "General"];
  var keys = src.configKeys;
  var vals = {};
  for (var k = 0; k < keys.length; k++) vals[keys[k]] = src.readConfig(keys[k]);
  for (var i = 0; i < all.length; i++) {
    var d = all[i];
    if (d.screen <= 0) continue;
    d.wallpaperPlugin = plugin;
    d.currentConfigGroup = ["Wallpaper", plugin, "General"];
    for (var key in vals) d.writeConfig(key, vals[key]);
    d.reloadConfig();
  }
}
EOF
js "$JS"
echo "    готово. Если второй монитор подключишь позже — запусти: ./steps/08-monitors-flat-overview.sh monitors"
fi

# =====================================================================
if has flat; then
echo "==> [flat] Breeze вместо Kvantum, без градиентов"
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Breeze
# рамки/контуры окон Breeze — выключены, заголовок сливается с окном
kwriteconfig6 --file breezerc --group Common --key OutlineIntensity OutlineOff
kwriteconfig6 --file breezerc --group Common --key ShadowStrength 160
kwriteconfig6 --file breezerc --group Common --key ShadowSize ShadowMedium
# панели Plasma без лишних переливов: тема Breeze Dark (плоская) + наша схема цветов
plasma-apply-desktoptheme breeze-dark >/dev/null 2>&1 || true
dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure || true
echo "    применится к приложениям после их перезапуска (проще — перелогиниться)."
echo "    вернуть Kvantum: kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum"
fi

# =====================================================================
if has overview; then
echo "==> [overview] горячий угол"
# угол срабатывает после короткой задержки (не от случайного касания) и не дёргается повторно
kwriteconfig6 --file kwinrc --group Windows --key ElectricBorderDelay 120
kwriteconfig6 --file kwinrc --group Windows --key ElectricBorderCooldown 400
dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure || true

echo "==> [overview] диагностика (для поиска причины просадки)"
Q=$(command -v qdbus6 || command -v qdbus || ls /usr/lib/qt6/bin/qdbus 2>/dev/null || true)
if [ -n "$Q" ]; then
  $Q org.kde.KWin /KWin org.kde.KWin.supportInformation 2>/dev/null \
    | grep -iE '^(OpenGL (vendor|renderer)|Driver:|GPU class|Compositing Type|Animation speed)|^Screen [0-9]|Name:|Refresh Rate|Enabled:|Geometry' \
    | head -40 > ~/higanbana-kwin-info.txt || true
  echo "    сводка KWin → ~/higanbana-kwin-info.txt"
fi
for c in /sys/class/drm/card*-*; do
  [ "$(cat "$c/status" 2>/dev/null)" = connected ] || continue
  card=${c##*/}; card=${card%%-*}
  drv=$(basename "$(readlink -f /sys/class/drm/$card/device/driver)")
  echo "    монитор ${c##*/} подключён к $card ($drv)"
done | tee -a ~/higanbana-kwin-info.txt
fi

echo
echo "Готово: $PARTS. Бэкапы конфигов: ~/.config/*.bak-$TS"
