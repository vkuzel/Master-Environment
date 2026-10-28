default:
    @just --list

# Format the current configuration
format:
    nix fmt .

# Check the current configuraiton
check:
    nix flake check --print-build-logs

# Rebuild and switch to the current configuration
update:
    ./.just/update.sh

# Update flake.lock and commit it
upgrade:
    ./.just/upgrade.sh
