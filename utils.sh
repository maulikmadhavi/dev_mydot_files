#!/usr/bin/env bash
#
# utils.sh — personal shell utility library.
#
# Sourced from ~/.zshrc and ~/.bashrc so every function below is available
# as a direct command in an interactive shell, e.g.:
#
#     compare_directories ~/a ~/b
#     custom_rsync ~/a ~/b
#
# Add new utilities by defining another function anywhere in this file.
# Can also be run directly as a dispatcher: ./utils.sh <function> [args...]

# -----------------------------------------------------------------------------
# compare_directories <source_dir> <target_dir>
#   Deep-compare two directories: structure, file lists, counts, total size and
#   per-file checksums. Returns 0 if identical, 1 if they differ.
# -----------------------------------------------------------------------------
compare_directories() {
    local source_dir="$1"
    local target_dir="$2"
    local exit_code=0

    # Validate input directories
    if [[ ! -d "$source_dir" ]]; then
        echo "ERROR: Source directory '$source_dir' does not exist"
        return 1
    fi

    if [[ ! -d "$target_dir" ]]; then
        echo "ERROR: Target directory '$target_dir' does not exist"
        return 1
    fi

    echo "========================================="
    echo "Comparing Directories"
    echo "Source: $source_dir"
    echo "Target: $target_dir"
    echo "========================================="

    # 1. Compare directory structure
    echo -e "\n[1/5] Checking directory structure..."
    if diff <(cd "$source_dir" && find . -type d | sort) \
            <(cd "$target_dir" && find . -type d | sort); then
        echo "✓ Directory structures match"
    else
        echo "❌ Directory structures differ"
        exit_code=1
    fi

    # 2. Compare file lists
    echo -e "\n[2/5] Checking file lists..."
    if diff <(cd "$source_dir" && find . -type f | sort) \
            <(cd "$target_dir" && find . -type f | sort); then
        echo "✓ File lists match"
    else
        echo "❌ File lists differ"
        exit_code=1
    fi

    # 3. Compare file counts
    echo -e "\n[3/5] Checking file counts..."
    local source_count target_count
    source_count=$(find "$source_dir" -type f | wc -l)
    target_count=$(find "$target_dir" -type f | wc -l)

    echo "Source files: $source_count"
    echo "Target files: $target_count"

    if [[ $source_count -ne $target_count ]]; then
        echo "❌ File counts differ"
        exit_code=1
    else
        echo "✓ File counts match"
    fi

    # 4. Compare total sizes
    echo -e "\n[4/5] Checking total directory sizes..."
    local source_size target_size
    source_size=$(du -sb "$source_dir" | cut -f1)
    target_size=$(du -sb "$target_dir" | cut -f1)

    echo "Source size: $(numfmt --to=iec-i --suffix=B "$source_size")"
    echo "Target size: $(numfmt --to=iec-i --suffix=B "$target_size")"

    if [[ $source_size -ne $target_size ]]; then
        echo "❌ Directory sizes differ"
        exit_code=1
    else
        echo "✓ Directory sizes match"
    fi

    # 5. Compare file contents using checksums
    echo -e "\n[5/5] Checking file contents (checksums)..."
    local source_checksums target_checksums
    source_checksums=$(cd "$source_dir" && find . -type f -exec md5sum {} \; | sort -k 2)
    target_checksums=$(cd "$target_dir" && find . -type f -exec md5sum {} \; | sort -k 2)

    if diff <(echo "$source_checksums") <(echo "$target_checksums"); then
        echo "✓ File contents match"
    else
        echo "❌ File contents differ"
        exit_code=1
    fi

    # Final summary
    echo -e "\n========================================="
    if [[ $exit_code -eq 0 ]]; then
        echo "✓ SUCCESS: Directories are identical"
    else
        echo "❌ FAILURE: Directories differ"
    fi
    echo "========================================="

    return $exit_code
}

# -----------------------------------------------------------------------------
# custom_rsync <source> <target> [extra rsync args...]
#   Mirror source -> target with sensible defaults: archive mode, human-readable
#   progress, and a dry-run preview that you confirm before the real copy.
# -----------------------------------------------------------------------------
custom_rsync() {
    local source="$1"
    local target="$2"
    shift 2 2>/dev/null

    if [[ -z "$source" || -z "$target" ]]; then
        echo "Usage: custom_rsync <source> <target> [extra rsync args...]"
        return 2
    fi

    local opts=(-a -h --info=progress2 "$@")

    echo "Dry run: rsync ${opts[*]} \"$source\" \"$target\""
    rsync --dry-run "${opts[@]}" "$source" "$target"

    printf 'Proceed with the real copy? [y/N] '
    local reply
    read -r reply
    if [[ "$reply" == [Yy]* ]]; then
        rsync "${opts[@]}" "$source" "$target"
    else
        echo "Aborted."
        return 1
    fi
}

# -----------------------------------------------------------------------------
# When executed directly (not sourced), act as a dispatcher:
#   ./utils.sh compare_directories ~/a ~/b
# Sourcing the file (from .zshrc/.bashrc) only defines the functions above.
# -----------------------------------------------------------------------------
if [[ -n "${BASH_VERSION:-}" && "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <function> [args...]"
        echo "Available functions:"
        echo "  compare_directories <source_dir> <target_dir>"
        echo "  custom_rsync <source> <target> [extra rsync args...]"
        exit 2
    fi
    "$@"
    exit $?
fi
