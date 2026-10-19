#!/bin/bash
set -euo pipefail
printf '%s\n' 'This removes ONLY the system-wide OpenMB.component AU.' \
  'It preserves all user presets and unrelated plugins.' \
  'Close Logic and other audio hosts first. Type REMOVE to continue:'
read -r reply
[[ "$reply" == REMOVE ]] || exit 0
TARGET=/Library/Audio/Plug-Ins/Components/OpenMB.component
if [[ -e "$TARGET" || -L "$TARGET" ]]; then
    /usr/bin/sudo /bin/rm -rf "$TARGET"
    echo 'Removed OpenMB.component. Reopen Logic.'
else
    echo 'No system-wide OpenMB.component was found.'
fi
