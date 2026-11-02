lib:

{
  overlays = [ (import ./default.nix) ];

  config.allowUnfreePredicate =
    pkg: builtins.elem (lib.getName pkg) [
      "github-copilot-cli"
      "google-chrome"
      "idea"
      "twingate"
      "veracrypt"
    ];
}
