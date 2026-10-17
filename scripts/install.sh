#!/bin/sh
set -eu

VIM_ROOT="${VIM_ROOT:-$HOME/.vim}"
FORCE=0

usage() {
    cat <<'EOF'
Usage:
  ./install.sh [--vim-root PATH] [--force]
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --vim-root)
            [ "$#" -ge 2 ] || exit 2
            VIM_ROOT="$2"
            shift 2
            ;;
        --force)
            FORCE=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PACKAGE_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

SOURCE_PLUGIN="$PACKAGE_ROOT/plugin/vim_draft_inbox.vim"
SOURCE_HELP="$PACKAGE_ROOT/doc/vim-draft-inbox.txt"

PLUGIN_DIR="$VIM_ROOT/plugin"
DOC_DIR="$VIM_ROOT/doc"

TARGET_PLUGIN="$PLUGIN_DIR/vim_draft_inbox.vim"
TARGET_HELP="$DOC_DIR/vim-draft-inbox.txt"

mkdir -p "$PLUGIN_DIR" "$DOC_DIR"

copy_file() {
    src="$1"
    dst="$2"

    if [ -f "$dst" ] && [ "$FORCE" -ne 1 ]; then
        cp -p "$dst" "$dst.bak"
        echo "Backup: $dst.bak"
    fi

    cp "$src" "$dst"
    echo "Installed: $dst"
}

copy_file "$SOURCE_PLUGIN" "$TARGET_PLUGIN"
copy_file "$SOURCE_HELP" "$TARGET_HELP"

if command -v vim >/dev/null 2>&1; then
    echo "Generating Vim help tags..."
    vim -Nu NONE -n -es \
        "+execute 'helptags ' . fnameescape('$DOC_DIR')" \
        "+qa" || true
else
    echo "vim was not found in PATH." >&2
    echo "Run this in Vim: :helptags $DOC_DIR" >&2
fi

echo
echo "vim-draft-inbox 1.0.0 installation completed."
echo "Plugin : $TARGET_PLUGIN"
echo "Help   : $TARGET_HELP"
