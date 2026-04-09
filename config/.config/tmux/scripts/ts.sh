#!/usr/bin/env bash
# ts.sh — tmux session/window switcher with fzf

CURRENT_SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null)
CURRENT_SESSION_ID=$(tmux display-message -p '#{session_id}' 2>/dev/null)
STATE_DIR="${TMPDIR:-/tmp}/ts-picker"
ENGINE_FILE="$STATE_DIR/engine"
CACHE_FILE="$STATE_DIR/dots.tsv"
DEFAULT_ENGINE="claude"
CACHE_TTL_S=1
PANES_FMT=$'#{session_activity}\t#{session_id}\t#{session_name}\t#{window_name}\t#{pane_current_command}\t#{pane_dead}\t#{pane_title}\t#{pane_current_path}\t#{?@fleet_captain,1,0}\t#{?@fleet_managed,1,0}\t#{?@fleet_engine,#{@fleet_engine},-}\t#{?@claude_task,#{@claude_task},-}'

mkdir -p "$STATE_DIR"

read_picker_engine() {
    if [[ -f "$ENGINE_FILE" ]]; then
        local engine
        engine=$(tr -d '[:space:]' < "$ENGINE_FILE" 2>/dev/null)
        [[ "$engine" == "claude" || "$engine" == "codex" ]] && printf '%s\n' "$engine" && return
    fi
    printf '%s\n' "$DEFAULT_ENGINE"
}

write_picker_engine() {
    printf '%s\n' "$1" > "$ENGINE_FILE"
}

toggle_picker_engine() {
    local current
    current=$(read_picker_engine)
    if [[ "$current" == "claude" ]]; then
        write_picker_engine "codex"
    else
        write_picker_engine "claude"
    fi
}

engine_boot_command() {
    if [[ "$1" == "codex" ]]; then
        printf '%s\n' "codex --full-auto"
    else
        printf '%s\n' "claude --dangerously-skip-permissions"
    fi
}

trimmed_pane_tail() {
    local target="$1" lines="${2:-8}"
    tmux capture-pane -t "$target:=claude" -p -S -20 2>/dev/null | awk -v keep="$lines" '
        NF { buf[++count] = $0 }
        END {
            start = count > keep ? count - keep + 1 : 1
            for (i = start; i <= count; i++) print buf[i]
        }
    '
}

is_codex_idle_tail() {
    local content="$1"
    local trimmed tail
    trimmed=$(printf '%s\n' "$content" | awk 'NF { print }')
    tail=$(printf '%s\n' "$trimmed" | tail -3)

    if [[ "$tail" == *"esc to interrupt"* ]] || [[ "$tail" == *"Working ("* ]] || [[ "$tail" == *"Booting MCP server"* ]]; then
        return 1
    fi

    if [[ "$tail" == *"% left"* ]] && \
       ([[ "$tail" == *"› "* ]] || [[ "$tail" == *$'\n› '* ]] || [[ "$tail" == *$'\n> '* ]] || [[ "$tail" == '> '* ]]); then
        return 0
    fi

    [[ "$tail" == ">" || "$tail" == $'\n>' || "$tail" == *$'\n> '* || "$tail" == *$'\n› '* ]]
}

is_codex_picker_tail() {
    local tail="$1"

    if printf '%s\n' "$tail" | grep -Eqi '\[y/n\]|\[Y/n\]|\[yes/no\]|enter to select|enter to confirm|press enter to confirm|space to select|to navigate'; then
        return 0
    fi

    printf '%s\n' "$tail" | grep -Eq '^[[:space:]]+/[[:alnum:]][[:alnum:]-]*[[:space:]]{2,}'
}

resolve_work_dir() {
    if [[ -d "$1" ]]; then
        printf '%s\n' "$1"
    else
        zoxide query "$1" 2>/dev/null || printf '%s\n' "$HOME"
    fi
}

