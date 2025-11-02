gho() {
  local tab=""

  while getopts "piawc" opt; do
    case $opt in
      p) tab="/pulls" ;;       # PRs tab
      i) tab="/issues" ;;      # Issues tab
      a) tab="/actions" ;;     # Actions tab
      w) tab="/wiki" ;;        # Wiki tab
      c) tab="/commits" ;;     # Commits tab
      \?) echo "Invalid option: -$OPTARG" >&2; return 1 ;;
    esac
  done

  local remote_url=$(git remote get-url origin)

  if [[ "$remote_url" =~ ^git@ ]]; then
    remote_url=$(echo "$remote_url" | sed -E 's/git@github.com:(.+)\.git/https:\/\/github.com\/\1/')
  elif [[ "$remote_url" =~ ^https:// ]]; then
    remote_url=$(echo "$remote_url" | sed -E 's/\.git$//')
  fi

  local url="${remote_url}${tab}"

  open "$url"
}

unalias gpr 2>/dev/null
gpr() {
  local current_branch=$(git branch --show-current 2>/dev/null)
  
  if [[ -z "$current_branch" ]]; then
    echo "Error: Not in a git repository or no current branch found" >&2
    return 1
  fi

  # Try to use GitHub CLI to get the PR URL
  if command -v gh >/dev/null 2>&1; then
    local pr_url=$(gh pr view --json url --jq '.url' 2>/dev/null)
    if [[ -n "$pr_url" ]]; then
      open "$pr_url"
      return 0
    fi
  fi

  # Fallback: construct GitHub URL and open PRs page
  local remote_url=$(git remote get-url origin 2>/dev/null)
  
  if [[ -z "$remote_url" ]]; then
    echo "Error: No origin remote found" >&2
    return 1
  fi

  if [[ "$remote_url" =~ ^git@ ]]; then
    remote_url=$(echo "$remote_url" | sed -E 's/git@github.com:(.+)\.git/https:\/\/github.com\/\1/')
  elif [[ "$remote_url" =~ ^https:// ]]; then
    remote_url=$(echo "$remote_url" | sed -E 's/\.git$//')
  fi

  # Open PRs page - GitHub will show relevant PRs for the branch
  local url="${remote_url}/pulls"
  
  echo "GitHub CLI not available or no PR found for branch '$current_branch'"
  echo "Opening PRs page: $url"
  open "$url"
}
