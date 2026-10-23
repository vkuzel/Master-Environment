default:
    @just --list

# Rebuild and switch to the current configuration
update:
    ./.just/update.sh

# Update flake.lock and commit it
upgrade:
    ./.just/upgrade.sh
