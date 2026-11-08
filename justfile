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

# Test the configuration in the current session w/o making it boot default
test:
    sudo nixos-rebuild switch --flake "."

# Rebuild and switch to the current configuration
switch:
    ./.just/switch.sh
