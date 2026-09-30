{ jetbrains }:

# Replaces the JetBrains Toolbox install of IntelliJ IDEA. What is left of
# MANUAL-POST-INSTALL.md step 5 is the plugins and the keymap.
#
# `jetbrains.idea` is the unified IDEA distribution; `idea-ultimate` and
# `idea-community` were removed in nixpkgs 26.05.
#
# `forceWayland` and `vmopts` are arguments of the whole nixpkgs jetbrains
# scope, and `callPackages` in all-packages.nix makes them reachable through
# `.override` on a single IDE.

jetbrains.idea.override {
  # Passes -Dawt.toolkit.name=WLToolkit whenever WAYLAND_DISPLAY is set, so
  # the IDE renders natively on sway instead of through XWayland. Doing it
  # this way rather than in vmopts below keeps the X11 path working.
  forceWayland = true;

  # Written to the store and pointed at by IDEA_VM_OPTIONS, which avoids a
  # ~/.config/JetBrains/IntelliJIdea<version>/idea64.vmoptions path that would
  # have to be re-derived on every upgrade. The launcher reads the bundled
  # options file as well, so what nixpkgs appends to it is kept.
  vmopts = ''
    -Xmx4096m

    # Experimental JBR Vulkan 2D pipeline. Uncomment if scrolling is slow;
    # it is off by default because it still glitches on some drivers.
    # -Dsun.java2d.vulkan=true
  '';
}
