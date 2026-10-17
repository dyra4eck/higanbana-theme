#!/usr/bin/env bash
# Higanbana, часть 4: терминал (starship + fastfetch + Nerd Font + eza/bat), курсор Bibata, экран блокировки.
set -euo pipefail

echo "==> пакеты"
sudo apt install -y starship fastfetch eza bat ffmpeg curl xz-utils

# ---------- Nerd Font (иконки в промпте) ----------
if ! fc-list | grep -qi "JetBrainsMono Nerd Font"; then
  echo "==> JetBrainsMono Nerd Font"
  mkdir -p ~/.local/share/fonts/JetBrainsMonoNF
  curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
    | tar -xJ -C ~/.local/share/fonts/JetBrainsMonoNF
  fc-cache -f >/dev/null
fi

# ---------- starship ----------
echo "==> промпт starship"
mkdir -p ~/.config
[ -f ~/.config/starship.toml ] && cp ~/.config/starship.toml ~/.config/starship.toml.bak-$(date +%s)
cat > ~/.config/starship.toml <<'EOF'
# Higanbana — starship prompt
add_newline = true
command_timeout = 800
palette = "higanbana"

format = """
[╭─](dim_red)$os$username$hostname$directory$git_branch$git_status$python$golang$docker_context$terraform$kubernetes$cmd_duration$fill$time
[╰─](dim_red)$character"""

[palettes.higanbana]
red = "#c4161c"
bright_red = "#e0353b"
dim_red = "#5a1418"
fg = "#e6e1df"
dim = "#8a8486"

[os]
disabled = false
style = "red"
format = "[$symbol]($style) "
[os.symbols]
Ubuntu = "󰕈 "

[username]
show_always = false
style_user = "dim"
format = "[$user]($style)"

[hostname]
ssh_only = true
style = "dim"
format = "[@$hostname]($style) "

[directory]
style = "bold fg"
read_only = " 󰌾"
truncation_length = 4
truncation_symbol = "…/"
format = "[󰉋 $path]($style)[$read_only](red) "

[git_branch]
symbol = "󰘬 "
style = "red"
format = "[$symbol$branch]($style) "

[git_status]
style = "bright_red"
format = "([$all_status$ahead_behind]($style) )"

[python]
symbol = "󰌠 "
style = "dim"
format = "[$symbol$version( \\($virtualenv\\))]($style) "

[golang]
symbol = "󰟓 "
style = "dim"
format = "[$symbol$version]($style) "

[docker_context]
symbol = "󰡨 "
style = "dim"
format = "[$symbol$context]($style) "

[terraform]
symbol = "󱁢 "
style = "dim"
format = "[$symbol$workspace]($style) "

[kubernetes]
disabled = false
symbol = "󱃾 "
style = "red"
format = "[$symbol$context( /$namespace)]($style) "

[cmd_duration]
min_time = 2000
style = "dim"
format = "[󰔛 $duration]($style) "

[fill]
symbol = " "

[time]
disabled = false
style = "dim_red"
time_format = "%H:%M"
format = "[$time]($style)"

[character]
success_symbol = "[❯](bold red)"
error_symbol = "[❯](bold bright_red)[✗](bright_red)"
vimcmd_symbol = "[❮](bold red)"
EOF

# ---------- fastfetch ----------
echo "==> fastfetch"
mkdir -p ~/.config/fastfetch
cat > ~/.config/fastfetch/config.jsonc <<'EOF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": { "source": "ubuntu_small", "color": { "1": "red", "2": "red" }, "padding": { "top": 1, "left": 2, "right": 3 } },
  "display": { "separator": "  ", "color": { "keys": "red", "title": "red" } },
  "modules": [
    { "type": "custom", "format": "\u001b[31m彼岸花\u001b[0m  \u001b[2mhiganbana\u001b[0m" },
    { "type": "custom", "format": "\u001b[2m────────────────────────────\u001b[0m" },
    { "type": "os",       "key": "󰣭 " },
    { "type": "kernel",   "key": "󰌽 " },
    { "type": "de",       "key": "󰍹 " },
    { "type": "wm",       "key": "󰖯 " },
    { "type": "terminal", "key": "󰆍 " },
    { "type": "shell",    "key": "󱆃 " },
    { "type": "cpu",      "key": "󰻠 " },
    { "type": "gpu",      "key": "󰢮 " },
    { "type": "memory",   "key": "󰍛 " },
    { "type": "disk",     "key": "󰋊 ", "folders": "/" },
    { "type": "uptime",   "key": "󰅐 " },
    "break",
    { "type": "colors", "symbol": "circle" }
  ]
}
EOF