next_session_name() {
    local work_dir="$1"
    local base_name="${work_dir##*/}"
    local session_name n

    base_name="${base_name//./_}"
    session_name="$base_name"
    n=2
    while tmux has-session -t="$session_name" 2>/dev/null; do
        session_name="${base_name}-${n}"
        n=$((n + 1))
    done
    printf '%s\n' "$session_name"
}

create_workspace_session() {
    local work_dir="$1"
    local engine="$2"
    local attach_mode="${3:-attach}"
    local session_name command

    session_name=$(next_session_name "$work_dir")
    command=$(engine_boot_command "$engine")

    tmux new-session -d -s "$session_name" -n "claude" -c "$work_dir"
    tmux set-option -t "$session_name" @claude_task "${work_dir##*/}"
    tmux send-keys -t "$session_name:=claude" "$command" C-m
    zoxide add "$work_dir" 2>/dev/null
    if [[ "$attach_mode" != "detached" ]]; then
        go_to_session "$session_name:=claude" "$session_name"
    fi
}

# Clean up stale _picker_ sessions
tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^_picker_' | while read -r s; do
    [[ "$s" != "$CURRENT_SESSION" ]] && tmux kill-session -t "$s" 2>/dev/null
done

go_to_session() {
    if [[ -n "$TMUX" ]]; then
        tmux switch-client -t "$1" 2>/dev/null || tmux switch-client -t "$2"
    else
        tmux attach-session -t "$1" 2>/dev/null || tmux attach-session -t "$2"
    fi
    [[ "$CURRENT_SESSION" == _picker_* ]] && tmux kill-session -t "$CURRENT_SESSION" 2>/dev/null
}

COLORS="bg+:#2d3843,fg:#908caa,fg+:#e0def4,hl:#ebbcba,hl+:#ebbcba"
COLORS+=",border:#3a4450,header:#f6c177,pointer:#ebbcba,marker:#f6c177,prompt:#ebbcba"

render_dot() {
    local code="$1" color="31"
    case "$code" in
        picker) color="33" ;;
        idle) color="90" ;;
        working) color="38;5;39" ;;
    esac
    printf '\033[%sm%s\033[0m' "$color" "●"
}

is_codex_spinner_title() {
    local title="$1"
    [[ "$title" == ?\ * ]] && [[ "$title" != ">\ "* ]] && [[ "$title" != "› "* ]]
}

codex_title_state() {
    local title="$1"

    if is_codex_spinner_title "$title"; then
        printf '%s\n' "working"
        return 0
    fi

    return 1
}

cached_dot_code() {
    local key="$1" now
    [[ -f "$CACHE_FILE" ]] || return 1
    now=$(date +%s)
    awk -F '\t' -v key="$key" -v now="$now" -v ttl="$CACHE_TTL_S" '
        $1 == key && (now - $2) <= ttl { print $3; exit }
    ' "$CACHE_FILE"
}

cheap_dot_code() {
    local target="$1" engine="$2" cmd="$3" dead="$4" title="$5"
    if [[ "$dead" == "1" ]]; then
        printf '%s\n' "error"
    elif [[ -z "$engine" || "$engine" == "-" ]]; then
        printf '%s\n' "error"
    elif [[ "$engine" == "claude" && "$cmd" != "claude" ]]; then
        printf '%s\n' "error"
    elif [[ "$engine" == "codex" && "$cmd" != codex* ]]; then
        printf '%s\n' "error"
    elif [[ "$engine" == "claude" ]]; then
        if [[ "$title" == ✳* ]]; then
            printf '%s\n' "idle"
        else
            printf '%s\n' "working"
        fi
    else
        local tail title_code=""
        tail=$(trimmed_pane_tail "$target" 8)
        if is_codex_picker_tail "$tail"; then
            printf '%s\n' "picker"
        elif title_code=$(codex_title_state "$title" 2>/dev/null); then
            printf '%s\n' "$title_code"
        elif is_codex_idle_tail "$tail"; then
            printf '%s\n' "idle"
        else
            printf '%s\n' "working"
        fi
    fi
}

