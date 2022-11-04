{ pkgs, ... }: {
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
}
