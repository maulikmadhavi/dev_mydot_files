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
# _progress_bar <current> <total> [label]   (private helper)
#   Draws/updates a single-line progress bar on stderr. No-op when stderr is
#   not a terminal, so piped/scripted output stays clean.
# -----------------------------------------------------------------------------
_progress_bar() {
    [ -t 2 ] || return 0
    local cur=$1 total=$2 label=${3:-}
    local width=40
    local hashes="########################################"   # 40 '#'
    local spaces="                                        "    # 40 ' '
    local pct=0 filled=0
    if [ "${total:-0}" -gt 0 ] 2>/dev/null; then
        pct=$(( cur * 100 / total ))
        filled=$(( pct * width / 100 ))
    fi
    printf '\r%s [%s%s] %3d%% (%d/%d)' \
        "$label" "${hashes:0:filled}" "${spaces:0:$((width - filled))}" \
        "$pct" "$cur" "$total" >&2
}

# -----------------------------------------------------------------------------
# _hash_tree <dir> <total> <label> <hasher> [jobs]   (private helper)
#   Prints a sorted "<hash>  ./path" manifest of every file under <dir> to
#   stdout, while animating a progress bar on stderr as files complete.
#   Hashing runs in parallel across <jobs> processes (default 1). -print0/-0
#   keep filenames with spaces or newlines safe.
# -----------------------------------------------------------------------------
_hash_tree() {
    local dir=$1 total=$2 label=$3 hasher=$4 jobs=${5:-1}
    local raw
    raw=$(mktemp) || return 1
    # Hash into a regular file, not a pipe. A file reader never "goes away", so
    # the hasher processes can't get a closed stdout — this avoids the
    # "failed printing to stdout: Broken pipe" panics that Rust hashers
    # (b3sum/xxhsum) throw when a downstream consumer (e.g. `head`) exits early.
    ( cd "$dir" && find . -type f -print0 | xargs -0 -r -P"$jobs" "$hasher" >"$raw" ) &
    local pid=$!
    if [ -t 2 ]; then
        # Sample progress from the growing manifest until hashing finishes.
        while kill -0 "$pid" 2>/dev/null; do
            _progress_bar "$(wc -l <"$raw" 2>/dev/null || echo 0)" "$total" "$label"
            sleep 0.2
        done
        _progress_bar "$total" "$total" "$label"
        printf '\n' >&2
    fi
    wait "$pid"
    sort -k2 "$raw"
    rm -f "$raw"
}

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

    # 5. Compare file contents using checksums (with progress bar)
    echo -e "\n[5/5] Checking file contents (checksums)..."
    local source_checksums target_checksums
    source_checksums=$(_hash_tree "$source_dir" "$source_count" "      source" md5sum)
    target_checksums=$(_hash_tree "$target_dir" "$target_count" "      target" md5sum)

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
# fixspaces <dir>
#   Recursively rename files and directories under <dir>, replacing every space
#   in their names with a dash.
#   NOTE: ${f// /-} rewrites spaces in the WHOLE path, so an entry fails to move
#   if one of its parent directories still has a space (renamed later, due to
#   -depth). Reliable when only leaf names contain spaces; otherwise run it more
#   than once, or rename only the basename.
# fixspaces_preview <dir>
#   Same as fixspaces but only prints the mv commands without running them.
# -----------------------------------------------------------------------------
fixspaces(){ find "$1" -depth -name "* *" -exec bash -c 'for f; do mv "$f" "${f// /-}"; done' _ {} +; }

fixspaces_preview(){ find "$1" -depth -name "* *" -exec bash -c 'for f; do echo mv "$f" "${f// /-}"; done' _ {} +; }

# -----------------------------------------------------------------------------
# compare_fast_directories <source_dir> <target_dir>
#   Fast, reliable content comparison of two directory trees. Hashes every file
#   in parallel (one process per core) using the fastest available tool
#   (b3sum > xxh128sum > xxhsum > sha1sum > md5sum), then diffs the two
#   manifests. Lines prefixed '<' are only-in/differ-on source, '>' on target.
#   Catches changed contents AND files present on only one side in a single pass.
#   Returns 0 if contents are identical, 1 if they differ.
# -----------------------------------------------------------------------------
compare_fast_directories() {
    local source_dir="$1"
    local target_dir="$2"

    if [[ ! -d "$source_dir" ]]; then
        echo "ERROR: Source directory '$source_dir' does not exist"
        return 2
    fi
    if [[ ! -d "$target_dir" ]]; then
        echo "ERROR: Target directory '$target_dir' does not exist"
        return 2
    fi

    # Pick the fastest hash tool that's installed.
    local hasher=""
    local h
    for h in b3sum xxh128sum xxhsum sha1sum md5sum; do
        if command -v "$h" >/dev/null 2>&1; then
            hasher="$h"
            break
        fi
    done
    if [[ -z "$hasher" ]]; then
        echo "ERROR: no hashing tool found (tried b3sum, xxh128sum, xxhsum, sha1sum, md5sum)"
        return 2
    fi

    local jobs
    jobs=$(nproc 2>/dev/null || echo 4)

    local source_total target_total
    source_total=$(find "$source_dir" -type f | wc -l)
    target_total=$(find "$target_dir" -type f | wc -l)

    echo "Comparing (hash=$hasher, parallel jobs=$jobs)"
    echo "Source: $source_dir ($source_total files)"
    echo "Target: $target_dir ($target_total files)"

    # Hash each tree in parallel with a live progress bar; manifests are sorted
    # by path so the diff lines up. -print0/-0 keep odd filenames safe.
    local source_sums target_sums
    source_sums=$(_hash_tree "$source_dir" "$source_total" "  source" "$hasher" "$jobs")
    target_sums=$(_hash_tree "$target_dir" "$target_total" "  target" "$hasher" "$jobs")

    local delta n
    delta=$(diff <(printf '%s\n' "$source_sums") <(printf '%s\n' "$target_sums"))
    if [ -z "$delta" ]; then
        echo "✓ SUCCESS: Directory contents are identical"
        return 0
    fi
    n=$(printf '%s\n' "$delta" | grep -c '^[<>]')
    echo "❌ FAILURE: $n differing file entries (source=<, target=>):"
    printf '%s\n' "$delta" | grep '^[<>]' | head -100
    [ "$n" -gt 100 ] && echo "... ($n total; showing first 100)"
    return 1
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
        echo "  compare_fast_directories <source_dir> <target_dir>"
        echo "  custom_rsync <source> <target> [extra rsync args...]"
        echo "  fixspaces <dir>"
        echo "  fixspaces_preview <dir>"
        exit 2
    fi
    "$@"
    exit $?
fi
