function scratchpad --description "Create a temp file and open in editor"
    set -l ext $argv[1]
    if test -z "$ext"
        set ext txt
    end
    set -l tmpfile (mktemp /tmp/scratch-XXXXXX.$ext)
    $EDITOR $tmpfile
end
