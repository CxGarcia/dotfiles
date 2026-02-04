function seekndestroy --description "Recursively delete directories by name"
    if test (count $argv) -eq 0
        echo "Please provide a file name or directory to delete"
        return 1
    end

    find . -name "$argv[1]" -type d -prune -exec rm -rf '{}' +

    echo "Obliberated all '$argv[1]' directories"
end
