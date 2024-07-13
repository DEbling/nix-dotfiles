# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  networking.hostName = "x220"; # Define your hostname.
  # Pick only one of the below networking options.
  networking.wireless.enable = false;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "America/Sao_Paulo";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true; # use xkbOptions in tty.
  };


  # Enable the X11 windowing system.
  services = {

    # zoneminder = {
    #   enable = true;
    #   openFirewall = true;
    #   database = {
    #     createLocally = true;
    #     host = "localhost";
    #     name = "zm";
    #     username = "zoneminder";
    #     password = "zmpass";
    #   };
    #   cameras = 1;
    #   };

    # Enable touchpad support (enabled default in most desktopManager).
    libinput.enable = true;

    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        hinfo = true;
        userServices = true;
        workstation = true;
      };
    };
    # greetd = {
    #   enable = true;
    #   settings =
    #     let
    #       tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet";
    #       session = "${pkgs.hyprland}/bin/Hyprland";
    #       username = "debling";
    #     in
    #     {
    #       initial_session = {
    #         command = "${session}";
    #         user = "${username}";
    #       };
    #       default_session = {
    #         command = "${tuigreet} --greeting 'Welcome to NixOS!' --asterisks --remember --remember-user-session --time --cmd ${session}";
    #         user = "greeter";
    #       };
    #     };
    # };
    #    xserver = {
    #      enable = true;
    #      windowManager.i3.enable = true;
    #      displayManager.autoLogin.user = "debling";
    #      desktopManager = {
    #        xterm.enable = false;
    #        xfce = {
    #          enable = true;
    #          noDesktop = true;
    #          enableXfwm = false;
    #        };
    #      };
    #      # Configure keymap in X11
    #      layout = "br";
    #      xkbVariant = "thinkpad";
    #      xkbOptions = "caps:escape"; # map caps to escape.
    #    };




       xserver = {
         enable = true;
         displayManager.gdm.enable = true;
         desktopManager.gnome.enable = true;
         displayManager.autoLogin.user = "debling";
         # Configure keymap in X11
         layout = "br";
         xkbVariant = "thinkpad";
       };



    # tlp.enable = true;

    blueman.enable = true;
  };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound = {
    enable = true;
    mediaKeys.enable = true;
  };
  security.rtkit.enable = true;
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  #   alsa.enable = true;
  # };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.debling = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "podman" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      firefox
    ];
    hashedPassword = "$y$j9T$O4qn0aOF8U9FQPiMXsv41/$CkOtnJbkV4lcZcCwQnUL0u4xlfoYhvN.9pCUzT2uFI5";
    shell = pkgs.zsh;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    systemPackages = with pkgs; [
      uxplay
      neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      tmux
      wget
      alacritty
      git

      bitwarden
      bitwarden-cli
      spotify
      # waybar
      # wofi
      # mako
      # libnotify
    ];


    sessionVariables = {
      WLR_NO_HARDWARE_CURSORS = "1";
      # Hint electron apps to use wayland
      NIXOS_OZONE_WL = "1";

      _JAVA_AWT_WM_NONREPARENTING = "1";
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs = {
    thunar.enable = true;
    steam.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    zsh.enable = true;
    neovim.enable = true;

    hyprland.enable = true;
  };

  # xdg.portal = {
  #   enable = true;
  #   extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  virtualisation = {
    docker.enable = true;
    # virtualbox.host.enable = true;
    libvirtd.enable = true;
    # waydroid.enable = true;
  };

  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;
    packages = with pkgs; [
      corefonts # microsoft free fonts
      source-sans-pro
      source-serif-pro
      (nerdfonts.override {
        fonts = [ "JetBrainsMono" ];
      })
    ];
    fontconfig.defaultFonts = {
      monospace = [ "JetBrainsMono Nerd Font" ];
      sansSerif = [ "Source Sans Pro" ];
      serif = [ "Source Serif Pro" ];
    };
  };


# systemd.timers."hello-world" = {
#   wantedBy = [ "timers.target" ];
#     timerConfig = {
#       OnBootSec = "5m";
#       OnUnitActiveSec = "5m";
#       Unit = "duckdns.service";
#     };
# };
#
# systemd.services."duckdns" = {
#   script = ''
#     set -eu
#     ${pkgs.coreutils}/bin/echo url="https://www.duckdns.org/update?domains=debling&token=ca64b58b-843b-43e7-8706-73fefbaa6f6b&ip=&ipv6=&verbose=true" \
#     | ${pkgs.curl}/bin/curl -k -K -
#   '';
#   serviceConfig = {
#     Type = "oneshot";
#     User = "root";
#   };
# };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
