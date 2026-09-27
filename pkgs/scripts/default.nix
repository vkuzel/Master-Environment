{ lib
, stdenvNoCC
, makeWrapper
, python3
, bash
, gobject-introspection
, glib
, gst_all_1
, pipewire
  # runtime dependencies of the individual scripts
, coreutils
, findutils
, gawk
, gnugrep
, gnused
, procps
, util-linux
, sudo
, rsync
, jq
, sway
, swayidle
, swaylock
, slurp
, grim
, libnotify
, foot
, micro
, networkmanager
, go-mtpfs
, usbutils
, veracrypt
, fuse
, bubblewrap
, git
, zsh
, glibc
, github-copilot-cli
, gtk3
}:

# Every helper from the original `home/.local/bin` and `home/.config/sway`
# becomes a real package with *declared* runtime dependencies, instead of a
# symlink that silently breaks when an apt package is missing.
#
# The sources are kept verbatim in ./src so they stay easy to diff against the
# Ubuntu version; only the interpreter and PATH are injected at build time.

let
  pythonEnv = python3.withPackages (ps: with ps; [
    pillow
    pygobject3
    pyyaml
    tkinter
  ]);

  # Builds one script into $out/bin/<name>, rewriting the shebang to a store
  # path and wrapping it with an explicit PATH (and GI typelibs when needed).
  mkScript =
    { name
    , src
    , interpreter
    , runtimeInputs ? [ ]
    , needsGi ? false
    , gstPlugins ? [ ]
    }:
    stdenvNoCC.mkDerivation {
      inherit name src;
      dontUnpack = true;
      nativeBuildInputs = [ makeWrapper ];

      installPhase = ''
        runHook preInstall

        mkdir -p $out/bin
        {
          echo "#!${interpreter}"
          tail -n +2 $src
        } > $out/bin/${name}
        chmod +x $out/bin/${name}

        wrapProgram $out/bin/${name} \
          --prefix PATH : ${lib.makeBinPath runtimeInputs} \
          ${lib.optionalString needsGi
            "--prefix GI_TYPELIB_PATH : ${lib.makeSearchPath "lib/girepository-1.0" [
              gobject-introspection glib gst_all_1.gstreamer gst_all_1.gst-plugins-base
            ]}"} \
          ${lib.optionalString (gstPlugins != [ ])
            "--prefix GST_PLUGIN_SYSTEM_PATH_1_0 : ${lib.makeSearchPath "lib/gstreamer-1.0" gstPlugins}"}

        runHook postInstall
      '';

      meta = {
        description = "Master Environment helper script: ${name}";
        mainProgram = name;
        platforms = lib.platforms.linux;
      };
    };

  py = "${pythonEnv}/bin/python3";
  sh = "${bash}/bin/bash";

  scripts = {
    backup = mkScript {
      name = "backup";
      src = ./src/backup.sh;
      interpreter = sh;
      runtimeInputs = [ rsync coreutils findutils gnugrep ];
    };

    backup-phone = mkScript {
      name = "backup-phone";
      src = ./src/backup-phone.sh;
      interpreter = sh;
      runtimeInputs = [ rsync coreutils gnugrep ];
    };

    blank-box = mkScript {
      name = "blank-box";
      src = ./src/blank-box.py;
      interpreter = py;
    };

    copilotw = mkScript {
      name = "copilotw";
      src = ./src/copilotw.py;
      interpreter = py;
      runtimeInputs = [ bubblewrap git github-copilot-cli coreutils ];
    };

    dirty-writeback = mkScript {
      name = "dirty-writeback";
      src = ./src/dirty-writeback.sh;
      interpreter = sh;
      runtimeInputs = [ procps gnugrep ];
    };

    dockershell = mkScript {
      name = "dockershell";
      src = ./src/dockershell.py;
      interpreter = py;
      runtimeInputs = [ sudo util-linux zsh glibc ];
    };

    java-home = mkScript {
      name = "java-home";
      src = ./src/java-home.sh;
      interpreter = sh;
      runtimeInputs = [ coreutils gnugrep gnused ];
    };

    kill-app = mkScript {
      name = "kill-app";
      src = ./src/kill.sh;
      interpreter = sh;
      runtimeInputs = [ procps gnugrep gawk findutils coreutils ];
    };

    microgui = mkScript {
      name = "microgui";
      src = ./src/microgui.sh;
      interpreter = sh;
      runtimeInputs = [ foot micro util-linux ];
    };

    mountui = mkScript {
      name = "mountui";
      src = ./src/mountui.py;
      interpreter = py;
      runtimeInputs = [ sudo util-linux fuse go-mtpfs usbutils veracrypt coreutils ];
    };

    nmcli-device-wifi-list = mkScript {
      name = "nmcli-device-wifi-list";
      src = ./src/nmcli-device-wifi-list.sh;
      interpreter = sh;
      runtimeInputs = [ networkmanager ];
    };

    preview = mkScript {
      name = "preview";
      src = ./src/preview.py;
      interpreter = py;
    };

    screencast-test = mkScript {
      name = "screencast-test";
      src = ./src/screencast-test.py;
      interpreter = py;
      needsGi = true;
      # `--play` renders the captured stream with `gst-launch-1.0 pipewiresrc`.
      runtimeInputs = [ gst_all_1.gstreamer ];
      gstPlugins = [
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-bad
        pipewire
      ];
    };

    start-apps = mkScript {
      name = "start-apps";
      src = ./src/start-apps.py;
      interpreter = py;
      runtimeInputs = [ sway gtk3 coreutils ];
    };

    sway-lock = mkScript {
      name = "sway-lock";
      src = ./src/lock.py;
      interpreter = py;
      runtimeInputs = [ swaylock swayidle sway procps ];
    };

    sway-rearrange-workspaces = mkScript {
      name = "sway-rearrange-workspaces";
      src = ./src/rearrange-workspaces.sh;
      interpreter = sh;
      runtimeInputs = [ sway jq gnugrep gawk coreutils ];
    };

    sway-screenshot = mkScript {
      name = "sway-screenshot";
      src = ./src/screenshot.sh;
      interpreter = sh;
      runtimeInputs = [ sway jq slurp grim libnotify gnused coreutils ];
    };
  };
in
scripts // {
  # Convenience bundle: `environment.systemPackages = [ pkgs.master-environment-scripts ]`
  all = stdenvNoCC.mkDerivation {
    name = "master-environment-scripts";
    dontUnpack = true;
    nativeBuildInputs = [ ];
    buildCommand = ''
      mkdir -p $out/bin
      for drv in ${lib.concatStringsSep " " (lib.attrValues scripts)}; do
        for f in "$drv"/bin/*; do
          ln -s "$f" "$out/bin/$(basename "$f")"
        done
      done
    '';
  };
}
