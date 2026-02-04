function gho --description "Open GitHub repo in browser"
    argparse 'p' 'i' 'a' 'w' 'c' -- $argv
    or return 1

    set -l tab ""

    if set -q _flag_p
        set tab "/pulls"
    else if set -q _flag_i
        set tab "/issues"
    else if set -q _flag_a
        set tab "/actions"
    else if set -q _flag_w
        set tab "/wiki"
    else if set -q _flag_c
        set tab "/commits"
    end

    set -l remote_url (git remote get-url origin)

    if string match -q 'git@*' $remote_url
        set remote_url (string replace -r 'git@github.com:(.+)\.git' 'https://github.com/$1' $remote_url)
    else if string match -q 'https://*' $remote_url
        set remote_url (string replace -r '\.git$' '' $remote_url)
    end

    set -l url "$remote_url$tab"
    open "$url"
end
