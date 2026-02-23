#!/usr/bin/env bash
#
# pnpm-outdated-summary.sh
# Parses pnpm -r outdated output and displays a color-coded summary
#
# Usage: pnpm-outdated-summary.sh
#        pnpm -r outdated 2>&1 | pnpm-outdated-summary.sh
#

# Colors
RESET=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
MAGENTA=$'\033[35m'
CYAN=$'\033[36m'
BRIGHT_RED=$'\033[91m'
BRIGHT_GREEN=$'\033[92m'
BRIGHT_CYAN=$'\033[96m'

# Temp files to store categorized packages
TMPDIR="${TMPDIR:-/tmp}"
deprecated_file=$(mktemp "${TMPDIR}/outdated_deprecated.XXXXXX")
safe_file=$(mktemp "${TMPDIR}/outdated_safe.XXXXXX")
major_file=$(mktemp "${TMPDIR}/outdated_major.XXXXXX")

cleanup() {
    rm -f "$deprecated_file" "$safe_file" "$major_file"
}
trap cleanup EXIT

# Function to compare semver and determine update type
get_update_type() {
    local current="$1"
    local latest="$2"

    # Extract major version numbers
    local curr_major lat_major curr_minor lat_minor

    curr_major=$(echo "$current" | sed -E 's/^([0-9]+).*/\1/' | head -1)
    lat_major=$(echo "$latest" | sed -E 's/^([0-9]+).*/\1/' | head -1)

    # Handle non-numeric versions
    if ! [[ "$curr_major" =~ ^[0-9]+$ ]] || ! [[ "$lat_major" =~ ^[0-9]+$ ]]; then
        echo "minor"
        return
    fi

    if [[ "$lat_major" -gt "$curr_major" ]]; then
        echo "major"
        return
    fi

    curr_minor=$(echo "$current" | sed -E 's/^[0-9]+\.([0-9]+).*/\1/' | head -1)
    lat_minor=$(echo "$latest" | sed -E 's/^[0-9]+\.([0-9]+).*/\1/' | head -1)

    if ! [[ "$curr_minor" =~ ^[0-9]+$ ]] || ! [[ "$lat_minor" =~ ^[0-9]+$ ]]; then
        echo "minor"
        return
    fi

    if [[ "$lat_minor" -gt "$curr_minor" ]]; then
        echo "minor"
        return
    fi

    echo "patch"
}

# Read input (from pipe or run command)
# Check if stdin has data available (not just whether it's a TTY)
if [[ -t 0 ]] || [[ ! -p /dev/stdin ]]; then
    # No pipe or not a pipe device, run pnpm -r outdated with --color to get table format
    input=$(pnpm -r outdated --color 2>&1 || true)
else
    # Read from pipe
    input=$(cat)
fi

# Strip ANSI color codes and control characters from input for parsing
# Use perl for more reliable ANSI stripping
if command -v perl &> /dev/null; then
    input=$(echo "$input" | perl -pe 's/\e\[[0-9;]*[a-zA-Z]//g' | tr -d '\r')
else
    # Fallback to sed
    input=$(echo "$input" | sed $'s/\x1b\[[0-9;]*[a-zA-Z]//g' | tr -d '\r')
fi

# Check if there are any updates
if [[ -z "$input" ]] || ! echo "$input" 2>/dev/null | grep -q "│"; then
    echo -e "${BRIGHT_GREEN}${BOLD}✓ All packages are up to date! Nothing to update.${RESET}"
    exit 0
fi

# Parse the table output and write to temp files
current_package=""
current_version=""
latest_version=""
workspaces=""

save_package() {
    if [[ -z "$current_package" ]]; then
        return
    fi

    # Remove (dev) suffix for display key
    local key="${current_package% (dev)}"

    if [[ "$latest_version" == "Deprecated" ]]; then
        echo "${key}|${current_version}|Deprecated|${workspaces}" >> "$deprecated_file"
    else
        local update_type
        update_type=$(get_update_type "$current_version" "$latest_version")
        if [[ "$update_type" == "major" ]]; then
            echo "${key}|${current_version}|${latest_version}|${workspaces}" >> "$major_file"
        else
            echo "${key}|${current_version}|${latest_version}|${workspaces}" >> "$safe_file"
        fi
    fi
}

