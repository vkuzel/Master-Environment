default:
    @just --list

# Format the current configuration
format:
    nix fmt .

# Check the current configuraiton
check:
    nix flake check --print-build-logs

# Update Flake and commit it
update:
    ./.just/update.sh

# Rebuild and switch to the current configuration
switch:
    ./.just/switch.sh
