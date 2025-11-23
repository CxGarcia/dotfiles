# Neovim Navigation Cheatsheet

**Leader key:** `Space`

---

## 🗂️ FILE & DIRECTORY NAVIGATION

### File Explorer (NvimTree)

| Keymap      | Action                            |
| ----------- | --------------------------------- |
| `<leader>e` | Toggle file explorer              |
| `a`         | Create new file/folder (in tree)  |
| `d`         | Delete file/folder                |
| `r`         | Rename file/folder                |
| `x`         | Cut file                          |
| `c`         | Copy file                         |
| `p`         | Paste file                        |
| `R`         | Refresh tree                      |
| `H`         | Toggle hidden files               |
| `Enter`     | Open file                         |
| `Tab`       | Open file but keep cursor in tree |
| `Ctrl-v`    | Open in vertical split            |
| `Ctrl-x`    | Open in horizontal split          |

### Telescope (Fuzzy Finder)

| Keymap                       | Action                                       |
| ---------------------------- | -------------------------------------------- |
| `<leader>p` or `<leader>ff`  | **Find files** (most used!)                  |
| `<leader>fb`                 | **Find buffers** (switch between open files) |
| `<leader>tf`                 | **Find terminals** (list all open terminals) |
| `<leader>fr`                 | Recent files                                 |
| `g/`                         | **Search across all files** (live grep) ⚡   |
| `<leader>fg`                 | Live grep (search text in all files)         |
| `<leader>fc`                 | Find word under cursor                       |
| `<leader>gc` or `<leader>gf` | Git changed files ⚡                         |
| `<leader>fh`                 | Help tags                                    |
| `<leader>fd`                 | Project diagnostics                          |
| `<leader>fs`                 | Document symbols                             |
| `<leader>fS`                 | Workspace symbols                            |

**Inside Telescope:**
| Keymap | Action |
|--------|--------|
| `Ctrl-j` | Move down |
| `Ctrl-k` | Move up |
| `Ctrl-q` | Send to quickfix list |
| `Enter` | Open file |
| `Esc` | Close |

---

## 📑 BUFFER NAVIGATION

### Three Mental Models for Buffers

**1. Linear List Model** (what Shift-h/l does)
Think of buffers as a carousel you cycle through:

```
[buf1] → [buf2] → [buf3] → [buf4] → (back to buf1)
```

**2. Jump List Model** (built-in, super useful!)
Jump to places you've recently been:

```
Current → Last → 2nd-to-last → ...
```

**3. Fuzzy Finder Model** (fastest for many buffers)
Search and jump directly to any buffer by name.

### Buffer Keymaps

| Keymap       | Action                                             |
| ------------ | -------------------------------------------------- |
| `Shift-h`    | Previous buffer (linear cycling)                   |
| `Shift-l`    | Next buffer (linear cycling)                       |
| `Ctrl-6`     | **Toggle between last 2 buffers** (use this most!) |
| `Ctrl-o`     | Jump to older location in jump list                |
| `Ctrl-i`     | Jump to newer location in jump list                |
| `<leader>fb` | Find buffer (Telescope - best for many buffers)    |
| `<leader>bd` | Delete/close current buffer                        |

### Recommended Workflow

**80% of the time:** Use `Ctrl-6` to toggle between your two main files
**When you need a specific file:** Use `<leader>fb` to fuzzy find it
**When browsing:** Use `Shift-h`/`Shift-l` to cycle through the bufferline

**Tip:** You can also click on buffers in the top bar!

---

## 💾 SESSION MANAGEMENT

| Keymap       | Action                                           |
| ------------ | ------------------------------------------------ |
| `<leader>qs` | **Restore session** for current directory        |
| `<leader>ql` | **Restore last session**                         |
| `<leader>qd` | Don't save current session (exit without saving) |

**Note:** Sessions are automatically saved when you exit nvim, and restored when you open nvim in the same directory!

---

## 🪟 WINDOW NAVIGATION

### Moving Between Windows

| Keymap   | Action             |
| -------- | ------------------ |
| `Ctrl-h` | Go to left window  |
| `Ctrl-j` | Go to lower window |
| `Ctrl-k` | Go to upper window |
| `Ctrl-l` | Go to right window |

### Resizing Windows

| Keymap       | Action          |
| ------------ | --------------- |
| `Ctrl-Up`    | Increase height |
| `Ctrl-Down`  | Decrease height |
| `Ctrl-Left`  | Decrease width  |
| `Ctrl-Right` | Increase width  |

### Window Commands (use `:` to enter)

| Command             | Action                           |
| ------------------- | -------------------------------- |
| `:split` or `:sp`   | Horizontal split                 |
| `:vsplit` or `:vsp` | Vertical split                   |
| `:only`             | Close all windows except current |
| `:q`                | Close current window             |

---

## 💻 TERMINAL MANAGEMENT

### Opening Terminals

| Keymap       | Action                     |
| ------------ | -------------------------- |
| `<leader>tt` | Toggle floating terminal   |
| `<leader>th` | Toggle horizontal terminal |
| `<leader>tv` | Toggle vertical terminal   |
| `<leader>tn` | Toggle Node REPL           |
| `<leader>tp` | Toggle Python REPL         |
| `<leader>cc` | Toggle Claude Code         |
| `Alt-,`      | Quick toggle Claude Code   |

