#!/usr/bin/env bash
set -euo pipefail

src=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
usage() { printf 'Usage: %s [--profile /path/to/profile]\n' "$0"; }
profiles=()
if (( $# == 2 )) && [[ $1 == --profile && -d $2 ]]; then
    profiles+=("$2")
elif (( $# == 0 )); then
    root=$HOME/.config/librewolf
    if [[ -f $root/profiles.ini ]]; then
        while IFS=$'\t' read -r relative path; do
            [[ $relative == 1 ]] && path=$root/$path
            [[ -d $path ]] && profiles+=("$path")
        done < <(awk '
            function emit() { if (profile && path != "") print relative "\t" path }
            { sub(/\r$/, "") }
            /^\[/ { emit(); profile = /^\[Profile[0-9]+\]$/; path = ""; relative = 1 }
            /^Path=/ { path = substr($0, 6) }
            /^IsRelative=/ { relative = substr($0, 12) }
            END { emit() }
        ' "$root/profiles.ini")
    fi
else
    usage >&2
    exit 2
fi

if (( ${#profiles[@]} == 0 )); then
    printf 'No LibreWolf profiles found. Use --profile with the Root Directory from about:profiles.\n' >&2
    exit 1
fi

if command -v pgrep >/dev/null && pgrep -u "$UID" -x librewolf >/dev/null; then
    printf 'Close LibreWolf before running this installer.\n' >&2
    exit 1
fi

copy_file() {
    install -T -m 0644 -- "$1" "$2"
}

for file in user.js userContent.css gruvbox-home.html gruvbox.xpi; do
    [[ -r $src/$file ]] || { printf 'Missing or unreadable: %s\n' "$src/$file" >&2; exit 1; }
done

printf 'Note: the supplied user.js disables add-on signature enforcement where supported.\n' >&2
for profile in "${profiles[@]}"; do
    mkdir -p -- "$profile/chrome" "$profile/extensions"
    copy_file "$src/user.js" "$profile/user.js"
    copy_file "$src/userContent.css" "$profile/chrome/userContent.css"
    copy_file "$src/gruvbox-home.html" "$profile/gruvbox-home.html"
    copy_file "$src/gruvbox.xpi" "$profile/extensions/gruvbox-alacritty@local.invalid.xpi"
    printf 'Installed files in %s\n' "$profile"
done

printf 'Restart LibreWolf. If the theme is listed but inactive, enable it in about:addons.\n'
