#!/usr/bin/env python3

import grp
import os
import re
import subprocess
import sys
import tempfile
import textwrap
from contextlib import contextmanager
from importlib import metadata


class CopilotRunner:

    def run(self):
        cwd = os.getcwd()

        if self._is_git_repository(cwd) or self._is_ai_slop_project(cwd):
            read_write = True
        elif self._ask_yn_question(f"Run read-only Copilot in {cwd} (N for exit)"):
            read_write = False
        else:
            return

        available_python_packages = ",".join(
            name for dist in metadata.distributions()
            if (name := dist.metadata.get('Name'))
        )
        instructions = textwrap.dedent(f"""
        - Assume Ubuntu 24.04 environment.
        - Do not install new software via APT or PIP or any other way.
        - Do not commit changes.
        - These Python packages are installed: {available_python_packages}
        """)

        with self._create_instructions_file(instructions) as instructions_file:
            home = os.path.expanduser("~")
            nvm_dir = os.path.join(home, ".nvm")
            copilot_dir = os.path.join(home, ".copilot")
            copilot_cache_dir = os.path.join(home, ".cache/copilot")
            microsoft_dev_tools_dir = os.path.join(home, ".cache/Microsoft/DeveloperTools")
            env = os.environ.copy()

            os.makedirs(copilot_cache_dir, exist_ok=True)
            os.makedirs(microsoft_dev_tools_dir, exist_ok=True)

            args = [
                "bwrap",
                # reset environment
                "--unshare-all",
                "--share-net",
                "--die-with-parent",

                # basic system
                "--dev", "/dev",
                "--proc", "/proc",
                "--tmpfs", "/tmp",
                "--ro-bind", "/run", "/run",
                "--ro-bind", "/etc", "/etc",
                "--ro-bind", "/usr", "/usr",
                "--ro-bind", "/bin", "/bin",
                "--ro-bind", "/lib", "/lib",
                "--ro-bind", "/lib64", "/lib64",

                # environment
                "--uid", str(os.getuid()),
                "--gid", str(grp.getgrgid(os.getgid()).gr_gid),

                "--clearenv",
                "--setenv", "HOME", home,
                "--setenv", "PATH", env.get("PATH", ""),
                "--setenv", "NVM_DIR", nvm_dir,
                "--setenv", "TERM", env.get("TERM", ""),
                "--setenv", "COLORTERM", env.get("COLORTERM", ""),

                "--ro-bind", nvm_dir, nvm_dir,
                "--bind", copilot_dir, copilot_dir,
                "--bind", copilot_cache_dir, copilot_cache_dir,
                "--bind", microsoft_dev_tools_dir, microsoft_dev_tools_dir,

                # instructions: https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions
                "--setenv", "COPILOT_CUSTOM_INSTRUCTIONS_DIRS", "/tmp/instructions",
                "--ro-bind", instructions_file.name, "/tmp/instructions/.github/instructions/custom.instructions.md",

                # workspace
                "--bind" if read_write else "--ro-bind", cwd, cwd,

                "/bin/bash", "-ec",
                # language=bash
                """
                source "$NVM_DIR/nvm.sh" --no-use
                nvm use default
                
                copilot
                """
            ]

            result = subprocess.run(args)
            sys.exit(result.returncode)

    @staticmethod
    def _is_git_repository(directory: str) -> bool:
        try:
            subprocess.run(
                ["git", "-C", directory, "rev-parse", "--is-inside-work-tree"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=True,
            )
            return True
        except subprocess.CalledProcessError:
            return False

    @staticmethod
    def _is_ai_slop_project(directory: str) -> bool:
        home = re.escape(os.path.expanduser("~"))
        slop_dir_pattern = fr"^{home}/slop/[^/]+"
        return bool(re.match(slop_dir_pattern, directory))

    @staticmethod
    def _ask_yn_question(msg: str) -> bool:
        try:
            answer = input(f"{msg} [y/N] ")
        except EOFError:
            answer = ""
        return answer.strip().lower() == "y"

    @staticmethod
    @contextmanager
    def _create_instructions_file(instructions: str):
        with tempfile.NamedTemporaryFile(
                prefix="copilot-instructions-",
                suffix=".md",
                mode="w+",
        ) as instructions_file:
            instructions_file.write(instructions)
            instructions_file.flush()
            yield instructions_file


def main():
    CopilotRunner().run()


if __name__ == "__main__":
    main()