### Managing Multiple Terminals

| Keymap       | Action                         |
| ------------ | ------------------------------ |
| `<leader>tf` | **Find terminals** (Telescope) |
| `<leader>t1` | Switch to terminal 1           |
| `<leader>t2` | Switch to terminal 2           |
| `<leader>t3` | Switch to terminal 3           |
| `<leader>t4` | Switch to terminal 4           |
| `<leader>ta` | Toggle all terminals           |

### Inside Terminal Mode

| Keymap         | Action                         |
| -------------- | ------------------------------ |
| `Esc` or `jk`  | Exit terminal mode (to normal) |
| `Ctrl-h/j/k/l` | Navigate to other windows      |
| `Ctrl-w`       | Close current terminal         |
| `Alt-h`        | Toggle horizontal terminal     |
| `Alt-v`        | Toggle vertical terminal       |

### Terminal Workflow

```
1. Open floating terminal:     <leader>tt
2. Run your commands:           (type normally)
3. Exit to normal mode:         Esc
4. Navigate to code:            Ctrl-h/j/k/l
5. Back to terminal:            <leader>tt (toggles)
6. Need another terminal?       <leader>t2 (opens terminal 2)
7. Switch between them:         <leader>t1 / <leader>t2
```

**Tips:**

- Terminals persist - they don't close when you toggle them, just hide
- Each terminal (1-4) maintains its own shell session
- Use floating for quick commands, horizontal/vertical for side-by-side work
- Terminal 1 is the default when you use `<leader>tt`

---

## 🎯 QUICK WORKFLOW TIPS

### Opening Files - The Three Main Ways:

1. **Know the filename?** → `<leader>p` (find files)
2. **File is already open?** → `<leader>fb` (find buffers) or `Shift-h`/`Shift-l`
3. **Browse directory structure?** → `<leader>e` (file tree)

### Typical Workflow:

```
1. Open file tree:           <leader>e
2. Navigate and open files:  Enter
3. Switch between buffers:   Shift-h / Shift-l
4. Quick find another file:  <leader>p
5. Search across project:    g/
```

---

## 🔀 GIT INTEGRATION

### Git Changed Files

| Keymap                       | Action                                 |
| ---------------------------- | -------------------------------------- |
| `<leader>gc` or `<leader>gf` | **Show all changed files** (Telescope) |

### Gutter Signs (Automatic!)

Your changes are **always visible** in the left gutter:
| Sign | Meaning |
|------|---------|
| **`│`** (green) | Added or changed lines |
| **`_`** (red) | Deleted lines |
| **`~`** (blue) | Changed and deleted |

### Navigate Git Changes (Hunks)

| Keymap      | Action                           |
| ----------- | -------------------------------- |
| **`]g`**    | **Go to next git change** ⚡     |
| **`[g`**    | **Go to previous git change** ⚡ |
| `]h` / `[h` | Alternative: next/prev hunk      |

### Git Actions

| Keymap       | Action                                    |
| ------------ | ----------------------------------------- |
| `<leader>gp` | Preview hunk (see what changed)           |
| `<leader>gb` | Git blame current line                    |
| `<leader>gr` | Reset/undo hunk                           |
| `<leader>gs` | Stage hunk (normal) or selection (visual) |

**Inside git_status (after `<leader>gc`):**

- `Enter` - Open the changed file
- `Ctrl-v` - Open in vertical split
- Tab through files to see all changes

### Git Workflow Example

```
1. See all changed files:        <leader>gc
2. Open a file:                  Enter
3. Jump to next change:          ]g
4. Preview what changed:         <leader>gp
5. Stage the change:             <leader>gs
6. Jump to next change:          ]g
```

---

## ✨ TEXT OBJECTS & SURROUND

### Surround (nvim-surround)

| Keymap  | Action                      | Example                |
| ------- | --------------------------- | ---------------------- |
| `cs"'`  | Change surround " to '      | `"hello"` → `'hello'`  |
| `ds"`   | Delete surrounding "        | `"hello"` → `hello`    |
| `ysiw"` | Surround word with "        | `hello` → `"hello"`    |
| `yss)`  | Surround entire line        | `hello` → `(hello)`    |
| `s`     | Surround selection (visual) | Select text then `s"`  |
| `S`     | Surround lines (visual)     | Select lines then `S"` |

### Built-in Text Objects (work everywhere)

