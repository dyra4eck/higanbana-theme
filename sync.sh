#!/usr/bin/env bash
# Снимает текущее состояние темы с этой машины в репозиторий (home/ и system/).
# Запускай после любых правок темы, затем: git add -A && git commit -m "..." && git push
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
R=$PWD
H=$R/home S=$R/system

find "$H" "$S" -mindepth 1 ! -name .gitkeep -delete 2>/dev/null || true
mkdir -p "$H" "$S"

cp_home() {
  for p in "$@"; do
    [ -e "$HOME/$p" ] || continue
    mkdir -p "$H/$(dirname "$p")"
    cp -a "$HOME/$p" "$H/$p"
  done
}
cp_sys() {
  for p in "$@"; do
    [ -e "$p" ] || continue
    mkdir -p "$S$(dirname "$p")"
    sudo cp -a "$p" "$S$p"
  done
}

echo "==> конфиги Plasma / KWin / терминала"
cp_home .config/kdeglobals .config/kwinrc .config/kglobalshortcutsrc .config/plasmarc \
        .config/plasma-org.kde.plasma.desktop-appletsrc .config/plasmashellrc \
        .config/kcminputrc .config/ksmserverrc .config/kscreenlockerrc .config/konsolerc \
        .config/breezerc .config/gtk-3.0/settings.ini .config/gtk-4.0/settings.ini \
        .config/Kvantum .config/starship.toml .config/fastfetch .config/btop .config/cava .tmux.conf \
        .config/autostart/test-install-kde-rounded-corners.desktop

echo "==> цвета, Konsole, курсор, шрифт, виджеты, KWin-скрипты, плагин обоев"
cp_home .local/share/color-schemes .local/share/konsole .local/share/icons/Bibata-Modern-Ice \
        .local/share/fonts/JetBrainsMonoNF .local/share/plasma/plasmoids/dev.higanbana.clock \
        .local/share/plasma/wallpapers .local/share/kwin/scripts \
        Pictures/higanbana-lock.png

echo "==> блок higanbana из .bashrc"
sed -n '/# >>> higanbana >>>/,/# <<< higanbana <<</p' ~/.bashrc > "$H/bashrc-higanbana.sh" || true

echo "==> системные файлы (sudo)"
cp_sys /usr/share/plymouth/themes/higanbana /boot/grub/themes/higanbana \
       /etc/default/grub.d/99-higanbana.cfg /etc/sddm.conf /etc/sddm.conf.d/10-higanbana.conf \
       /usr/share/sddm/themes/breeze/theme.conf.user /usr/share/sddm/themes/breeze/higanbana.png
sudo chown -R "$(id -u):$(id -g)" "$S"

echo "$HOME" > "$H/.old-home"
touch "$H/.gitkeep" "$S/.gitkeep"

echo
git -C "$R" status --short | head -40
echo
echo "Снимок обновлён. Дальше: git add -A && git commit -m 'sync' && git push"
