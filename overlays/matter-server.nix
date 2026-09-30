_: prev: {
  python-matter-server = prev.python-matter-server.overrideAttrs (old: {
    # Cryptography 50 rejects an NXP DCL certificate that older versions warned
    # about. Skip malformed roots so one vendor cannot prevent server startup.
    # Device attestation still uses the remaining, successfully parsed roots.
    patches = (old.patches or [ ]) ++ [ ./matter-server-invalid-paa.patch ];
  });
}
