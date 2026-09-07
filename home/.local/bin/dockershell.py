#!/usr/bin/env python3
import os
import subprocess
import tempfile

# language=shell
ZSHRC = """
source "$HOME/.config/zsh/.zshrc.key-bindings.zsh"
source "$HOME/.config/zsh/.zshrc.aliases.zsh"

PROMPT='[%F{red}docker%f]%F{green}%n@%m%f:%F{yellow}%~%f %# '
"""


def main():
    with tempfile.TemporaryDirectory(prefix="dockershell-") as tmp_dir:
        with open(os.path.join(tmp_dir, ".zshrc"), "w") as zshrc:
            zshrc.write(ZSHRC)

        groups = [str(gid) for gid in os.getgroups()]
        docker_gid = subprocess.run(
            ["getent", "group", "docker"],
            capture_output=True,
            text=True,
        ).stdout.strip().split(":")[2]
        groups.append(docker_gid)

        subprocess.run([
            "sudo", "--preserve-env",
            f"ZDOTDIR={tmp_dir}",
            "setpriv",
            "--reuid", str(os.getuid()),
            "--regid", str(os.getgid()),
            "--groups", ",".join(groups),
            "zsh", "-i",
        ])


if __name__ == "__main__":
    main()
