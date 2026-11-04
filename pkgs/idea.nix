{ jetbrains }:

jetbrains.idea.override {
  # TODO Consider enabling Wayland with new IDEA when context menu placement is fixed
  forceWayland = false;

  vmopts = ''
    -Xmx4096m

    -Dsun.java2d.vulkan=true
  '';
}
