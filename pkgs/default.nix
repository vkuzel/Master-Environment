final: prev:

{
  masterEnvironmentScripts = final.callPackage ./scripts { };

  master-environment-scripts = final.masterEnvironmentScripts.all;

  github-copilot-cli = prev.callPackage ./copilot.nix {
    inherit (prev) github-copilot-cli;
  };

  # Rhythmbox finds the iPod through GIO's volume monitor, which lives in gvfs.
  # Wrapping only this one binary keeps the GIO backends out of every other
  # GTK app, unlike `services.gvfs`, which exports them session-wide.
  rhythmbox = prev.rhythmbox.overrideAttrs (old: {
    preFixup = (old.preFixup or "") + ''
      gappsWrapperArgs+=(--prefix GIO_EXTRA_MODULES : "${final.gvfs}/lib/gio/modules")
    '';
  });

  micro-filemanager-plugin = prev.callPackage ./micro-filemanager-plugin.nix { };

  # IntelliJ IDEA with the vmoptions and Wayland flag this environment needs.
  intellij-idea = final.callPackage ./idea.nix { };
}
