_cdnlist () {
  COMPREPLYCDN=("commonlib")
  idx=1
  dir=$DEV/nest/apps

  for entry in "$dir"/*
  do
    print entry
    COMPREPLYCDN[idx++]=${entry#$dir/}
  done
  return null
}

complete -o nospace -F _cdnlist cdn
