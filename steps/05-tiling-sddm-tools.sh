#!/usr/bin/env bash
# Higanbana, часть 5.
#   tiling   — Krohnkite (автотайлинг с отступами) + скруглённые углы окон
#   sddm     — экран входа SDDM с лилией вместо gdm3
#   terminal — btop, cava, tmux в палитре Higanbana
# Запуск: ./higanbana-part5.sh                (всё)
#         ./higanbana-part5.sh tiling terminal (выборочно)
set -euo pipefail
PARTS=${*:-tiling sddm terminal}
GAP=${GAP:-10}
has() { [[ " $PARTS " == *" $1 "* ]]; }
TS=$(date +%Y%m%d-%H%M%S)

# =====================================================================
if has tiling; then
echo "==> [tiling] Krohnkite"
if ! kpackagetool6 -t KWin/Script -s krohnkite >/dev/null 2>&1; then
  URL=$(curl -fsSL 'https://codeberg.org/api/v1/repos/anametologin/Krohnkite/releases?limit=1' 2>/dev/null \
        | python3 -c 'import sys,json; d=json.load(sys.stdin); print(next(a["browser_download_url"] for a in d[0]["assets"] if a["name"].endswith(".kwinscript")))' 2>/dev/null || true)
  if [ -n "$URL" ]; then
    T=$(mktemp -d); curl -fL -o "$T/krohnkite.kwinscript" "$URL"
    kpackagetool6 -t KWin/Script -i "$T/krohnkite.kwinscript"; rm -rf "$T"
  else
    echo "    !! не смог скачать автоматически. Поставь руками:"
    echo "       System Settings → Window Management → KWin Scripts → Get New… → «Krohnkite»"
    echo "       и запусти скрипт ещё раз: ./higanbana-part5.sh tiling"
  fi
fi
if kpackagetool6 -t KWin/Script -s krohnkite >/dev/null 2>&1; then
  kwriteconfig6 --file kwinrc --group Plugins --key krohnkiteEnabled true
  for k in screenGapLeft screenGapRight screenGapTop screenGapBottom screenGapBetween; do
    kwriteconfig6 --file kwinrc --group Script-krohnkite --key $k "$GAP"
  done
  # диалоги, Spectacle, настройки и т.п. — плавающие
  kwriteconfig6 --file kwinrc --group Script-krohnkite --key floatUtility true
  # по умолчанию Krohnkite держит тайловые окна «под остальными» (layer 0) — из-за этого
  # окно в фокусе не поднимается над плавающими. 1 = обычный слой для всех.
  kwriteconfig6 --file kwinrc --group Script-krohnkite --key tiledWindowsLayer 1
  kwriteconfig6 --file kwinrc --group Script-krohnkite --key floatedWindowsLayer 1
  kwriteconfig6 --file kwinrc --group Script-krohnkite --key floatingClass "org.kde.spectacle,spectacle,systemsettings,org.kde.kcalc,pinentry-qt,polkit-kde-authentication-agent-1,org.kde.polkit-kde-authentication-agent-1,yakuake"
  # без рамок у тайловых окон смотрится чище
  kwriteconfig6 --file kwinrc --group Windows --key BorderlessMaximizedWindows true
  echo "    Krohnkite включён, отступы ${GAP}px"
fi

