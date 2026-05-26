# adbtool bash completion
# Source this file or place it in $PREFIX/share/bash-completion/completions/adbtool

_adbtool_completions() {
  local cur prev words
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  local commands="start port fix-port tunnel shizuku help"

  case "$prev" in
    adbtool)
      COMPREPLY=($(compgen -W "$commands" -- "$cur"))
      ;;
    port)
      COMPREPLY=($(compgen -W "--tcp --tls" -- "$cur"))
      ;;
    tunnel)
      COMPREPLY=($(compgen -W "up down status" -- "$cur"))
      ;;
    shizuku)
      COMPREPLY=($(compgen -W "start status" -- "$cur"))
      ;;
  esac
}

complete -F _adbtool_completions adbtool
