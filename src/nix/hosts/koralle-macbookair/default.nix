{ username, ... }:
{
  imports = [
    ./environment.nix
    ./fonts.nix
    ./homebrew.nix
    ./networking.nix
    ./security.nix
    ./services.nix
    ./system.nix
  ];

  nix = {
    optimise.automatic = true;
    settings = {
      experimental-features = "nix-command flakes";
      sandbox = true;
    };
  };

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.${username}.home = "/Users/${username}";
}
