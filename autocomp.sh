_script()
{
  _script_commands=$(./perle-vyos-image.sh lists)

  local cur
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "${_script_commands}" -- ${cur}) )

  return 0
}
complete -o nospace -F _script ./perle-vyos-image.sh
complete -o nospace -F _script ./ti-bsp-image.sh
complete -o nospace -F _script ./flash-sdcard.sh