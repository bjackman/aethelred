{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./brendan.nix
    ./common.nix
    ./kernel.nix
    ./aethelred-hardware-configuration.nix
  ];
  networking.hostName = "aethelred";

  # I have a PiKVM attached with Serial-over-USB enabled in kvmd as per
  # https://docs.pikvm.org/usb_serial/.
  # I have ensure the Pi isn't running Getty on that interface, which from its
  # perspective will be called /dev/ttyGS0 (GS = "gadget serial").
  # This is assuming the Aethelred kernel has CONFIG_USB_ACM.
  # Should then be able to read this console output from the PiKVM with just cat
  # /dev/ttyGS0.
  boot.initrd.kernelModules = [ "cdc_acm" ];
  boot.kernelParams = [ "console=tty1" ];
}
