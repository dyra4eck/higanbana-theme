#!/usr/bin/env bash
# Higanbana — тёмный минимализм с красными акцентами для KDE Plasma 6.
# Ставит: цветовую схему, шрифты, иконки, размытие/эффекты KWin, профиль Konsole.
# Перед изменениями делает бэкап конфигов в ~/.config/higanbana-backup-<дата>.
set -euo pipefail

WOBBLY=${WOBBLY:-0}          # WOBBLY=1 ./higanbana-plasma.sh — включить «желейные» окна

# ---------- палитра ----------
BG=11,11,13          # #0b0b0d  фон окон
BG_ALT=20,20,23      # #141417
VIEW=15,15,18        # #0f0f12  поля ввода, списки
VIEW_ALT=22,22,26
BTN=26,26,30         # #1a1a1e
FG=230,225,223       # #e6e1df  основной текст
FG_DIM=138,132,134   # #8a8486
ACCENT=196,22,28     # #c4161c  цвет лилии
ACCENT_HI=224,53,59  # #e0353b  hover
SEL=140,16,22        # #8c1016  выделение
LINK=232,90,94
NEG=230,60,60
NEU=214,150,60
POS=110,170,120

need() { command -v "$1" >/dev/null || { echo "нет $1"; exit 1; }; }
need kwriteconfig6

echo "==> пакеты (шрифты, иконки)"
sudo apt install -y fonts-inter fonts-jetbrains-mono papirus-icon-theme kde-spectacle konsole-kpart

echo "==> бэкап"
BK=~/.config/higanbana-backup-$(date +%Y%m%d-%H%M%S)
mkdir -p "$BK"
for f in kdeglobals kwinrc konsolerc plasmarc; do [ -f ~/.config/$f ] && cp ~/.config/$f "$BK/"; done
echo "    $BK"

echo "==> цветовая схема"
mkdir -p ~/.local/share/color-schemes
grp() { # $1 name $2 bg $3 bgalt $4 fg
cat <<EOF
[Colors:$1]
BackgroundAlternate=$3
BackgroundNormal=$2
DecorationFocus=$ACCENT
DecorationHover=$ACCENT_HI
ForegroundActive=$ACCENT_HI
ForegroundInactive=$FG_DIM
ForegroundLink=$LINK
ForegroundNegative=$NEG
ForegroundNeutral=$NEU
ForegroundNormal=$4
ForegroundPositive=$POS
ForegroundVisited=$FG_DIM

EOF
}
{
  grp Window "$BG" "$BG_ALT" "$FG"
  grp View "$VIEW" "$VIEW_ALT" "$FG"
  grp Button "$BTN" "$BG_ALT" "$FG"
  grp Selection "$SEL" "$ACCENT" "255,255,255"
  grp Tooltip "$BG_ALT" "$BG" "$FG"
  grp Complementary "$BG" "$BG_ALT" "$FG"
  grp Header "$BG" "$BG_ALT" "$FG"
  echo "[Colors:Header][Inactive]"
  grp Header "$BG" "$BG_ALT" "$FG_DIM" | tail -n +2
  cat <<EOF
[General]
ColorScheme=Higanbana
Name=Higanbana
shadeSortColumn=true

[KDE]
contrast=4

[WM]
activeBackground=$BG
activeBlend=$FG
activeForeground=$FG
inactiveBackground=$BG
inactiveBlend=$FG_DIM
inactiveForeground=$FG_DIM
EOF
} > ~/.local/share/color-schemes/Higanbana.colors

plasma-apply-desktoptheme breeze-dark || true
plasma-apply-colorscheme Higanbana || true
kwriteconfig6 --file kdeglobals --group General --key AccentColor "$ACCENT"
kwriteconfig6 --file kdeglobals --group General --key LastUsedCustomAccentColor "$ACCENT"

echo "==> шрифты и иконки"
kwriteconfig6 --file kdeglobals --group General --key font "Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file kdeglobals --group General --key menuFont "Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file kdeglobals --group General --key toolBarFont "Inter,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file kdeglobals --group General --key smallestReadableFont "Inter,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file kdeglobals --group General --key fixed "JetBrains Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file kdeglobals --group WM --key activeFont "Inter,10,-1,5,500,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file kdeglobals --group Icons --key Theme Papirus-Dark

echo "==> KWin: размытие, рамки, анимации"
kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled true
kwriteconfig6 --file kwinrc --group Plugins --key contrastEnabled true
kwriteconfig6 --file kwinrc --group Plugins --key magiclampEnabled true
kwriteconfig6 --file kwinrc --group Plugins --key squashEnabled false
kwriteconfig6 --file kwinrc --group Plugins --key wobblywindowsEnabled "$([ "$WOBBLY" = 1 ] && echo true || echo false)"
kwriteconfig6 --file kwinrc --group Effect-blur --key BlurStrength 12
kwriteconfig6 --file kwinrc --group Effect-blur --key NoiseStrength 3
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key BorderSize None
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key BorderSizeAuto false
dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure || true

echo "==> Konsole: полупрозрачный профиль"
mkdir -p ~/.local/share/konsole
cat > ~/.local/share/konsole/Higanbana.colorscheme <<EOF
[General]
Description=Higanbana
Opacity=0.82
Blur=true

[Background]
Color=11,11,13
[BackgroundIntense]
Color=20,20,23
[Foreground]
Color=$FG
[ForegroundIntense]
Color=255,255,255
[Color0]
Color=30,30,34
[Color0Intense]
Color=90,86,88
[Color1]
Color=$ACCENT
[Color1Intense]
Color=$ACCENT_HI
[Color2]
Color=$POS
[Color2Intense]
Color=150,200,160
[Color3]
Color=$NEU
[Color3Intense]
Color=235,185,100
[Color4]
Color=110,130,170
[Color4Intense]
Color=150,170,210
[Color5]
Color=170,60,110
[Color5Intense]
Color=210,100,150
[Color6]
Color=100,160,165
[Color6Intense]
Color=140,200,205
[Color7]
Color=$FG_DIM
[Color7Intense]
Color=$FG
EOF
cat > ~/.local/share/konsole/Higanbana.profile <<EOF
[Appearance]
ColorScheme=Higanbana
Font=JetBrains Mono,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1

[Cursor Options]
CursorShape=1
CustomCursorColor=$ACCENT
UseCustomCursorColor=true

[General]
Name=Higanbana
Parent=FALLBACK/
TerminalMargin=12
EOF
kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile Higanbana.profile

echo
echo "Готово. Выйди из сессии и зайди снова, чтобы шрифты и иконки применились везде."
echo "Откат: cp $BK/* ~/.config/ && перелогин."
