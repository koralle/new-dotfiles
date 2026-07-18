alias b := build

build:
  @mise bootstrap
  @sudo darwin-rebuild switch --flake .#koralle-macbookair
