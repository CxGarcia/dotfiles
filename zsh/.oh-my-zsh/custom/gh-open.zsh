gh-open() {
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
