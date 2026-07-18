alias b := build

build:
  @mise bootstrap
  @nix run home-manager -- switch --flake .#koralle