| Keymap                  | Action                                            |
| ----------------------- | ------------------------------------------------- |
| `vi{` or `vi}`          | Select **inside** curly braces `{}`               |
| `va{` or `va}`          | Select **around** curly braces (includes `{}`)    |
| `vi(` or `vi)` or `vib` | Select **inside** parentheses `()`                |
| `va(` or `va)` or `vab` | Select **around** parentheses (includes `()`)     |
| `vi[` or `vi]`          | Select **inside** square brackets `[]`            |
| `va[` or `va]`          | Select **around** square brackets (includes `[]`) |
| `vi"`                   | Select inside double quotes                       |
| `va"`                   | Select around double quotes (includes `"`)        |
| `vi'`                   | Select inside single quotes                       |
| `va'`                   | Select around single quotes (includes `'`)        |
| `viw`                   | Select inner word                                 |
| `vaw`                   | Select around word (includes space)               |
| `vip`                   | Select inner paragraph                            |
| `vap`                   | Select around paragraph                           |
| `vit`                   | Select inner tag (HTML/XML)                       |
| `vat`                   | Select around tag (includes tags)                 |

**Tip:** Replace `v` with `d` to delete, `c` to change, or `y` to yank!

- `da{` - delete around `{}`
- `ci"` - change inside `"`
- `ya(` - yank around `()`

### Indent Text Objects

| Keymap | Action                                     |
| ------ | ------------------------------------------ |
| `vii`  | Select inner indent (just indented block)  |
| `vai`  | Select around indent (includes line above) |

### Treesitter Text Objects (smart, language-aware)

| Keymap | Action                              |
| ------ | ----------------------------------- |
| `vaf`  | Select around function              |
| `vif`  | Select inside function              |
| `vac`  | Select around class                 |
| `vic`  | Select inside class                 |
| `vab`  | Select around block                 |
| `vib`  | Select inside block                 |
| `vaa`  | Select around parameter/argument    |
| `via`  | Select inside parameter/argument    |
| `vai`  | Select around conditional (if/else) |
| `vii`  | Select inside conditional           |
| `val`  | Select around loop                  |
| `vil`  | Select inside loop                  |
| `vad`  | Select around definition            |
| `vid`  | Select inside definition            |

### Navigate Between Code Blocks

| Keymap | Action                        |
| ------ | ----------------------------- |
| `]f`   | Go to next function start     |
| `]F`   | Go to next function end       |
| `[f`   | Go to previous function start |
| `[F`   | Go to previous function end   |
| `]c`   | Go to next class              |
| `[c`   | Go to previous class          |
| `]a`   | Go to next parameter          |
| `[a`   | Go to previous parameter      |

---

## 🔧 ESSENTIAL COMMANDS

| Keymap      | Action                            |
| ----------- | --------------------------------- |
| `<leader>w` | Save file                         |
| `<leader>q` | Quit                              |
| `Esc`       | Clear search highlight            |
| `Ctrl-d`    | Scroll down (centered)            |
| `Ctrl-u`    | Scroll up (centered)              |
| `n`         | Next search result (centered)     |
| `N`         | Previous search result (centered) |

### Utility Commands

| Command | Action                             |
| ------- | ---------------------------------- |
| `:Crp`  | Copy relative path of current file |
| `:Cap`  | Copy absolute path of current file |

### Visual Mode

| Keymap | Action                              |
| ------ | ----------------------------------- |
| `<`    | Indent left (stays in visual)       |
| `>`    | Indent right (stays in visual)      |
| `J`    | Move line down                      |
| `K`    | Move line up                        |
| `x`    | Cut (delete and copy)               |
| `p`    | Paste without yanking replaced text |

---

## 🚀 PRO TIPS

1. **Lost in buffers?** Use `<leader>fb` to see all open files
2. **Can't find a file?** `<leader>p` searches your entire project
3. **Need to search content?** `<leader>fg` greps through all files
4. **Just opened wrong file?** `<leader>fr` shows recent files
5. **Too many splits?** Use `:only` to close all except current

---

## 🆘 WHEN YOU'RE STUCK

- **How do I get out of this mode?** → Press `Esc` (multiple times if needed)
- **Telescope won't close?** → Press `Esc`
- **Buffer won't close?** → `<leader>bd` or `:bd`
- **Everything is broken?** → `:q!` (quit without saving)
- **Need help on a command?** → `<leader>fh` (search help)
- **What keys can I press?** → Press `<Space>` and wait - which-key shows options!

---

## 📚 MOST USED DAILY COMMANDS (MEMORIZE THESE!)

### Navigation

```
<leader>e     - File tree
<leader>p     - Find file
<leader>fb    - Find buffer
g/            - Search text across files
Shift-h/l     - Previous/Next buffer
Ctrl-h/j/k/l  - Navigate windows
<leader>w     - Save
```

### Git

```
<leader>gc    - See changed files
]g / [g       - Next/previous git change (NEW!)
<leader>gp    - Preview what changed
<leader>gs    - Stage hunk
<leader>gb    - Git blame line
```

### Text Objects (the real power of Vim!)

```
vi{   - Select inside {}
va{   - Select around {} (includes braces)
ci"   - Change inside ""
da(   - Delete around () (includes parens)
vif   - Select inside function
cad   - Change around definition
vid   - Select inside definition
```

### Terminal

```
<leader>tt    - Toggle floating terminal
<leader>th    - Toggle horizontal terminal
<leader>tv    - Toggle vertical terminal
<leader>tf    - Find terminals (Telescope)
Esc (in term) - Exit terminal mode
Ctrl-w        - Close terminal
<leader>t1-4  - Switch between terminals
```
