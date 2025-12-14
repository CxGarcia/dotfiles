# =============================================================================
# Git Abbreviations (expand on space, so you see the full command)
# =============================================================================

if status is-interactive
    # Basic
    abbr -a g git
    abbr -a ga 'git add'
    abbr -a gaa 'git add --all'
    abbr -a gap 'git add --patch'

    # Branch
    abbr -a gb 'git branch'
    abbr -a gba 'git branch -a'
    abbr -a gbd 'git branch -d'
    abbr -a gbD 'git branch -D'

    # Commit
    abbr -a gc 'git commit'
    abbr -a gc! 'git commit --amend'
    abbr -a gcm 'git commit -m'
    abbr -a gcam 'git commit -a -m'
    abbr -a gca 'git commit -a'

    # Checkout / Switch
    abbr -a gco 'git checkout'
    abbr -a gcb 'git checkout -b'
    abbr -a gsw 'git switch'
    abbr -a gswc 'git switch -c'

    # Diff
    abbr -a gd 'git diff'
    abbr -a gds 'git diff --staged'
    abbr -a gdw 'git diff --word-diff'

    # Fetch / Pull / Push
    abbr -a gf 'git fetch'
    abbr -a gfa 'git fetch --all --prune'
    abbr -a gl 'git pull'
    abbr -a gp 'git push'
    abbr -a gpf 'git push --force-with-lease'
    abbr -a gpsup 'git push --set-upstream origin (git branch --show-current)'

    # Log
    abbr -a glg 'git log --oneline --decorate --graph'
    abbr -a glga 'git log --oneline --decorate --graph --all'
    abbr -a glo 'git log --oneline'

    # Merge / Rebase
    abbr -a gm 'git merge'
    abbr -a grb 'git rebase'
    abbr -a grbi 'git rebase -i'
    abbr -a grbc 'git rebase --continue'
    abbr -a grba 'git rebase --abort'

    # Remote
    abbr -a gr 'git remote'
    abbr -a grv 'git remote -v'

    # Reset
    abbr -a grh 'git reset'
    abbr -a grhh 'git reset --hard'
    abbr -a grhs 'git reset --soft'

    # Stash
    abbr -a gsta 'git stash push'
    abbr -a gstp 'git stash pop'
    abbr -a gstl 'git stash list'
    abbr -a gstd 'git stash drop'

    # Status
    abbr -a gst 'git status'
    abbr -a gss 'git status -s'

    # Cherry-pick
    abbr -a gcp 'git cherry-pick'
    abbr -a gcpa 'git cherry-pick --abort'
    abbr -a gcpc 'git cherry-pick --continue'

    # Worktree
    abbr -a gwt 'git worktree'
    abbr -a gwta 'git worktree add'
    abbr -a gwtl 'git worktree list'
    abbr -a gwtr 'git worktree remove'
end
