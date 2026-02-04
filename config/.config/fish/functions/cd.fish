function cd --wraps=cd --description "cd with support for 'cd -' to go to previous directory"
    set -l previous $PWD

    if test (count $argv) -eq 1 -a "$argv[1]" = "-"
        if set -q OLDPWD
            builtin cd $OLDPWD
            set -g OLDPWD $previous
        else
            echo "cd: no previous directory"
            return 1
        end
    else
        builtin cd $argv
        and set -g OLDPWD $previous
    end
end
