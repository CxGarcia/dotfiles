cdd() {
  local dev_dir="$HOME/dev"

  if [[ $# -eq 0 ]]; then
    cd "$dev_dir"
  else
    cd "$dev_dir/$1"
  fi
}

# Tab completion for the dev function
_cdd() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local dev_dir="$HOME/dev"

  # Get all subdirectories in ~/dev
  _files -W "$dev_dir" -/
}


cdn() {
nest_dir="$DEV/nest"

  if [ -z "$1" ]
    then
      cd $nest_dir
    elif [ "$1" = "commonlib" ]
      then
        cd $nest_dir/packages/commonlib
    elif [ "$1" = "web" ]
      then
        cd $nest_dir/websites/web
    else
      cd "$nest_dir/apps/$1"
  fi
}

seekndestroy() {
  if [ -z "$1" ]
    then
      echo "Please provide a file name or directory to delete"
      return
  fi

  find . -name "$1" -type d -prune -exec rm -rf '{}' +

  echo "Obliberated all '$1' directories"
}
