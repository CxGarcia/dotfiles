_flist () {
  COMPREPLY=()
  k=0
  i="$HOME/Documents/code"

  for entry in "$i"/*
  do
	print entry
	COMPREPLY[k++]=${entry#$i/}
  done
  return null
}

complete -o nospace -F _flist cdd

