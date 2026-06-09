#!/bin/bash

set -eu -o pipefail

TARGET=brendan@aethelred
ITERATIONS=3
BOOT_TIMEOUT_S=60

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

for config_name in "gfp_unmapped" "next"; do
    flakeref=".#nixosConfigurations.$config_name.config.system.build.toplevel"
    system_store_path=$(nix build --no-link --print-out-paths "$flakeref")
    current_system=$(ssh "$TARGET" readlink /run/current-system)
    booted_system=$(ssh "$TARGET" readlink /run/booted-system)

    if [ "$booted_system" != "$system_store_path" ]; then
        if [ "$current_system" != "$system_store_path" ]; then
            # The --no-reexec thing is a workaround for what I think is an issue with
            # using nixos-rebuild remotely from a non-NixOS system (error: file
            # 'nixos-config' was not found in the Nix search path).
            nixos-rebuild --target-host "$TARGET" --sudo switch --store-path "$system_store_path" --no-reexec
        fi
        reboot_and_wait "$TARGET" "$BOOT_TIMEOUT_S"
    fi

    for i in $(seq "$ITERATIONS"); do
        echo "Running iteration $i of $ITERATIONS..."
        run-benchprog --target brendan@aethelred --benchprog compile-kernel --stressor secretmem
        run-benchprog --target brendan@aethelred --benchprog compile-kernel
    done
done