# ---------- bashrc ----------
echo "==> ~/.bashrc"
sed -i '/# >>> higanbana >>>/,/# <<< higanbana <<</d' ~/.bashrc
cat >> ~/.bashrc <<'EOF'
# >>> higanbana >>>
if [[ $- == *i* ]]; then
  command -v starship >/dev/null && eval "$(starship init bash)"
  if command -v eza >/dev/null; then
    alias ls='eza --icons=auto --group-directories-first'
    alias ll='eza -lh --icons=auto --git --group-directories-first'
    alias la='eza -lah --icons=auto --git --group-directories-first'
    alias lt='eza --tree --level=2 --icons=auto'
  fi
  alias neofetch=fastfetch
  command -v batcat >/dev/null && alias cat='batcat --paging=never --style=plain --theme=ansi' && alias bat='batcat --theme=ansi'
  [[ -z $HIGANBANA_FETCHED && $TERM_PROGRAM != vscode && -z $INTELLIJ_ENVIRONMENT_READER ]] && { export HIGANBANA_FETCHED=1; fastfetch 2>/dev/null; }
fi
# <<< higanbana <<<
EOF

# ---------- Konsole ----------
echo "==> Konsole"
P=~/.local/share/konsole/Higanbana.profile
if [ -f "$P" ]; then
  sed -i 's/^Font=.*/Font=JetBrainsMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1/' "$P"
  grep -q '^\[Scrolling\]' "$P" || printf '\n[Scrolling]\nScrollBarPosition=2\n' >> "$P"   # скрыть скроллбар
fi
kwriteconfig6 --file konsolerc --group KonsoleWindow --key ShowMenuBarByDefault false
kwriteconfig6 --file konsolerc --group KonsoleWindow --key RememberWindowSize true

# ---------- курсор ----------
echo "==> курсор Bibata Modern Ice"
mkdir -p ~/.local/share/icons
if [ ! -f ~/.local/share/icons/Bibata-Modern-Ice/index.theme ]; then
  T=$(mktemp -d)
  curl -fL --retry 3 -o "$T/b.tar.xz" https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Ice.tar.xz
  tar -xJf "$T/b.tar.xz" -C "$T"
  SRC=$(dirname "$(find "$T" -name index.theme -path '*Bibata-Modern-Ice*' | head -1)")
  rm -rf ~/.local/share/icons/Bibata-Modern-Ice && cp -r "$SRC" ~/.local/share/icons/Bibata-Modern-Ice
  rm -rf "$T"
fi
ls ~/.local/share/icons/Bibata-Modern-Ice/cursors >/dev/null && echo "    установлен в ~/.local/share/icons/Bibata-Modern-Ice"
plasma-apply-cursortheme Bibata-Modern-Ice || true
kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme Bibata-Modern-Ice
kwriteconfig6 --file kcminputrc --group Mouse --key cursorSize 24

# ---------- экран блокировки ----------
echo "==> экран блокировки"
VID=$(ls ~/Videos/wallpapers/emptiness-2560x1600*.mp4 ~/Videos/wallpapers/emptiness*.mp4 ~/Videos/emptiness*.mp4 2>/dev/null | head -1 || true)
LOCK=~/Pictures/higanbana-lock.png
mkdir -p ~/Pictures
if [ -n "$VID" ]; then
  ffmpeg -loglevel error -y -ss 3 -i "$VID" -frames:v 1 "$LOCK"
  kwriteconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin org.kde.image
  kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "file://$LOCK"
  kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key PreviewImage "file://$LOCK"
  kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key FillMode 2
  echo "    $LOCK"
else
  echo "    видео не найдено в ~/Videos — пропускаю (задай картинку в System Settings → Screen Locking)"
fi

echo
echo "Готово. Открой новое окно Konsole. Курсор полностью применится после перелогина."
echo "Проверить экран блокировки: Meta+L"
