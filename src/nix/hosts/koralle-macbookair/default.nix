{ username, ... }:
{
  imports = [
    ./homebrew.nix
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

  system = {
    stateVersion = 6;
    primaryUser = username;
  };
}
