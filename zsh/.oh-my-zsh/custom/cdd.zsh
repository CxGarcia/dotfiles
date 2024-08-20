cdd() {
  if [ -z "$1" ]
    then
      cd "$DEV"
    else
      cd "$DEV/$1"
  fi
}

cdn() {
nest_dir="$DEV/nest"

  if [ -z "$1" ]
    then
      cd $nest_dir
    elif [ "$1" = "commonlib" ]
      then
        cd $nest_dir/packages/commonlib
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