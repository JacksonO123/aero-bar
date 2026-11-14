#!/bin/sh
for f in /usr/share/wayland-sessions/*.desktop /usr/local/share/wayland-sessions/*.desktop; do
    [ -r "$f" ] || continue
    grep -qE '^(Hidden|NoDisplay)=true' "$f" && continue

    id=$(basename "$f" .desktop)
    name=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
    command=$(grep -m1 '^Exec=' "$f" | cut -d= -f2-)
    names=$(grep -m1 '^DesktopNames=' "$f" | cut -d= -f2- | tr ';' ':' | sed 's/:$//')

    [ -n "$command" ] && printf '%s\t%s\t%s\t%s\n' "$id" "${name:-$id}" "$command" "$names"
done
