function cdd --description "Quick cd to ~/dev or subdirectory"
    if test (count $argv) -eq 0
        cd $DEV
    else
        cd $DEV/$argv[1]
    end
end

# Tab completions - list directories in ~/dev
complete -c cdd -f -a "(command ls -1 $DEV 2>/dev/null)"
