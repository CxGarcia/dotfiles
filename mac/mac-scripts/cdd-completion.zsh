_cddlist () {
  COMPREPLYCDD=()
  k=0
  i=$DEV

  for entry in "$i"/*
  do
  print entry
  COMPREPLYCDD[k++]=${entry#$i/}
  done
  return null
}

complete -o nospace -F _cddlist cdd

