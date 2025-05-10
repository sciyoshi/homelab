{ pkgs, config, ... }:
{
  programs.eza.enable = true;
  programs.fzf.enable = true;
  programs.direnv.enable = true;

  # Shell aliases.
  home.shellAliases = {
    l = "${pkgs.eza}/bin/eza -l --group-directories-first";
    ls = "${pkgs.eza}/bin/eza -l --group-directories-first";
    la = "${pkgs.eza}/bin/eza -la --group-directories-first";
    dc = "docker compose";
    pc = "podman compose";
    k = "kubectl";
    # wget = "wget --hsts-file=\"${config.xdg.dataHome}/wget-hsts\"";
  };

  xdg.enable = true;

  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    history.path = "${config.xdg.stateHome}/zsh/history";
    sessionVariables = {
      PODMAN_COMPOSE_WARNING_LOGS = "false";

      CARGO_HOME = "${config.xdg.dataHome}/cargo";
      RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
      NODE_REPL_HISTORY = "${config.xdg.stateHome}/node_repl_history";
      MYSQL_HISTFILE = "${config.xdg.stateHome}/mysql_history";
      FLY_CONFIG_DIR = "${config.xdg.stateHome}/fly";
      # PSQL_HISTORY = "${config.xdg.dataHome}/psql_history";
      # GNUPGHOME = "${config.xdg.dataHome}/gnupg";

      # AWS_SHARED_CREDENTIALS_FILE = "${config.xdg.configHome}/aws/credentials";
      # AWS_CONFIG_FILE = "${config.xdg.configHome}/aws/config";
    };
    initContent = ''
      # compinit -d "$XDG_CACHE_HOME"/zsh/zcompdump-"$ZSH_VERSION"

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
      pathadd "$HOME/.local/share/cargo/bin"
      pathadd "/opt/homebrew/bin"

      for al in `git --list-cmds=alias`; do
        alias g$al="git $al"
      done
    '';
    profileExtra = ''
      # ZELLIJ_AUTO_EXIT=true eval "$(zellij setup --generate-auto-start zsh)"
    '';
  };

  programs.zellij = {
    enable = true;
  };
}
