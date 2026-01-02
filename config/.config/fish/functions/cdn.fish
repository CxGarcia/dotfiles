function cdn --description "Quick cd to nest project directories"
    set nest_dir $DEV/nest

    if test (count $argv) -eq 0
        cd $nest_dir
    else if test "$argv[1]" = "commonlib"
        cd $nest_dir/packages/commonlib
    else if test "$argv[1]" = "web"
        cd $nest_dir/websites/web
    else
        cd $nest_dir/apps/$argv[1]
    end
end

# Tab completions - list apps + special dirs
complete -c cdn -f -a "commonlib\t'packages/commonlib'" -a "web\t'websites/web'"
complete -c cdn -f -a "(for dir in $DEV/nest/apps/*/; set -l name (basename \$dir); echo \$name\t'nest app'; end)"
