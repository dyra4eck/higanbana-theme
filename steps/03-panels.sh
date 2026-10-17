#!/usr/bin/env bash
# Higanbana, часть 3: панели.
#  - снизу: плавающий док по центру, только открытые/закреплённые приложения, автоскрытие
#  - сверху: тонкая строка (меню | часы | трей), автоскрытие, выезжает при наведении
# Бэкап раскладки: ~/.config/plasma-org.kde.plasma.desktop-appletsrc.bak-<дата>
set -euo pipefail

CFG=~/.config/plasma-org.kde.plasma.desktop-appletsrc
BK="$CFG.bak-$(date +%Y%m%d-%H%M%S)"
cp "$CFG" "$BK"
cp ~/.config/plasmashellrc ~/.config/plasmashellrc.bak-$(date +%Y%m%d-%H%M%S) 2>/dev/null || true

read -r -d '' JS <<'EOF' || true
var old = panels();

// --- верхняя строка ---
var topbar = new Panel;
topbar.location = "top";
topbar.height = 30;
topbar.floating = true;
topbar.hiding = "autohide";
topbar.addWidget("org.kde.plasma.kickoff");
topbar.addWidget("org.kde.plasma.panelspacer");
topbar.addWidget("org.kde.plasma.digitalclock");
topbar.addWidget("org.kde.plasma.panelspacer");
topbar.addWidget("org.kde.plasma.systemtray");

// --- док снизу ---
var dock = new Panel;
dock.location = "bottom";
dock.height = 52;
dock.floating = true;
dock.lengthMode = "fit";
dock.alignment = "center";
dock.hiding = "autohide";
dock.addWidget("org.kde.plasma.icontasks");

// старые панели убираем только после создания новых
for (var i = 0; i < old.length; i++) old[i].remove();
EOF

dbus-send --session --print-reply --dest=org.kde.plasmashell /PlasmaShell \
  org.kde.PlasmaShell.evaluateScript "string:$JS" >/dev/null

echo "Готово. Откат: cp $BK $CFG && systemctl --user restart plasma-plasmashell"
