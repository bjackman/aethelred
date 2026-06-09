{
  writeShellApplication,
  nix,
  nixos-rebuild,
  run-benchprog,
}:

writeShellApplication {
  name = "experiment";
  runtimeInputs = [
    nix
    nixos-rebuild
    run-benchprog
  ];
  text = builtins.readFile ./experiment.sh;
}
