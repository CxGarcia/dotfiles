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
complete -c cdn -f -a "commonlib web"
complete -c cdn -f -a "(command ls -1 $DEV/nest/apps 2>/dev/null)"
