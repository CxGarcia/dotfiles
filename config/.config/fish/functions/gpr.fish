function gpr --description "Open current branch's PR in browser"
    set -l current_branch (git branch --show-current 2>/dev/null)

    if test -z "$current_branch"
        echo "Error: Not in a git repository or no current branch found" >&2
        return 1
    end

    # Try to use GitHub CLI to get the PR URL
    if command -q gh
        set -l pr_url (gh pr view --json url --jq '.url' 2>/dev/null)
        if test -n "$pr_url"
            open "$pr_url"
            return 0
        end
    end

    # Fallback: construct GitHub URL and open PRs page
    set -l remote_url (git remote get-url origin 2>/dev/null)

    if test -z "$remote_url"
        echo "Error: No origin remote found" >&2
        return 1
    end

    if string match -q 'git@*' $remote_url
        set remote_url (string replace -r 'git@github.com:(.+)\.git' 'https://github.com/$1' $remote_url)
    else if string match -q 'https://*' $remote_url
        set remote_url (string replace -r '\.git$' '' $remote_url)
    end

    set -l url "$remote_url/pulls"

    echo "GitHub CLI not available or no PR found for branch '$current_branch'"
    echo "Opening PRs page: $url"
    open "$url"
end