precise_dot_code() {
    local target="$1" engine="$2" cmd="$3" dead="$4" title="$5"
    if [[ "$dead" == "1" ]]; then
        printf '%s\n' "error"
        return
    fi
    if [[ -z "$engine" || "$engine" == "-" ]]; then
        if [[ "$cmd" == "claude" ]]; then
            engine="claude"
        elif [[ "$cmd" == codex* ]]; then
            engine="codex"
        fi
    fi
    if [[ -z "$engine" || "$engine" == "-" ]]; then
        printf '%s\n' "error"
        return
    fi
    if [[ "$engine" == "claude" && "$cmd" != "claude" ]]; then
        printf '%s\n' "error"
        return
    fi
    if [[ "$engine" == "codex" && "$cmd" != codex* ]]; then
        printf '%s\n' "error"
        return
    fi

    local tail
    tail=$(trimmed_pane_tail "$target" 5)

    local title_code=""
    if [[ "$engine" == "codex" ]]; then
        title_code=$(codex_title_state "$title" || true)
    fi

    if is_codex_picker_tail "$tail"; then
        printf '%s\n' "picker"
    elif [[ -n "$title_code" ]]; then
        printf '%s\n' "$title_code"
    elif [[ "$engine" == "claude" ]]; then
        if [[ "$title" == ✳* ]]; then
            printf '%s\n' "idle"
        else
            printf '%s\n' "working"
        fi
    elif is_codex_idle_tail "$tail"; then
        printf '%s\n' "idle"
    else
        printf '%s\n' "working"
    fi
}

refresh_dot_cache() {
    local now tmp code
    now=$(date +%s)
    tmp="${CACHE_FILE}.tmp.$$"
    : > "$tmp"
    while IFS=$'\t' read -r activity id name window_name cmd dead title path captain managed engine task; do
        [[ -z "$id" || "$window_name" != "claude" || "$name" == _picker_* ]] && continue
        code=$(precise_dot_code "$id" "$engine" "$cmd" "$dead" "$title")
        printf '%s\t%s\t%s\n' "$id" "$now" "$code" >> "$tmp"
    done < <(tmux list-panes -a -F "$PANES_FMT" 2>/dev/null)
    mv "$tmp" "$CACHE_FILE"
}

list_sessions() {
    local captains="" sessions="" line
    while IFS=$'\t' read -r activity id name window_name cmd dead title path captain managed engine task; do
        [[ -z "$id" || "$name" == "$CURRENT_SESSION" || "$name" == _picker_* || "$window_name" != "claude" ]] && continue

        local repo="${path##*/}"
        local label="${task:-$name}"

        if [[ "$captain" == "1" ]]; then
            if [[ "$task" == "-" ]]; then
                task="Fleet Captain"
            fi
            printf -v line '%s\t%s\t⚡ %s\t%s\n' "$id" "$name" "${task:-Fleet Captain}" "fleet"
            captains+="$line"
            continue
        fi

        if [[ -z "$engine" || "$engine" == "-" ]]; then
            if [[ "$cmd" == "claude" ]]; then
                engine="claude"
            elif [[ "$cmd" == codex* ]]; then
                engine="codex"
            fi
        fi

        local colorized=""
        if [[ "$managed" == "1" || "$cmd" == "claude" || "$cmd" == codex* ]]; then
            local code
            code=$(cached_dot_code "$id")
            if [[ -z "$code" ]]; then
                code=$(cheap_dot_code "$id" "$engine" "$cmd" "$dead" "$title")
            fi
            colorized=$(render_dot "$code")
            printf -v line '%s\t%s\t%s %s\t%s\n' "$id" "$name" "$colorized" "$label" "$repo"
        else
            printf -v line '%s\t%s\t%s\t%s\n' "$id" "$name" "$label" "$repo"
        fi
        sessions+="$line"
    done < <(tmux list-panes -a -F "$PANES_FMT" 2>/dev/null | sort -rnk1,1)
    printf '%s' "$captains$sessions"
}

