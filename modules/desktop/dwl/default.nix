{ config, lib, pkgs, mainUser, nix-colors, colorscheme, ... }:


let
  dwlb = pkgs.callPackage ./dwlb.nix { };
  # main - 29-12-2024
  dwl-patches = pkgs.fetchFromGitea {
    domain = "codeberg.org";
    owner = "dwl";
    repo = "dwl-patches";
    rev = "e7752b138afcc4d8b43261d53458e1ae44359857";
    hash = "sha256-DradTawxoDj96Qm4Hs1mErpdXTVIrQrBMQxhPvIIIIA=";
  };
  dwl-with-patches = pkgs.dwl.overrideAttrs (prev: {
    # main - 29-12-2024
    src = pkgs.fetchFromGitea {
      domain = "codeberg.org";
      owner = "dwl";
      repo = "dwl";
      rev = "30f5063474a70835d0178ffc12521a3e0fb1ef8b";
      hash = "sha256-oOJLsJMYNpQOIrbX8L0GNwg7U+JddaPBsSuI3I2Zf8Q=";
    };
    buildInputs = with pkgs; [
      libinput
      xorg.libxcb
      libxkbcommon
      pixman
      wayland
      wayland-protocols
      wlroots
      xorg.libX11
      xorg.xcbutilwm
      xwayland
    ];

    patches = [
      "${dwl-patches}/patches/ipc/ipc.patch"
      "${dwl-patches}/patches/smartborders/smartborders.patch"
      "${dwl-patches}/patches/kblayout/kblayout.patch"
    ];

    passthru = {
      providedSessions = [ prev.meta.mainProgram ];
    };
  });

  dwl = dwl-with-patches.override {
    configH = ./config.def.h;
  };

  slstatus = pkgs.slstatus.override {
    conf = ./slstatus-config.h;
  };


  dwl-run = pkgs.writeShellScriptBin "dwl-run" ''
    set -x

    systemctl --user is-active dwl-session.target \
      && echo "DWL is already running" \
      && exit 1

    # The commands below were adapted from:
    # https://github.com/NixOS/nixpkgs/blob/ad3e815dfa9181aaa48b9aa62a00cf9f5e4e3da7/nixos/modules/programs/wayland/sway.nix#L122
    # Import the most important environment variables into the D-Bus and systemd
    dbus-run-session -- ${lib.getExe dwl} -s "
      dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_SESSION_TYPE;
      systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_SESSION_TYPE;
      systemctl --user start dwl-session.target;
    " & 
    dwlPID=$!
    wait $dwlPID
    systemctl --user stop dwl-session.target
  '';

  volume = pkgs.writeShellApplication {
    name = "volume";
    runtimeInputs = with pkgs; [ libnotify pipewire ];
    text = builtins.readFile ./volume;
  };

  screenshot = pkgs.writeShellApplication {
    name = "screenshot";

    runtimeInputs = with pkgs; [ grim slurp satty ];

    text = ''
      grim -g "$(slurp -c '#ff0000ff')" -t ppm - \
        | satty --filename - \
                --fullscreen \
                --output-filename "$HOME/Pictures/Screenshots/satty-$(date '+%Y%m%d-%H:%M:%S').png";
    '';
  };
in
{
  config = {
    environment = {
      systemPackages = [
        pkgs.slurp
        pkgs.grim
        screenshot
        volume
        pkgs.wl-clipboard
        dwl-run
        dwl
        dwlb
        slstatus
        pkgs.brightnessctl
        pkgs.bemenu
        pkgs.libnotify
        pkgs.foot
        pkgs.playerctl
        pkgs.brightnessctl
      ];
      sessionVariables = {
        WLR_NO_HARDWARE_CURSORS = "1";
        # Hint electron apps to use wayland
        NIXOS_OZONE_WL = "1";
      };
    };

    services.displayManager.sessionPackages = [
      ((pkgs.writeTextDir "share/wayland-sessions/dwl.desktop" ''
        [Desktop Entry]
        Name=dwl
        Exec=dwl-run
        Type=Application
      '').overrideAttrs (_: { passthru.providedSessions = [ "dwl" ]; }))
    ];

    systemd.user.targets.dwl-session = {
      description = "dwl compositor session";
      documentation = [ "man:systemd.special(7)" ];
      bindsTo = [ "graphical-session.target" ];
      wants = [ "graphical-session-pre.target" ];
      after = [ "graphical-session-pre.target" ];
    };

    systemd.user.services.dwlb = {
      description = "Service to run the dwlb status bar";
      enable = true;
      serviceConfig = {
        ExecStart = with colorscheme.palette; ''
          ${lib.getExe dwlb} -ipc -font 'mono:size=10' \
            -inactive-bg-color '#${base00}' \
            -middle-bg-color '#${base00}' \
            -middle-bg-color-selected '#${base01}' \
            -active-bg-color '#${base01}' \
            -occupied-bg-color '#${base00}'
        '';
      };
      bindsTo = [ "dwl-session.target" ];
      wantedBy = [ "dwl-session.target" ];
      restartIfChanged = true;
    };

    systemd.user.services.status-bar = {
      description = "Service to run the status bar provider";
      enable = true;
      script = "${lib.getExe slstatus} -s | ${lib.getExe dwlb} -status-stdin all -ipc";
      bindsTo = [ "dwlb.service" ];
      wantedBy = [ "dwlb.service" ];
      reloadTriggers = [ dwlb slstatus ];
      restartTriggers = [ dwlb slstatus ];
    };

    systemd.user.services.wallpaper = {
      description = "Service to set the wallpapper";
      enable = true;
      serviceConfig = {
        ExecStart =
          let
            nix-colors-lib = nix-colors.lib.contrib { inherit pkgs; };
            wallpaper = nix-colors-lib.nixWallpaperFromScheme {
              scheme = colorscheme;
              width = 3840;
              height = 2160;
              logoScale = 4.0;
            };
          in
          ''
            ${lib.getExe pkgs.wbg} --stretch ${wallpaper}
          '';
      };
      bindsTo = [ "dwl-session.target" ];
      wantedBy = [ "dwl-session.target" ];
      restartIfChanged = true;
    };

    security = {
      polkit.enable = true;
    };

    programs = {
      dconf.enable = true;
      xwayland.enable = true;
    };

    services.graphical-desktop.enable = true;

    xdg.portal = {
      enable = true;
      config = {
        common = {
          default = "wlr";
        };
      };
      wlr = {
        enable = true;
        settings.screencast = {
          chooser_type = "simple";
          chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
        };
      };
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    home-manager.users.${mainUser} = {
      services.cliphist.enable = true;
    };

    # Window manager only sessions (unlike DEs) don't handle XDG
    # autostart files, so force them to run the service
    services.xserver.desktopManager.runXdgAutostartIfNone = true;
  };
}
