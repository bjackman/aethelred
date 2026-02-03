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
    # Desperately trying to get the build to not fail because of missing
    # modules. I have deliberately disabled those modules to make the build
    # faster. But this doesn't work.
    initrd = {
      availableKernelModules = [ ];
      # Enable storage drivers in initrd, maybe this helps with crashdump stuff?
      kernelModules = [ "nvme" "ext4" ];
      includeDefaultModules = false;
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
  # Need root login password for crash kernel. hunter2
  users.users.root.hashedPassword = "$6$tTuhmmP./Fie2O1M$q8AA.WWHO.iQu5ImeQ2/sKRZbLkxSyWyZhI8PFwIUfiqMMx1ctJK/PD91Qk5LxslIuWDA0SFKw9njNWdvtjhh.";
}
