{ config, pkgs, lib, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "sciyoshi";

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

  home.shellAliases = {
    l = "${pkgs.exa}/bin/exa -l --group-directories-first";
    ls = "${pkgs.exa}/bin/exa -l --group-directories-first";
    la = "${pkgs.exa}/bin/exa -la --group-directories-first";
    dc = "docker compose";
    k = "kubectl";
  };

  programs.zsh = {
    enable = true;
    initExtra = ''
      # create a zkbd compatible hash;
      # to add other keys to this hash, see: man 5 terminfo
      typeset -g -A key

      key[Home]="''${terminfo[khome]}"
      key[End]="''${terminfo[kend]}"
      key[Insert]="''${terminfo[kich1]}"
      key[Backspace]="''${terminfo[kbs]}"
      key[Delete]="''${terminfo[kdch1]}"
      key[Up]="''${terminfo[kcuu1]}"
      key[Down]="''${terminfo[kcud1]}"
      key[Left]="''${terminfo[kcub1]}"
      key[Right]="''${terminfo[kcuf1]}"
      key[PageUp]="''${terminfo[kpp]}"
      key[PageDown]="''${terminfo[knp]}"
      key[Shift-Tab]="''${terminfo[kcbt]}"

      # setup key accordingly
      [[ -n "''${key[Home]}"      ]] && bindkey -- "''${key[Home]}"       beginning-of-line
      [[ -n "''${key[End]}"       ]] && bindkey -- "''${key[End]}"        end-of-line
      [[ -n "''${key[Insert]}"    ]] && bindkey -- "''${key[Insert]}"     overwrite-mode
      [[ -n "''${key[Backspace]}" ]] && bindkey -- "''${key[Backspace]}"  backward-delete-char
      [[ -n "''${key[Delete]}"    ]] && bindkey -- "''${key[Delete]}"     delete-char
      [[ -n "''${key[Up]}"        ]] && bindkey -- "''${key[Up]}"         up-line-or-history
      [[ -n "''${key[Down]}"      ]] && bindkey -- "''${key[Down]}"       down-line-or-history
      [[ -n "''${key[Left]}"      ]] && bindkey -- "''${key[Left]}"       backward-char
      [[ -n "''${key[Right]}"     ]] && bindkey -- "''${key[Right]}"      forward-char
      [[ -n "''${key[PageUp]}"    ]] && bindkey -- "''${key[PageUp]}"     beginning-of-buffer-or-history
      [[ -n "''${key[PageDown]}"  ]] && bindkey -- "''${key[PageDown]}"   end-of-buffer-or-history
      [[ -n "''${key[Shift-Tab]}" ]] && bindkey -- "''${key[Shift-Tab]}"  reverse-menu-complete

      # Finally, make sure the terminal is in application mode, when zle is
      # active. Only then are the values from $terminfo valid.
      if (( ''${+terminfo[smkx]} && ''${+terminfo[rmkx]} )); then
        autoload -Uz add-zle-hook-widget
        function zle_application_mode_start { echoti smkx }
        function zle_application_mode_stop { echoti rmkx }
        add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
        add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
      fi

      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word

      pathadd() {
        if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
         PATH="''${PATH:+"$PATH:"}$1"
        fi
      }

      pathadd "$HOME/.local/bin"
      pathadd "$HOME/.cargo/bin"
      pathadd "/opt/homebrew/bin"

      for al in `git --list-cmds=alias`; do
        alias g$al="git $al"
      done
    '';
    profileExtra = ''
      source "$HOME/.nix-profile/etc/profile.d/nix.sh"

      ZELLIJ_AUTO_EXIT=true eval "$(zellij setup --generate-auto-start zsh)"
    '';
  };

  programs.bash = {
    enable = true;
    bashrcExtra = ''
      pathadd() {
        if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
         PATH="''${PATH:+"$PATH:"}$1"
        fi
      }

      pathadd "$HOME/.local/bin"
      pathadd "$HOME/.cargo/bin"
      pathadd "/opt/homebrew/bin"
    '';
    initExtra = ''
      function_exists() {
        declare -f -F $1 > /dev/null
        return $?
      }

      source "${pkgs.git}/share/git/contrib/completion/git-completion.bash"

      for al in `git --list-cmds=alias`; do
        alias g$al="git $al"

        complete_func=_git_$(__git_aliased_command $al | tr '-' '_')
        function_exists $complete_fnc && __git_complete g$al $complete_func
      done
    '';
    profileExtra = ''
      source "$HOME/.nix-profile/etc/profile.d/nix.sh"

      ZELLIJ_AUTO_EXIT=true eval "$(zellij setup --generate-auto-start bash)"
    '';
  };

  programs.keychain = {
    enable = true;
    keys = [ "id_ed25519" ];
  };

  programs.git = {
    enable = true;
    userEmail = "samuel@cormier-iijima.com";
    userName = "Samuel Cormier-Iijima";
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
      merge = {
        conflictStyle = "diff3";
      };
      rebase = {
        autoStash = true;
      };
      core = {
        editor = "vim +startinsert!";
      };
    };
    aliases = {
      a = "add";
      b = "branch";
      bd = "branch -D";
      c = "commit --verbose";
      ca = "commit -a --verbose";
      cam = "commit -a --amend";
      cm = "commit --amend";
      co = "checkout";
      cp = "cherry-pick";
      d = "diff";
      dc = "diff --cached";
      ds = "diff --stat";
      f = "fetch --all --prune --tags";
      fp = "push --force";
      l = "pull --rebase";
      p = "push";
      po = "push origin";
      puo = "push --set-upstream origin";
      r = "reset";
      rb = "rebase";
      rbi = "rebase -i";
      rh = "reset --hard";
      s = "status";
      st = "stash";
      stp = "stash pop";
    };
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      add_newline = true;
      format = "$username$hostname$directory$all";
      directory = {
        truncation_length = 5;
        truncate_to_repo = false;
      };

      character = {
        success_symbol = "[λ](bold green)";
        error_symbol = "[✘](bold red)";
      };

      git_branch = {
        symbol = "🌱 ";
        format = "\\[[$symbol$branch]($style)\\]";
      };

      aws = {
        disabled = true;
      };

      kubernetes = {
        disabled = false;
        format = "\\[[$symbol$context( \($namespace\))]($style)\\]";
        symbol = "🧿";
        style = "bold yellow";
        context_aliases = {
          "arn:aws:eks:ca-central-1:326253947186:cluster/staging" = "staging";
          "arn:aws:eks:ca-central-1:326253947186:cluster/production" = "production";
        };
      };
    };
  };

  programs.exa.enable = true;
  programs.fzf.enable = true;
  programs.direnv.enable = true;

  programs.zellij = {
    enable = true;
    package = pkgs.zellij.overrideAttrs (drv: rec {
      pname = "zellij";
      version = "0.31.1";
      name = "zellij-0.31.1";

      src = pkgs.fetchFromGitHub {
        owner = "zellij-org";
        repo = "zellij";
        rev = "533a19c26bc150a53902e0b8b12b47175bd940e1";
        sha256 = "sha256-kwOpXfwJB9d7GQLgVflq3e2W88vtFYm3LWurw0K10o0=";
      };

      cargoDeps = drv.cargoDeps.overrideAttrs (lib.const {
        name = "${name}-vendor.tar.gz";
        inherit src;
        outputHash = "sha256-LzqTEDbVHxlYNGQ7nMFtNo1S3Uiw4bpKsQX/rtuFDQE=";
      });
    });
    settings = {
      default_shell = "zsh";
      keybinds = {
        normal = [{
          key = [{ F = 6; }];
          action = [{
            NewTab = {
              direction = "Horizontal";
              parts = [
                {
                  direction = "Vertical";
                  pane_name = "Django";
                  run = {
                    command = {
                      cmd = "zsh";
                      args = [ "-c" "cd ~/workspace/fellow/fellow/; direnv exec . ./manage.py runserver 0.0.0.0:8080; zsh -i" ];
                    };
                  };
                }
                {
                  direction = "Vertical";
                  parts = [
                    {
                      direction = "Horizontal";
                      pane_name = "Webpack";
                      run = {
                        command = {
                          cmd = "zsh";
                          args = [ "-c" "cd ~/workspace/fellow/fellow/web/; direnv exec .. npm run dev; zsh -i" ];
                        };
                      };
                    }
                    {
                      direction = "Horizontal";
                      pane_name = "Celery";
                      run = {
                        command = {
                          cmd = "zsh";
                          args = [ "-c" "cd ~/workspace/fellow/fellow/; direnv exec . celery -A server.fellow worker -Ofair --beat --loglevel=debug -Q background,search_notes,search_calendar,search,billing,integrations_google_calendar,integrations_google_sync,integrations_office365_calendar,integrations_office365_sync,integrations_asana,integrations_zapier,relationships,celery,realtime; zsh -i" ];
                        };
                      };
                    }
                  ];
                }
              ];
            };
          }];
        }];
      };
    };
  };

  programs.gitui.enable = true;

  home.packages = with pkgs; [
    ripgrep
    nodejs
    kubectl
    awscli2
    kubectx
    caddy
    tig
    rustup
    fastmod
    poetry
  ];

  home.file.".aws/config".text = ''
    [default]
    region = ca-central-1
  '';
}
