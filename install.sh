#!/usr/bin/env bash
# Установка темы Higanbana на (новую) систему с KDE Plasma 6.
#   ./install.sh            — из снимка home/ + system/ (если он есть), иначе по шагам steps/
#   ./install.sh --steps    — принудительно по шагам (чистая установка без снимка)
# Запускать в сессии Plasma, не из TTY.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
SRC=$PWD
A=$SRC/assets
TS=$(date +%Y%m%d-%H%M%S)

MODE=snapshot
[ -f home/.config/kdeglobals ] || MODE=steps
[ "${1:-}" = --steps ] && MODE=steps
echo "Режим установки: $MODE"

# ---------- общее: обои и тема Telegram ----------
mkdir -p ~/Videos/wallpapers ~/Pictures
cp -n "$A"/wallpapers/*.mp4 ~/Videos/wallpapers/
cp "$A/tg/Higanbana.tdesktop-theme" ~/Pictures/

if [ "$MODE" = steps ]; then
  # ---------- чистая установка по шагам ----------
  for s in steps/01-plasma.sh steps/02-kvantum-gtk.sh steps/03-panels.sh steps/04-terminal-cursor-lock.sh; do
    echo; echo "######## $s"; bash "$s"
  done
  echo; echo "######## steps/05-tiling-sddm-tools.sh"; bash steps/05-tiling-sddm-tools.sh terminal tiling sddm
  sudo apt remove -y qt6-virtualkeyboard-plugin 2>/dev/null || true
  echo; echo "######## steps/06-boot-apps-widget.sh"; bash steps/06-boot-apps-widget.sh boot apps widget
  echo; echo "######## steps/07-yazi.sh"; bash steps/07-yazi.sh
  echo; echo "######## steps/08-monitors-flat-overview.sh"; bash steps/08-monitors-flat-overview.sh monitors flat overview
else
  # ---------- установка из снимка ----------
  echo "==> пакеты"
  sudo apt update
  sudo apt install -y kde-plasma-desktop kde-spectacle konsole-kpart sddm sddm-theme-breeze kde-config-sddm \
    fonts-inter fonts-jetbrains-mono papirus-icon-theme \
    qt-style-kvantum qt-style-kvantum-themes breeze-gtk-theme kde-config-gtk-style \
    starship fastfetch eza bat btop cava tmux ffmpeg curl xz-utils git plymouth \
    cmake g++ extra-cmake-modules kwin-dev qt6-base-private-dev qt6-base-dev-tools libkf6kcmutils-dev libdrm-dev
  sudo apt remove -y qt6-virtualkeyboard-plugin 2>/dev/null || true

  echo "==> бэкап текущих конфигов → ~/.config/pre-higanbana-$TS"
  mkdir -p ~/.config/pre-higanbana-$TS
  (cd home && find .config -maxdepth 1 -type f) | while read -r f; do
    [ -f ~/"$f" ] && cp ~/"$f" ~/.config/pre-higanbana-$TS/ || true
  done

  echo "==> файлы пользователя"
  (cd home && tar cf - --exclude=./.gitkeep --exclude=./.old-home --exclude=./bashrc-higanbana.sh .) | (cd ~ && tar xf -)
  OLD=$(cat home/.old-home 2>/dev/null || echo "$HOME")
  if [ "$OLD" != "$HOME" ]; then
    grep -rlI --exclude-dir=wallpapers --exclude-dir=fonts --exclude-dir=icons "$OLD" ~/.config ~/.local/share/konsole 2>/dev/null \
      | xargs -r sed -i "s|$OLD|$HOME|g" || true
  fi
  sed -i '/# >>> higanbana >>>/,/# <<< higanbana <<</d' ~/.bashrc
  [ -f home/bashrc-higanbana.sh ] && cat home/bashrc-higanbana.sh >> ~/.bashrc
  fc-cache -f >/dev/null

  echo "==> системные файлы"
  (cd system && sudo tar cf - --exclude=./.gitkeep .) | (cd / && sudo tar xf - --no-same-owner)
  if [ -f /usr/share/plymouth/themes/higanbana/higanbana.plymouth ]; then
    sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth \
         /usr/share/plymouth/themes/higanbana/higanbana.plymouth 200
    sudo update-alternatives --set default.plymouth /usr/share/plymouth/themes/higanbana/higanbana.plymouth
  fi
  SDDM_HOME=$(getent passwd sddm | cut -d: -f6 || true); SDDM_HOME=${SDDM_HOME:-/var/lib/sddm}
  sudo mkdir -p "$SDDM_HOME/.config"
  grep -v '^widgetStyle=' ~/.config/kdeglobals | sudo tee "$SDDM_HOME/.config/kdeglobals" >/dev/null
  printf '[Mouse]\ncursorTheme=Bibata-Modern-Ice\ncursorSize=24\n' | sudo tee "$SDDM_HOME/.config/kcminputrc" >/dev/null
  [ -d ~/.local/share/icons/Bibata-Modern-Ice ] && sudo cp -r ~/.local/share/icons/Bibata-Modern-Ice /usr/share/icons/
  sudo chown -R sddm:sddm "$SDDM_HOME/.config" 2>/dev/null || true
  if [ -x /usr/sbin/sddm ]; then echo /usr/sbin/sddm; else echo /usr/bin/sddm; fi | sudo tee /etc/X11/default-display-manager >/dev/null
  sudo systemctl disable gdm3 2>/dev/null || true
  sudo systemctl enable --force sddm
  sudo update-grub
  sudo update-initramfs -u

  echo "==> красные папки Papirus"
  if ! command -v papirus-folders >/dev/null; then
    T=$(mktemp -d); git clone -q --depth 1 https://github.com/PapirusDevelopmentTeam/papirus-folders.git "$T/pf"
    sudo install -m 755 "$T/pf/papirus-folders" /usr/local/bin/papirus-folders; rm -rf "$T"
  fi
  sudo papirus-folders -C red --theme Papirus-Dark || true

  echo "==> скруглённые углы (сборка под эту версию KWin)"
  RC=~/.local/src/KDE-Rounded-Corners
  rm -rf "$RC"; mkdir -p ~/.local/src
  if git clone -q --depth 1 https://github.com/matinlotfali/KDE-Rounded-Corners "$RC" \
     && mkdir -p "$RC/build" && cd "$RC/build" && cmake .. >/dev/null && cmake --build . -j"$(nproc)" >/dev/null \
     && sudo make install >/dev/null; then
    sh ../tools/install-autorun-test.sh >/dev/null 2>&1 || true
  else
    echo "    !! углы не собрались — остальное работает"
  fi
  cd "$SRC"

  echo "==> Firefox / Obsidian"
  bash steps/06-boot-apps-widget.sh apps

  echo "==> yazi"
  YAZI_KEEP_CONFIG=1 bash steps/07-yazi.sh

  echo "==> обои на все мониторы"
  bash steps/08-monitors-flat-overview.sh monitors
fi

cat <<EOF

Готово ($MODE). Дальше:
  1. Перезагрузись — подхватятся GRUB, Plymouth, SDDM, Krohnkite, скругления.
  2. Telegram: открой ~/Pictures/Higanbana.tdesktop-theme → Keep changes.
  3. IntelliJ: Settings → Plugins → ⚙ → Install Plugin from Disk → $A/intellij/higanbana-intellij-theme.jar
  4. Обои, если не включились: правый клик по рабочему столу → Configure Desktop and Wallpaper →
     видео ~/Videos/wallpapers/emptiness-2560x1600.mp4 (или -4k под 16:9).
  5. Другой монитор — панели/виджет могут встать криво, поправь в режиме редактирования.
EOF
[ "$MODE" = snapshot ] && echo "Откат конфигов: cp ~/.config/pre-higanbana-$TS/* ~/.config/"
true
