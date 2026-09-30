# NixOS post-install steps

Most of what the Ubuntu version needed here is now declarative. What is left
is either data that cannot live in a public repository, or vendor software
that has to be configured through its own UI.

1. Set a real password

    `users.mutableUsers = false` plus `initialPassword` in `flake.nix` is a
    bootstrap convenience only.

    ```shell
    passwd
    ```

    Better: switch to `hashedPasswordFile` backed by
    [sops-nix](https://github.com/Mic92/sops-nix) and drop `initialPassword`.

2. Wi-Fi

    ```shell
    nmcli device wifi list
    nmcli device wifi connect <SSID> --ask
    ```

    (`nmcli-device-wifi-list` is installed as a helper.)

3. Printer & scanner

    CUPS, Avahi, `brlaser` and SANE are enabled by `modules/nixos/printing.nix`.
    Add the Brother DCP-L2532DW at <http://localhost:631/admin> - it is
    auto-discovered over mDNS. Scanning works through `simple-scan`.

    If `brlaser` renders badly, replace it in `printing.nix` with the vendor
    driver package from nixpkgs (`cups-brother-*`).

4. Twingate VPN

    The service is enabled; authenticate once:

    ```shell
    sudo twingate setup
    ```

5. IntelliJ IDEA setup

    The IDE itself is installed by `modules/home/editor.nix`
    (`pkgs/idea.nix` adds the vmoptions). What is left is per-profile state
    that lives in the JetBrains account / UI:

    Plugins:
    * [Tab Management Plugin](https://github.com/vkuzel/IntelliJ-Tab-Management)

    Settings:
    * Disable: Settings -> Editor -> General -> Smart Keys -> Markdown ->
      Adjust indentation on type
    * Select: Keymap -> Tab Management

6. Rhythmbox / iPod shuffle

    1. Open GTK file dialog: Rhythmbox -> Preferences -> Music -> Browse
    2. Open iPod

7. Copilot

    Terminal progress notifications are a runtime setting, add into
    `~/.copilot/settings.json`:

    ```json
    "terminalProgress": false
    ```

8. Firefox extensions

    Startpage, uBlock Origin and Unhook are installed by policy
    (`modules/home/desktop-apps.nix`); they only need to be enabled once in
    `about:addons`.
