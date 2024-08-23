# TODO: separate linux and darwin stuff
{ config, pkgs, nix-index-database, android-nixpkgs, ... }:

let
  customScriptsDir = ".local/bin";
  globalNodePackagesDir = ".local/share/node_packages";
in
{
  imports = [
    ./modules/editors/neovim.nix
    ./modules/alacritty
    ./modules/home/version-control.nix
    nix-index-database.hmModules.nix-index
    android-nixpkgs.hmModule
  ];

  dconf.settings = {
    "org/gnome/desktop/background" = {
      picture-uri-dark = "file://${pkgs.nixos-artwork.wallpapers.nineish-dark-gray.src}";
    };
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  debling.editors.neovim.enable = true;

  debling.alacritty.enable = true;

  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    age.keyFile = "${config.home.homeDirectory}/.age-key";
  };

  services =
    let
      shouldEnable = pkgs.stdenv.isLinux;
    in
    {
      mako.enable = shouldEnable;

      blueman-applet.enable = shouldEnable;

      network-manager-applet.enable = shouldEnable;

      mpris-proxy.enable = shouldEnable;
    };

  # wayland.windowManager.hyprland = {
  #   enable = pkgs.stdenv.isLinux;
  #   extraConfig = builtins.readFile ./config/hyprland/hyprland.conf;
  #   settings = {
  #     general = {
  #       layout = "dwindle";
  #     };
  #     dwindle = {
  #       no_gaps_when_only = 1;
  #     };
  #
  #     input = {
  #       kb_options = "caps:swapescape";
  #       kb_layout = "br";
  #       kb_variant = "thinkpad";
  #
  #       follow_mouse = 1;
  #
  #       touchpad = {
  #         natural_scroll = true;
  #       };
  #     };
  #     "$mod" = "SUPER";
  #     misc = {
  #       force_default_wallpaper = 1;
  #     };
  #     # exec-once = ''
  #     #   ${pkgs.waybar}/bin/waybar &
  #     # '';
  #   };
  # };

  news.display = "show";

  nix = {
    checkConfig = true;
    settings = {
      experimental-features = "nix-command flakes";
      # extra-platforms = "x86_64-darwin aarch64-darwin";
    };
  };

  android-sdk = {
    enable = true;

    path = "${config.home.homeDirectory}/SDKs/android";

    packages = sdk: with sdk; [
      build-tools-34-0-0
      cmdline-tools-latest
      emulator
      platforms-android-34
      platform-tools
      sources-android-34
      # ndk-23-1-7779620
    ];
  };

  home = {
    enableNixpkgsReleaseCheck = true;

    packages = with pkgs;
      let
        linuxPkgs = [
          rofi-wayland
          kdePackages.dolphin
          wofi
          sops
          pavucontrol
        ];
        macosPkgs = [
          m-cli # useful macOS CLI commands 
        ];
      in
      [
        jetbrains.idea-ultimate
        babashka
        gh

        gnumake
        snitch
        maven

        ### Editors/IDEs
        # jetbrains.datagrip
        # jetbrains.idea-ultimate
        visualvm

        ### Langs related
        # idris2 # A language with dependent types, XXX: compilation is broken on m1 for now https://github.com/NixOS/nixpkgs/issues/151223
        # ansible
        clojure # Lisp language with sane concurrency
        cargo
        nodejs
        nodePackages.pnpm
        pipenv

        (python311.withPackages (ps: with ps; [
          pandas
          numpy
          ipython
          matplotlib
          seaborn
          jupyterlab
          pudb
          # torch
          scikit-learn
        ]))
        poetry

        ### CLI utils
        pinentry-tty
        # bitwarden-cli
        rbw ## a usable bitwarden cli
        awscli2
        cloc
        coreutils
        entr # Run commands when files change
        graphviz
        jq
        texlive.combined.scheme-basic
        pandoc
        python310Packages.editorconfig
        rlwrap # Utility to have Readline features, like scrollback in REPLs that don`t use the lib
        silver-searcher # A faster and more convenient grep. Executable is called `ag`
        terraform
        tree

        hledger
        hledger-ui
        hledger-web
        hledger-interest

        cachix

        # required by telescope.nvim  
        ripgrep
        fd

        wget
        unrar
        postgresql_15

        renameutils # adds qmv, and qmc utils for bulk move and copy

        taskwarrior-tui
        timewarrior

        # vagrant
        ouch # Painless compression and decompression for your terminal https://github.com/ouch-org/ouch
        # https://github.com/mic92/nix-update
        nurl # https://github.com/nix-community/nurl
        nix-init # https://github.com/nix-community/nix-init
        oha # HTTP load generator https://github.com/hatoo/oha

        trivy
        cht-sh # https://github.com/chubin/cheat.sh
        # nix-du

        # https://magic-wormhole.readthedocs.io/en/latest/welcome.html#example
        # magic-wormhole # Send files over the network

        glow
      ] ++ lib.optionals stdenv.isDarwin macosPkgs
      ++ lib.optionals stdenv.isLinux linuxPkgs;

    shellAliases = {
      g = "git";
      e = "emacs -nw";
      v = "vi";
      ni = "nix profile install";
      ns = "nix-shell --pure";
      nsp = "nix-shell -p";
    };

    sessionPath = [
      "$HOME/${customScriptsDir}"
      "$HOME/${globalNodePackagesDir}/bin"
    ];

    sessionVariables = {
      GRAALVM_HOME = pkgs.graalvm-ce.home;

      # Neeed on darwin bcs sops looks by default on
      # $HOME/Library/Application Support/sops/age/keys.txt
      SOPS_AGE_KEY_FILE = config.sops.age.keyFile;
    };

    file = {
      "${config.programs.taskwarrior.dataLocation}/hooks/on-modify.timewarrior" = {
        executable = true;
        source = "${pkgs.timewarrior.out}/share/doc/timew/ext/on-modify.timewarrior";
      };

      ${customScriptsDir} = {
        source = ./scripts;
        recursive = true;
      };

      ".npmrc".text = ''
        prefix=~/${globalNodePackagesDir}
        global-bin-dir=~/${globalNodePackagesDir}
      '';

      ".ideavimrc".source = ./config/.ideavimrc;

      # Stable SDK symlinks
      "SDKs/Java/current".source = pkgs.jdk;
      "SDKs/Java/22".source = pkgs.jdk22;
      "SDKs/Java/11".source = pkgs.jdk11;
      "SDKs/Java/8".source = pkgs.jdk8;
      # "SDKs/graalvm".source = pkgs.graalvm-ce.home;
    };

  };

  xdg.configFile = {
    snitch = {
      source = ./config/snitch;
      recursive = true;
    };
  };

  programs = {

    zoxide.enable = true;

    dircolors.enable = true;

    nix-index-database.comma.enable = true;

    nix-index.enable = true;

    vscode = {
      enable = true;
      enableUpdateCheck = false;
      mutableExtensionsDir = true;
      userSettings = {
        "files.autoSave" = "afterDelay";
        "vim.enableNeovim" = true;
        "editor.fontFamily" = "'JetBrains Mono', Menlo, Monaco, 'Courier New', monospace";
        "editor.fontSize" = 14;
        "editor.fontLigatures" = true;
        "workbench.colorTheme" = "Solarized Light";
        "vim.easymotion" = true;
        "vim.incsearch" = true;
        "vim.useSystemClipboard" = true;
        "vim.useCtrlKeys" = true;
        "vim.hlsearch" = true;
        "vim.leader" = "<space>";
        "extensions.experimental.affinity" = {
          "vscodevim.vim" = 1;
        };
        "zig.path" = "zig";
        "zig.zls.path" = "zig";
      };
    };

    htop.enable = true;

    taskwarrior = {
      enable = true;
      colorTheme = "dark-16";
      package = pkgs.taskwarrior3; 
    };

    # Used to have custom environment per project.
    # Very useful  to automaticly activate nix-shell when cd'ing to a
    # project folder.
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # A modern replacement for ls.
    eza = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      git = true;
    };

    # A modern replacement for cat, with sintax hilghting
    bat = {
      enable = true;
      config = {
        theme = "base16-256";
      };
    };

    # Terminal fuzzy finder
    fzf = {
      enable = true;
      enableZshIntegration = true;
      changeDirWidgetOptions = [ "--preview 'tree -C {} | head -n 100'" ];
      fileWidgetCommand = "fd --type f --hidden --strip-cwd-prefix --exclude .git";
      fileWidgetOptions = [ "--preview 'bat --color=always --style=numbers --line-range :100 {}'" ];
    };

    java.enable = true;

    # JSON query tool, but its mainly used for pretty-printing
    jq.enable = true;

    ssh = {
      enable = true;
      compression = true;
      controlMaster = "auto";
      controlPersist = "15m";
      matchBlocks = {
        "cvm1" = {
          hostname = "rabapp.cvm.ncsu.edu";
          user = "debling";
        };

        "cvm2" = {
          hostname = "rabapp-test.cvm.ncsu.edu";
          user = "debling";
        };

        "pdsa.aws" = {
          hostname = "ec2-54-232-138-185.sa-east-1.compute.amazonaws.com";
          user = "centos";
          identityFile = "~/.ssh/identities/pdsa-aws.pem";
        };

        "pdsa.review" = {
          hostname = "200.18.45.230";
          user = "admin";
          port = 222;
        };

        "pdsa.dev" = {
          hostname = "200.18.45.231";
          user = "admin";
          port = 222;
        };

        "pdsa.xen" = {
          hostname = "200.18.45.229";
          user = "admin";
        };

        "zeit-ryzen" = {
          hostname = "10.0.0.44";
          user = "debling";
          port = 443;
        };
      };
    };

    gpg.enable = true;

    # The true OS
    emacs = {
      enable = true;
      package = if pkgs.stdenv.isDarwin then pkgs.emacs-macport else pkgs.emacs;
    };

    zsh = {
      enable = true;
      defaultKeymap = "emacs";
      autosuggestion = {
        enable = true;
      };
      enableCompletion = true;
      syntaxHighlighting = {
        enable = true;
      };
      enableVteIntegration = true;
      autocd = true;
      history.size = 100000;
      localVariables = {
        TYPEWRITTEN_ARROW_SYMBOL = "➜";
        TYPEWRITTEN_RELATIVE_PATH = "adaptive";
        TYPEWRITTEN_SYMBOL = "$";
      };
      plugins = [
        {
          name = "typewritten";
          src = pkgs.fetchFromGitHub {
            owner = "reobin";
            repo = "typewritten";
            rev = "v1.5.1";
            sha256 = "07zk6lvdwy9n0nlvg9z9h941ijqhc5vvfpbr98g8p95gp4hvh85a";
          };
        }
        # build is currently failing on nixpkgs-unstable
        { name = "fzf-tab"; src = "${pkgs.zsh-fzf-tab}/share/fzf-tab"; }
      ];
      initExtraBeforeCompInit = ''
        if type brew &>/dev/null
        then
            fpath+="$(brew --prefix)/share/zsh/site-functions"
        fi
      '';
      initExtra = ''
        # Enable editing of the command line in an editor with Ctrl-X Ctrl-E
        autoload -z edit-command-line
        zle -N edit-command-line
        bindkey "^X^E" edit-command-line

        # load module for list-style selection
        # zmodload zsh/complist

        # use the module above for autocomplete selection
        # zstyle ':completion:*' menu yes select

        # now we can define keybindings for complist module
        # you want to trigger search on autocomplete items
        # so we'll bind some key to trigger history-incremental-search-forward function
        # bindkey -M menuselect '?' history-incremental-search-forward

        #### zfzf-tab config
        # disable sort when completing `git checkout`
        zstyle ':completion:*:git-checkout:*' sort false
        # set descriptions format to enable group support
        zstyle ':completion:*:descriptions' format '[%d]'
        # set list-colors to enable filename colorizing
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        # preview directory's content with exa when completing cd
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
        # switch group using `,` and `.`
        zstyle ':fzf-tab:*' switch-group ',' '.'
      '';
    };

    tmux = {
      enable = true;
      escapeTime = 0;
      historyLimit = 10000;
      terminal = "alacritty";
      extraConfig = ''
        # Terminal config for TrueColor support
        # set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'  # colored underscores
        set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'  # undercurl support
        set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'  # underscore colours - needs tmux-3.0
        set -as terminal-overrides ",*:RGB"  # true-color support


        set -g focus-events on

        set -g mouse on

        set -g set-titles on
        set -g set-titles-string "#S / #W"

        set -g status-style "none,bg=default"
        set -g status-justify centre
        set -g status-bg colour8
        set -g status-fg colour15
        set -g status-left-length 25
        set -g status-right '%d/%m %H:%M'

        setw -g window-status-current-format '#[bold]#I:#W#[fg=colour5]#F'
        setw -g window-status-format '#[fg=colour7]#I:#W#F'

        # Open new splits in the same directory as the current pane
        bind  %  split-window -h -c "#{pane_current_path}"
        bind '"' split-window -v -c "#{pane_current_path}"

        bind-key -r f run-shell "tmux neww tmux-sessionizer"
      '';
    };
  };


  ####
  #### The section bellow is auto-generated by home-manager
  ####

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "debling";
  # home.homeDirectory = pkgs.lib.mkForce "/home/debling";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
