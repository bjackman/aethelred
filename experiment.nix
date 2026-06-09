{
  writeShellApplication,
  openssh,
  nix,
  nixos-rebuild,
  run-benchprog,
}:

writeShellApplication {
  name = "experiment";
  runtimeInputs = [
    openssh
    nix
    nixos-rebuild
    run-benchprog
  ];
  text = builtins.readFile ./experiment.sh;
}
