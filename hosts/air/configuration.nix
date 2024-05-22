{ pkgs, ... }:
{
  # documentation = {
  #   enable = false;
  #   doc.enable = false;
  #   info.enable = false;
  # };

  # Enable experimental nix command and flakes
  # nix.package = pkgs.nixUnstable;
  nix = {
    configureBuildUsers = true;
    settings = {
      trusted-users = [ "debling" "@admin" ];
      auto-optimise-store = true;
    };
    extraOptions = ''
      experimental-features = nix-command flakes
      extra-platforms = x86_64-darwin aarch64-darwin
    '';
    useDaemon = true;

    # Enable the linux builder, which allows to build packages, and most important
    # use the build-vm feature
    linux-builder.enable = true;
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
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    ];
  };

  environment.systemPackages = with pkgs; [
    pinentry_mac

    # Linux programing api pages
    man-pages-posix
  ];

  security.pam.enableSudoTouchIdAuth = true;

  services = {
    yabai = {
      enable = true;
      enableScriptingAddition = true;
      config = {
        # default layout (can be bsp, stack or float)
        layout = "bsp";
        window_border = "off";
        window_shadow = "float";
        # New window spawns to the right if vertical split, or bottom if horizontal split
        window_placement = "second_child";

        # modifier for clicking and dragging with mouse
        mouse_modifier = "alt";
        mouse_drop_action = "swap";

        # padding set to 8px
        top_padding = 6;
        bottom_padding = 6;
        left_padding = 6;
        right_padding = 6;
        window_gap = 6;

        window_opacity = "on";
        active_window_opacity = "1.0";
        normal_window_opacity = "0.9";

        window_animation_duration = 0.0;
      };
      extraConfig = builtins.readFile ../../config/yabai/yabairc;
    };

    skhd = {
      enable = true;
      skhdConfig = builtins.readFile ../../config/skhd/skhdrc;
    };
  };

  # TODO: Move this config to home-manager
  system = {
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };
    defaults = {
      NSGlobalDomain = {
        InitialKeyRepeat = 15;
        KeyRepeat = 1;

        NSAutomaticWindowAnimationsEnabled = true;

        _HIHideMenuBar = true;
      };
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

      dock = {
        autohide = true;
        autohide-delay = 0.1;
        autohide-time-modifier = 0.1;
        expose-animation-duration = 0.1;

        tilesize = 32;
      };
      finder.AppleShowAllFiles = true; # Show hidden files
      screencapture.type = "png";
    };
  };

  homebrew = {
    enable = true;
    casks = [
      "android-studio"
      "anydesk"
      "bitwarden"
      "docker"
      "iterm2"
      "maccy"
      "miniconda"
      "obsidian"
      "slack"
      "spotify"
      "keycastr"
    ];
  };
}
