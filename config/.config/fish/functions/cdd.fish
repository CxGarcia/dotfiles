function cdd --description "Quick cd to ~/dev or subdirectory"
    if test (count $argv) -eq 0
        cd $DEV
    else
        cd $DEV/$argv[1]
    end
end

# Tab completions - list directories in ~/dev with descriptions
complete -c cdd -f -a "(for dir in $DEV/*/; set -l name (basename \$dir); echo \$name\t'dev project'; end)"
