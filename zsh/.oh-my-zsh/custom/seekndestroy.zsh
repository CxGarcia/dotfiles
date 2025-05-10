seekndestroy() {
  if [ -z "$1" ]
    then
      echo "Please provide a file name or directory to delete"
      return
  fi

  find . -name "$1" -type d -prune -exec rm -rf '{}' +

  echo "Obliberated all '$1' directories"
}