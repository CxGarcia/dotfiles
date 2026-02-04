function code --description "Open file/directory in configured editor"
    set -l editor (cat ~/.editor-profile | jq -r '.editor')

    if test -z "$editor"
        echo "No editor found in ~/.editor-profile"
        return 1
    end

    if test (count $argv) -gt 0
        set -l dirpath (cd (dirname $argv[1]) && pwd)
        set -l filepath "$dirpath/"(basename $argv[1])
        open -a "/Applications/$editor.app" "$filepath"
    else
        open "/Applications/$editor.app"
    end
end