while IFS= read -r line; do
    # Skip header and border lines
    if [[ "$line" =~ ^[├└┌┬┐─┼┤┘]+$ ]] || [[ "$line" == *"Package"*"Current"* ]]; then
        continue
    fi

    # Skip warning lines
    if [[ "$line" == *"WARN"* ]]; then
        continue
    fi

    # Parse data rows
    if [[ "$line" == │* ]]; then
        # Extract columns - handle the box drawing characters
        pkg=$(echo "$line" | awk -F'│' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
        curr=$(echo "$line" | awk -F'│' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}')
        lat=$(echo "$line" | awk -F'│' '{gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4}')
        ws=$(echo "$line" | awk -F'│' '{gsub(/^[ \t]+|[ \t]+$/, "", $5); print $5}')

        # Check if this is a continuation line (package name is empty)
        if [[ -z "$pkg" && -n "$ws" ]]; then
            # Continuation of workspaces from previous line
            if [[ -n "$workspaces" ]]; then
                workspaces="${workspaces}, ${ws}"
            else
                workspaces="$ws"
            fi
            continue
        fi

        # If we have a previous package to save, save it now
        if [[ -n "$current_package" ]]; then
            save_package
        fi

        # Start new package
        if [[ -n "$pkg" ]]; then
            current_package="$pkg"
            current_version="$curr"
            latest_version="$lat"
            workspaces="$ws"
        fi
    fi
done <<< "$input"

# Don't forget the last package
if [[ -n "$current_package" ]]; then
    save_package
fi

# Deduplicate and merge workspaces for same packages
dedupe_file() {
    local infile="$1"
    local outfile=$(mktemp "${TMPDIR}/outdated_deduped.XXXXXX")

    if [[ ! -s "$infile" ]]; then
        echo "$outfile"
        return
    fi

    # Sort by package name, then merge workspaces for duplicates
    # Also clean up double commas and extra spaces
    sort -t'|' -k1,1 "$infile" | awk -F'|' '
    {
        pkg = $1
        curr = $2
        lat = $3
        ws = $4
        if (pkg == prev_pkg) {
            # Merge workspaces
            prev_ws = prev_ws ", " ws
        } else {
            if (prev_pkg != "") {
                # Clean up workspace string: remove double commas, extra spaces
                gsub(/,[ ]*,/, ",", prev_ws)
                gsub(/,[ ]+/, ", ", prev_ws)
                gsub(/^[ ,]+|[ ,]+$/, "", prev_ws)
                print prev_pkg "|" prev_curr "|" prev_lat "|" prev_ws
            }
            prev_pkg = pkg
            prev_curr = curr
            prev_lat = lat
            prev_ws = ws
        }
    }
    END {
        if (prev_pkg != "") {
            gsub(/,[ ]*,/, ",", prev_ws)
            gsub(/,[ ]+/, ", ", prev_ws)
            gsub(/^[ ,]+|[ ,]+$/, "", prev_ws)
            print prev_pkg "|" prev_curr "|" prev_lat "|" prev_ws
        }
    }
    ' > "$outfile"

    echo "$outfile"
}

# Deduplicate each category
deprecated_deduped=$(dedupe_file "$deprecated_file")
safe_deduped=$(dedupe_file "$safe_file")
major_deduped=$(dedupe_file "$major_file")

# Count packages
deprecated_count=$(wc -l < "$deprecated_deduped" | tr -d ' ')
safe_count=$(wc -l < "$safe_deduped" | tr -d ' ')
major_count=$(wc -l < "$major_deduped" | tr -d ' ')

# Print header
echo -e "${BRIGHT_CYAN}${BOLD}═══════════════════════════════════════════════════════${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}  AVAILABLE PACKAGE UPDATES${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}═══════════════════════════════════════════════════════${RESET}"
echo ""

# Print deprecated packages (compact list)
if [[ $deprecated_count -gt 0 ]]; then
    echo -e "${BOLD}${YELLOW}⚠ DEPRECATED${RESET} (${deprecated_count}): ${DIM}$(cut -d'|' -f1 "$deprecated_deduped" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')${RESET}"
fi

# Print safe packages (compact list)
if [[ $safe_count -gt 0 ]]; then
    echo -e "${BOLD}${BRIGHT_GREEN}✓ SAFE${RESET} (${safe_count}): ${DIM}$(cut -d'|' -f1 "$safe_deduped" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')${RESET}"
fi

# Print major packages (compact list)
if [[ $major_count -gt 0 ]]; then
    echo -e "${BOLD}${BRIGHT_RED}⬆ MAJOR${RESET} (${major_count}): ${DIM}$(cut -d'|' -f1 "$major_deduped" | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')${RESET}"
fi

# Cleanup deduped files
rm -f "$deprecated_deduped" "$safe_deduped" "$major_deduped"

# Print summary
echo ""
echo -e "${BRIGHT_CYAN}${BOLD}═══════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}Summary:${RESET} ${YELLOW}${deprecated_count} deprecated${RESET} │ ${GREEN}${safe_count} safe${RESET} │ ${BRIGHT_RED}${major_count} major${RESET}"
echo -e "${BRIGHT_CYAN}${BOLD}═══════════════════════════════════════════════════════${RESET}"
