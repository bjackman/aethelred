#!/bin/bash

set -eu -o pipefail

# Use host ssh to avoid NSS LDAP issues inside Nix env
ssh() {
    /usr/bin/ssh "$@"
}
export -f ssh

TARGET=brendan@aethelred
ITERATIONS=3
BOOT_TIMEOUT_S=60
CONFIGS=("gfp_unmapped" "next")

reboot_and_wait() {
    local target="$1"
    local timeout="$2"

    local orig_boot_id
    orig_boot_id=$(ssh "$target" cat /proc/sys/kernel/random/boot_id)

    # reboot might close the connection abruptly, ignoring exit code
    ssh "$target" sudo reboot || true

    echo "Waiting for machine to reboot..."
    local start_time
    start_time=$(date +%s)
    while true; do
        local current_boot_id
        if current_boot_id=$(ssh -o ConnectTimeout=2 -o ConnectionAttempts=1 "$target" cat /proc/sys/kernel/random/boot_id 2>/dev/null); then
            if [ "$current_boot_id" != "$orig_boot_id" ]; then
                echo "Machine rebooted successfully. New boot ID: $current_boot_id"
                break
            fi
            echo "Machine is still up with old boot ID, waiting..."
        else
            echo "Machine is unreachable, waiting..."
        fi

        local current_time
        current_time=$(date +%s)
        local elapsed
        elapsed=$((current_time - start_time))
        if [ "$elapsed" -gt "$timeout" ]; then
            echo "Timed out waiting for machine to reboot" >&2
            return 1
        fi
        sleep 2
    done
}

ensure_system_booted() {
    local config_name="$1"
    local system_store_path="$2"
    local target="$3"
    local timeout="$4"

    local current_system
    current_system=$(ssh "$target" readlink /run/current-system)
    local booted_system
    booted_system=$(ssh "$target" readlink /run/booted-system)

    if [ "$booted_system" != "$system_store_path" ]; then
        if [ "$current_system" != "$system_store_path" ]; then
            echo "Switching $target to $config_name ($system_store_path)..."
            # The --no-reexec thing is a workaround for what I think is an issue with
            # using nixos-rebuild remotely from a non-NixOS system (error: file
            # 'nixos-config' was not found in the Nix search path).
            nixos-rebuild --target-host "$target" --sudo switch --store-path "$system_store_path" --no-reexec
        fi
        reboot_and_wait "$target" "$timeout"
    else
        echo "$target is already booted into $config_name ($system_store_path)"
    fi
}

# Build all configs upfront and get their paths.
declare -A config_paths
for config_name in "${CONFIGS[@]}"; do
    echo "Building $config_name..."
    flakeref=".#nixosConfigurations.$config_name.config.system.build.toplevel"
    config_paths[$config_name]=$(nix build --no-link --print-out-paths "$flakeref")
done

booted_system=$(ssh "$TARGET" readlink /run/booted-system)

# Sort CONFIGS: put the currently booted one first to avoid unnecessary reboot
sorted_configs=()
for config_name in "${CONFIGS[@]}"; do
    if [ "${config_paths[$config_name]}" = "$booted_system" ]; then
        echo "Target is already booted into $config_name. Will run it first."
        sorted_configs+=("$config_name")
    fi
done
for config_name in "${CONFIGS[@]}"; do
    if [ "${config_paths[$config_name]}" != "$booted_system" ]; then
        sorted_configs+=("$config_name")
    fi
done

for config_name in "${sorted_configs[@]}"; do
    ensure_system_booted "$config_name" "${config_paths[$config_name]}" "$TARGET" "$BOOT_TIMEOUT_S"

    for i in $(seq "$ITERATIONS"); do
        echo "Running iteration $i of $ITERATIONS..."
        run-benchprog --target brendan@aethelred --benchprog compile-kernel --stressor secretmem
        run-benchprog --target brendan@aethelred --benchprog compile-kernel
    done
done