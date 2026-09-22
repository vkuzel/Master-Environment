#!/bin/bash

resolve_script_dir() {
    local source="${BASH_SOURCE[0]}"
    local dir target

    while [ -L "$source" ]; do
        dir="$(cd -- "$(dirname -- "$source")" && pwd -P)"
        target="$(readlink -- "$source")"

        if [[ "$target" = /* ]]; then
            source="$target"
        else
            source="$dir/$target"
        fi
    done

    cd -- "$(dirname -- "$source")" && pwd -P
}

scriptDir="$(resolve_script_dir)"
nixDir=$(realpath -m "$scriptDir/../../.config/nix")

nix develop "path:$nixDir/copilot"
