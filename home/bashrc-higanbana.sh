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
