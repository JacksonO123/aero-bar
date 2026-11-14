#!/bin/sh
# The accounts that can log in, one per line: name<TAB>display name<TAB>picture path.
# Regular users only (uid 1000-59999) with a real login shell. The picture is the first
# readable one of AccountsService's icon, ~/.face and ~/.face.icon (the greeter user usually
# can't read home directories, so AccountsService's copy is the one that tends to work).
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
