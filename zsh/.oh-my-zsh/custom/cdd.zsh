cdd() {
  if [ "$1" != "" ]
    then
      cd "$DEV/$1"
    else
  cd "$DEV"
  fi
}