code() {
    # reads the current editor in ~/editor-config
    editor=$(cat ~/.editor-profile | jq -r '.editor')
    if [ -z "$editor" ]
        then
            echo "No editor found in ~/.editor-profile"
            return
    fi

    if [ -n "$1" ]; then
        dirpath=$(cd "$(dirname "$1")" && pwd)
        filepath="$dirpath/$(basename "$1")"
        open -a "/Applications/$editor.app" "$filepath"
    else
        open "/Applications/$editor.app"
    fi
}