echo "==> [tiling] скруглённые углы (KDE-Rounded-Corners, сборка из исходников)"
if [ ! -f /usr/lib/x86_64-linux-gnu/qt6/plugins/kwin/effects/plugins/kwin4_effect_shapecorners.so ] \
   && ! ls /usr/lib/*/qt6/plugins/kwin/effects/plugins/*shapecorners* >/dev/null 2>&1; then
  sudo apt install -y git cmake g++ extra-cmake-modules kwin-dev qt6-base-private-dev \
       qt6-base-dev-tools libkf6kcmutils-dev libdrm-dev
  SRC=~/.local/src/KDE-Rounded-Corners
  rm -rf "$SRC"; mkdir -p ~/.local/src
  git clone -q --depth 1 https://github.com/matinlotfali/KDE-Rounded-Corners "$SRC"
  mkdir -p "$SRC/build" && cd "$SRC/build"
  if cmake .. >/dev/null && cmake --build . -j"$(nproc)" >/dev/null && sudo make install >/dev/null; then
    sh ../tools/install-autorun-test.sh >/dev/null 2>&1 || true   # пересборка после обновлений KWin
    echo "    собрано и установлено"
  else
    echo "    !! сборка не удалась — углы пропускаю (остальное работает)"
  fi
  cd - >/dev/null
fi
kwriteconfig6 --file kwinrc --group Plugins --key kwin4_effect_shapecornersEnabled true
echo "    радиус и красную обводку активного окна настрой в System Settings → Desktop Effects → Rounded Corners"
dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure || true
fi

# =====================================================================
if has sddm; then
echo "==> [sddm] экран входа"
LOCK=~/Pictures/higanbana-lock.png
[ -f "$LOCK" ] || { echo "    !! нет $LOCK — сначала запусти part4 (он делает кадр с лилией)"; exit 1; }
echo "sddm shared/default-x-display-manager select sddm" | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt install -y sddm sddm-theme-breeze kde-config-sddm

sudo install -m 644 "$LOCK" /usr/share/sddm/themes/breeze/higanbana.png
sudo tee /usr/share/sddm/themes/breeze/theme.conf.user >/dev/null <<'EOF'
[General]
type=image
background=/usr/share/sddm/themes/breeze/higanbana.png
EOF
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/10-higanbana.conf >/dev/null <<'EOF2'
[Theme]
Current=breeze
CursorTheme=Bibata-Modern-Ice
CursorSize=24
Font=Inter,10
EOF2
sudo rm -f /etc/sddm.conf.d/20-wayland.conf   # X11-greeter: на Wayland KWin показывает экранную клавиатуру
# /etc/sddm.conf читается последним и перекрывает чужие conf.d (например 50-ubuntu-budgie.conf)
sudo touch /etc/sddm.conf
setsddm() { # section key value
  if grep -q "^\[$1\]" /etc/sddm.conf; then
    if sudo sed -n "/^\[$1\]/,/^\[/p" /etc/sddm.conf | grep -q "^$2="; then
      sudo sed -i "/^\[$1\]/,/^\[/{s|^$2=.*|$2=$3|}" /etc/sddm.conf
    else
      sudo sed -i "/^\[$1\]/a $2=$3" /etc/sddm.conf
    fi
  else
    printf '\n[%s]\n%s=%s\n' "$1" "$2" "$3" | sudo tee -a /etc/sddm.conf >/dev/null
  fi
}
setsddm Theme Current breeze
setsddm General InputMethod ""      # без экранной клавиатуры
# цвета/шрифты Plasma для экрана входа (без Kvantum — у пользователя sddm его нет)
SDDM_HOME=$(getent passwd sddm | cut -d: -f6); SDDM_HOME=${SDDM_HOME:-/var/lib/sddm}
sudo mkdir -p "$SDDM_HOME/.config"
grep -v '^widgetStyle=' ~/.config/kdeglobals | sudo tee "$SDDM_HOME/.config/kdeglobals" >/dev/null
printf '[Mouse]\ncursorTheme=Bibata-Modern-Ice\ncursorSize=24\n' | sudo tee "$SDDM_HOME/.config/kcminputrc" >/dev/null
[ -d ~/.local/share/icons/Bibata-Modern-Ice ] && sudo cp -r ~/.local/share/icons/Bibata-Modern-Ice /usr/share/icons/
sudo chown -R sddm:sddm "$SDDM_HOME/.config" 2>/dev/null || true

echo /usr/sbin/sddm | sudo tee /etc/X11/default-display-manager >/dev/null
[ -x /usr/sbin/sddm ] || echo /usr/bin/sddm | sudo tee /etc/X11/default-display-manager >/dev/null
sudo systemctl disable gdm3 2>/dev/null || true
sudo systemctl enable --force sddm
echo "    SDDM будет при следующей загрузке."
echo "    Если что-то пойдёт не так: Ctrl+Alt+F3 → войти → sudo systemctl disable sddm && sudo systemctl enable --force gdm3 && sudo reboot"
fi

# =====================================================================
if has terminal; then
echo "==> [terminal] btop, cava, tmux"
sudo apt install -y btop cava tmux

# --- btop ---
mkdir -p ~/.config/btop/themes
cat > ~/.config/btop/themes/higanbana.theme <<'EOF'
theme[main_bg]=""
theme[main_fg]="#e6e1df"
theme[title]="#e6e1df"
theme[hi_fg]="#e0353b"
theme[selected_bg]="#5a1418"
theme[selected_fg]="#ffffff"
theme[inactive_fg]="#4a4648"
theme[graph_text]="#8a8486"
theme[meter_bg]="#1a1a1e"
theme[proc_misc]="#c4161c"
theme[cpu_box]="#5a1418"
theme[mem_box]="#5a1418"
theme[net_box]="#5a1418"
theme[proc_box]="#5a1418"
theme[div_line]="#232328"
theme[temp_start]="#8a8486"
theme[temp_mid]="#d6963c"
theme[temp_end]="#e0353b"
theme[cpu_start]="#5a1418"
theme[cpu_mid]="#c4161c"
theme[cpu_end]="#ff6b6b"
theme[free_start]="#2a2a30"
theme[free_mid]="#5a5658"
theme[free_end]="#8a8486"
theme[cached_start]="#3a1418"
theme[cached_mid]="#8c1016"
theme[cached_end]="#c4161c"
theme[available_start]="#2a2a30"
theme[available_mid]="#5a5658"
theme[available_end]="#b0a8aa"
theme[used_start]="#5a1418"
theme[used_mid]="#c4161c"
theme[used_end]="#ff6b6b"
theme[download_start]="#3a1418"
theme[download_mid]="#8c1016"
theme[download_end]="#e0353b"
theme[upload_start]="#2a2a30"
theme[upload_mid]="#8a8486"
theme[upload_end]="#e6e1df"
theme[process_start]="#8a8486"
theme[process_mid]="#c4161c"
theme[process_end]="#ff6b6b"
EOF
BC=~/.config/btop/btop.conf
touch "$BC"
setbtop() { grep -q "^$1 *=" "$BC" && sed -i "s|^$1 *=.*|$1 = $2|" "$BC" || echo "$1 = $2" >> "$BC"; }
setbtop color_theme '"higanbana"'
setbtop theme_background False
setbtop rounded_corners True
setbtop graph_symbol '"braille"'

# --- cava ---
mkdir -p ~/.config/cava
[ -f ~/.config/cava/config ] && cp ~/.config/cava/config ~/.config/cava/config.bak-$TS
cat > ~/.config/cava/config <<'EOF'
[general]
framerate = 60
bar_width = 2
bar_spacing = 1

[input]
method = pipewire
source = auto

[output]
method = noncurses

[color]
background = default
gradient = 1
gradient_count = 3
gradient_color_1 = '#5a1418'
gradient_color_2 = '#c4161c'
gradient_color_3 = '#ff6b6b'

[smoothing]
noise_reduction = 77
EOF

# --- tmux ---
[ -f ~/.tmux.conf ] && cp ~/.tmux.conf ~/.tmux.conf.bak-$TS
cat > ~/.tmux.conf <<'EOF'
# Higanbana tmux
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",*:RGB"
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g history-limit 50000
set -sg escape-time 10
set -g status-position top
set -g status-interval 5

set -g status-style "bg=default,fg=#8a8486"
set -g status-left-length 40
set -g status-left  "#[fg=#c4161c,bold] 彼岸花 #[fg=#5a1418]│ #[fg=#e6e1df]#S #[fg=#5a1418]│ "
set -g status-right "#[fg=#8a8486]%H:%M #[fg=#5a1418]│ #[fg=#c4161c]#h "
setw -g window-status-format         "#[fg=#8a8486] #I #W "
setw -g window-status-current-format "#[fg=#ffffff,bg=#5a1418,bold] #I #W "
setw -g window-status-separator ""

set -g pane-border-style        "fg=#232328"
set -g pane-active-border-style "fg=#8c1016"
set -g message-style            "bg=#141417,fg=#e6e1df"
set -g mode-style               "bg=#8c1016,fg=#ffffff"
setw -g clock-mode-colour "#c4161c"

# удобные сплиты в текущей папке
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind r source-file ~/.tmux.conf \; display "reloaded"
EOF
echo "    btop / cava / tmux настроены"
fi

echo
echo "Готово: $PARTS"
has tiling && echo "  tiling: перелогинься, чтобы углы и Krohnkite точно подхватились. Шорткаты — System Settings → Shortcuts → KWin (раздел Krohnkite)."
has sddm   && echo "  sddm: перезагрузись, чтобы увидеть новый экран входа."
has terminal && echo "  terminal: btop, cava (включи музыку), tmux."
