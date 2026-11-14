#!/bin/sh
# AccountsService first: the greeter user usually can't read home directories
getent passwd | while IFS=: read -r name _ uid _ gecos home shell; do
    [ "$uid" -ge 1000 ] 2>/dev/null && [ "$uid" -lt 60000 ] || continue
    case "$shell" in */nologin | */false | "") continue ;; esac

    picture=""
    for f in "/var/lib/AccountsService/icons/$name" "$home/.face" "$home/.face.icon"; do
        if [ -r "$f" ] && [ -s "$f" ]; then
            picture="$f"
            break
        fi
    done

    printf '%s\t%s\t%s\n' "$name" "${gecos%%,*}" "$picture"
done
