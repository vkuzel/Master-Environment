{ jetbrains }:

jetbrains.idea.override {
  forceWayland = true;

  vmopts = ''
    -Xmx4096m

    # Experimental JBR Vulkan 2D pipeline. Uncomment if scrolling is slow;
    # it is off by default because it still glitches on some drivers.
    # -Dsun.java2d.vulkan=true
  '';
}
