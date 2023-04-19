{ pkgs, ... }:
{
  # Enable experimental nix command and flakes
  # nix.package = pkgs.nixUnstable;
  nix = {
    package = pkgs.nixUnstable;
    configureBuildUsers = true;
    settings = {
      trusted-users = [ "debling" "@admin" ];
    };
    extraOptions = ''
      auto-optimise-store = true
      experimental-features = nix-command flakes
      build-users-group = nixbld
      extra-platforms = x86_64-darwin aarch64-darwin
    '';
    useDaemon = true;
  };

  programs = {
    # Create /etc/bashrc that loads the nix-darwin environment.
    zsh.enable = true;
  };

  # Fonts
  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      jetbrains-mono
      nerdfonts
    ];
  };

  # Keyboard
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };
}
