{ pkgs, config, lib, ... }: {
  services.borgbackup.repos.backup = {
    path = lib.mkDefault "/var/lib/borg/backup";
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHL7BldB6Jcn62oT3jXwfbWLJQuFn4IJN5JapbfrPYax sciyoshi@scilo"
    ];
  };
}
