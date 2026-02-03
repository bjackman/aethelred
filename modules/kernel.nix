# Stuff for doing kernel development.
{ pkgs, config, ... }:
{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        # Try to stop /boot getting full
        configurationLimit = 8;
      };
      efi.canTouchEfiVariables = true;
    };
  };
  hardware.enableAllHardware = false;

  powerManagement.cpuFreqGovernor = "performance";

  environment.systemPackages = [
    pkgs.bpftrace
    # It's annoying to recompile perf every time we change the kernel, so we
    # just use the latest NixOS perf regardless of what is installed in the
    # system. To use the exact corresponding perf package, replace this with:
    # config.boot.kernelPackages.perf
    pkgs.perf
  ];

  services.getty.autologinUser = "root";

  boot.crashDump = {
    enable = true;
    reservedMemory = "1G";
  };

  boot.initrd.kernelModules = [ "nvme" "ext4" ];
}
