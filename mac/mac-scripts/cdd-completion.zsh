_flist () {
  COMPREPLY=()
  k=0
  i=$DEV

  for entry in "$i"/*
  do
  print entry
  COMPREPLY[k++]=${entry#$i/}
  done
  return null
}

complete -o nospace -F _flist cdd

