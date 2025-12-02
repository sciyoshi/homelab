{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        email = "samuel@cormier-iijima.com";
        name = "Samuel Cormier-Iijima";
      };
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
      alias = {
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
  };

  # programs.gitui.enable = true;
}
