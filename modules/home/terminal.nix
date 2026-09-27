{ ... }:

# Replaces home/.config/foot/foot.ini. The `monospace` alias resolves to the
# Nerd Font configured in modules/nixos/fonts.nix.

{
  programs.foot = {
    enable = true;
    settings.main = {
      font = "monospace:style=Regular:size=10";
      font-bold = "monospace:style=Bold:size=10";
      font-italic = "monospace:style=Oblique:size=10";
      font-bold-italic = "monospace:style=Bold Oblique:size=10";
    };
  };
}
