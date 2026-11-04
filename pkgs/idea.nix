{ jetbrains }:

jetbrains.idea.override {
  forceWayland = true;

  vmopts = ''
    -Xmx4096m

    -Dawt.toolkit.name=WLToolkit
    -Dsun.java2d.vulkan=true
  '';
}
