{ jetbrains }:

# Replaces the JetBrains Toolbox install of IntelliJ IDEA. What is left of
# MANUAL-POST-INSTALL.md step 5 is the plugins and the keymap.
#
# `vmopts` is an argument of the whole nixpkgs jetbrains scope; overriding it
# writes the options into the store and points IDEA_VM_OPTIONS at them. That
# is preferred over a ~/.config/JetBrains/IntelliJIdea<version>/idea64.vmoptions
# file, because the path there carries the release number and would have to be
# re-derived on every upgrade. The launcher reads the bundled options file as
# well, so the `-Djna.library.path` nixpkgs appends to it is kept.

jetbrains.idea-ultimate.override {
  vmopts = ''
    -Xmx4096m

    # Render through the native Wayland toolkit instead of XWayland - without
    # this the IDE is blurry on a scaled output and ignores sway's clipboard.
    -Dawt.toolkit.name=WLToolkit

    # Experimental JBR Vulkan 2D pipeline. Uncomment if scrolling is slow;
    # it is off by default because it still glitches on some drivers.
    # -Dsun.java2d.vulkan=true
  '';
}
