{ visualvm, makeWrapper }:

visualvm.overrideAttrs (old: {
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ makeWrapper ];

  postInstall = (old.postInstall or "") + ''
    wrapProgram $out/bin/visualvm --set _JAVA_AWT_WM_NONREPARENTING 1
  '';
})
