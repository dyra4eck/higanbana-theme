#!/usr/bin/env bash
# Higanbana: yazi — терминальный файловый менеджер в теме Higanbana.
#   - бинарники yazi/ya из последнего релиза → ~/.local/bin
#   - зависимости для предпросмотра (картинки, видео, PDF, архивы) и поиска
#   - тема, конфиг, клавиши, плагины (git-статус, скруглённая рамка, smart-enter, toggle-pane)
#   - функция y: после выхода терминал остаётся в папке, где закрыл yazi
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
A=$(readlink -f "$PWD/../assets/yazi")

echo "==> зависимости"
sudo apt install -y file ffmpeg 7zip jq poppler-utils fd-find ripgrep fzf zoxide imagemagick unzip curl
mkdir -p ~/.local/bin
# в Ubuntu fd называется fdfind
command -v fd >/dev/null || ln -sf "$(command -v fdfind)" ~/.local/bin/fd

echo "==> yazi (последний релиз)"
T=$(mktemp -d)
curl -fL --retry 3 -o "$T/y.zip" https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip
unzip -q "$T/y.zip" -d "$T"
install -m 755 "$T"/yazi-x86_64-unknown-linux-gnu/{yazi,ya} ~/.local/bin/
mkdir -p ~/.local/share/bash-completion/completions
cp "$T"/yazi-x86_64-unknown-linux-gnu/completions/yazi.bash ~/.local/share/bash-completion/completions/yazi 2>/dev/null || true
cp "$T"/yazi-x86_64-unknown-linux-gnu/completions/ya.bash   ~/.local/share/bash-completion/completions/ya   2>/dev/null || true
rm -rf "$T"
export PATH="$HOME/.local/bin:$PATH"
yazi --version | head -2

echo "==> конфиг и тема"
C=~/.config/yazi
mkdir -p "$C"
if [ "${YAZI_KEEP_CONFIG:-0}" = 1 ] && [ -f "$C/theme.toml" ]; then
  echo "    оставляю конфиг из снимка"
else
  for f in theme.toml yazi.toml keymap.toml init.lua; do
    if [ -f "$C/$f" ] && ! cmp -s "$C/$f" "$A/$f"; then cp "$C/$f" "$C/$f.bak-$(date +%s)"; fi
    cp "$A/$f" "$C/$f"
  done
fi

echo "==> плагины"
for p in git full-border smart-enter toggle-pane; do
  ya pkg list 2>/dev/null | grep -q "plugins:$p" || ya pkg add "yazi-rs/plugins:$p"
done

echo "==> функция y в ~/.bashrc"
sed -i '/# >>> higanbana-yazi >>>/,/# <<< higanbana-yazi <<</d' ~/.bashrc
cat >> ~/.bashrc <<'EOF'
# >>> higanbana-yazi >>>
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
command -v zoxide >/dev/null && eval "$(zoxide init bash)"
y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}
# <<< higanbana-yazi <<<
EOF

echo
echo "Готово. Открой новый терминал и набери: y"
echo "  F1 или ~     — все горячие клавиши        T  — развернуть предпросмотр"
echo "  hjkl/стрелки — навигация                  z  — fzf,  Z — zoxide (частые папки)"
echo "  Space        — выделить   y/x/p — копировать/вырезать/вставить   d — в корзину"
echo "  /            — поиск      s / S — поиск по имени (fd) / по содержимому (rg)"
echo "  Ctrl+o       — показать файл в Dolphin (для drag-n-drop)"
