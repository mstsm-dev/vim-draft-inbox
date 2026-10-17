#!/bin/sh
set -eu

VIM_ROOT="${VIM_ROOT:-$HOME/.vim}"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --vim-root)
            [ "$#" -ge 2 ] || exit 2
            VIM_ROOT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: ./uninstall.sh [--vim-root PATH]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

PLUGIN_FILE="$VIM_ROOT/plugin/vim_draft_inbox.vim"
HELP_FILE="$VIM_ROOT/doc/vim-draft-inbox.txt"
DOC_DIR="$VIM_ROOT/doc"

if [ -f "$PLUGIN_FILE" ]; then
    rm -f "$PLUGIN_FILE"
    echo "Removed: $PLUGIN_FILE"
fi

if [ -f "$HELP_FILE" ]; then
    rm -f "$HELP_FILE"
    echo "Removed: $HELP_FILE"
fi

if command -v vim >/dev/null 2>&1 && [ -d "$DOC_DIR" ]; then
    vim -Nu NONE -n -es \
        "+execute 'helptags ' . fnameescape('$DOC_DIR')" \
        "+qa" || true
fi

echo "vim-draft-inbox uninstallation completed."
