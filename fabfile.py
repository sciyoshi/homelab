#!/usr/bin/env python

import io
import json
import pathlib
import tarfile
import tempfile
from fabric import Connection, SerialGroup

hosts = {
    "alpha.sciyoshi.com": {
        "profile": "ovh",
        "hostname": "alpha",
        "bootDevice": "/dev/sda",
        "rootDevice": "/dev/sda1",
    },
    "beta.sciyoshi.com": {
        "profile": "ovh",
        "hostname": "beta",
        "bootDevice": "/dev/vda",
        "rootDevice": "/dev/vda1",
    },
}

group = SerialGroup(*hosts.keys())

for conn in group:
    host_config = hosts[conn.host]

    with tempfile.TemporaryFile() as tmp:
        with tarfile.open(fileobj=tmp, mode="w:gz") as tar:
            tar.add(pathlib.Path(__file__).with_name("nixos"), arcname=".")

        conn.put(tmp, "/tmp/nixos-configuration-tmp.tar.gz")
        conn.put(io.StringIO(json.dumps(host_config)), "/tmp/nixos-host-config.json")

    conn.sudo("tar -xzf /tmp/nixos-configuration-tmp.tar.gz -C /etc/nixos")
    conn.sudo("mv /tmp/nixos-host-config.json /etc/nixos/host-config.json")
    conn.sudo("nixos-rebuild switch")
