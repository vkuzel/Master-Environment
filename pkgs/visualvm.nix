{ visualvm, makeWrapper }:

visualvm.overrideAttrs (old: {
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ makeWrapper ];

  postFixup = (old.postFixup or "") + ''
    wrapProgram $out/bin/visualvm --set _JAVA_AWT_WM_NONREPARENTING 1
  '';
})