case "${1:-}" in
    --list)     list_sessions; exit 0 ;;
    --refresh-dots)
        refresh_dot_cache
        exit 0
        ;;
    --refresh-and-list)
        refresh_dot_cache
        list_sessions
        exit 0
        ;;
    --new)
        [[ -z "${2:-}" ]] && exit 1
        create_workspace_session "$(resolve_work_dir "$2")" "${3:-$(read_picker_engine)}" "${4:-attach}"
        exit 0
        ;;
    --toggle-engine)
        toggle_picker_engine
        exit 0
        ;;
    --list-dirs)
        { zoxide query -l 2>/dev/null; find "$HOME/dev" -maxdepth 1 -mindepth 1 -type d 2>/dev/null; } | awk -v home="$HOME" '!seen[$0]++ { display=$0; sub("^"home, "~", display); printf "_dir_\t%s\t%s\n", $0, display }'
        exit 0 ;;
    --kill)
        [[ -z "${2:-}" || "$2" == "${3:-}" ]] && exit 0
        tmux kill-session -t "$2" 2>/dev/null; exit 0 ;;
esac

SELF="bash $0"

if [[ "${1:-}" == "--windows" ]]; then
    selected=$(
        tmux list-windows -a -F '#{session_name}:#{window_index} #{window_name}' |
        fzf --prompt="  Windows > " \
            --preview='tmux capture-pane -ep -t "$(echo {} | cut -d" " -f1)" 2>/dev/null' \
            --preview-window=right:55%:border-left \
            --color="$COLORS" --no-border --no-sort --no-separator --header=" " --layout=reverse --padding=0,3
    ) || exit 0
    target_win="${selected%% *}"
    go_to_session "$target_win" "$target_win"
    exit 0
fi

PREVIEW_SESSION='tmux capture-pane -ep -t "$(echo {} | cut -f1):=claude" 2>/dev/null'
PREVIEW_DIR='ls -1 --color=always {2} 2>/dev/null || ls -1G {2} 2>/dev/null'

selected=$(
    list_sessions |
    fzf --prompt="> " \
        --print-query \
        --pointer="" \
        --delimiter='\t' \
        --with-nth=3 \
        --bind="start:execute-silent($SELF --refresh-dots >/dev/null 2>&1 &)" \
        --bind="ctrl-x:execute-silent($SELF --kill {1} $CURRENT_SESSION_ID)+reload($SELF --list)" \
        --bind="ctrl-g:execute-silent($SELF --toggle-engine)+reload($SELF --list)" \
        --bind="ctrl-f:reload($SELF --list-dirs)+change-preview($PREVIEW_DIR)" \
        --bind="ctrl-s:reload($SELF --refresh-and-list)+change-preview($PREVIEW_SESSION)" \
        --preview="$PREVIEW_SESSION" \
        --preview-window=right:55%:border-left \
        --ansi --color="$COLORS" --no-border --no-sort --no-separator --header=" " --info=inline-right --padding=0,3
) || exit 0

{
    IFS= read -r query
    IFS= read -r choice
} <<< "$selected"

if [[ -n "$choice" ]]; then
    IFS=$'\t' read -r target name _ <<< "$choice"
else
    target=""
    name="$query"
fi
[[ -z "$target" && -z "$name" ]] && exit 0

# Directory picked from zoxide list -- create new workspace
if [[ "$target" == "_dir_" ]]; then
    "$0" --new "$name" "$(read_picker_engine)"
    exit 0
fi

# Existing session -- switch using stable session ID
if [[ -n "$target" ]]; then
    go_to_session "$target:=claude" "$target"
    exit 0
fi

# No session matched -- resolve query to a directory and create a new workspace
"$0" --new "$name" "$(read_picker_engine)"
