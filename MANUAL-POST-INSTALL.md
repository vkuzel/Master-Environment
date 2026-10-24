# NixOS post-install steps

Most of what the Ubuntu version needed here is now declarative. What is left
is either data that cannot live in a public repository, or vendor software
that has to be configured through its own UI.

1. Set a real password

    ```shell
    passwd
    ```

    TODO Switch to `hashedPasswordFile` backed by [sops-nix](https://github.com/Mic92/sops-nix) and drop `initialPassword`.

2. Wi-Fi

    ```shell
    nmcli device wifi list
    nmcli device wifi connect <SSID> --ask
    ```

3. Printer & scanner

    Add the Brother DCP-L2532DW at <http://localhost:631/admin> - it is auto-discovered over mDNS. Scanning works through `simple-scan`.

    _If `brlaser` renders badly, replace it in `printing.nix` with the vendor driver package from nixpkgs (`cups-brother-*`)._

4. Twingate VPN

    The service is enabled; authenticate once:

    ```shell
    sudo twingate setup
    ```

5. IntelliJ IDEA setup

    Plugins:
    * [Tab Management Plugin](https://github.com/vkuzel/IntelliJ-Tab-Management)

    Settings:
    * Disable: Settings -> Editor -> General -> Smart Keys -> Markdown -> Adjust indentation on type
    * Select: Keymap -> Tab Management

   Toolbar:
   - Fetch
   - VCS ...
   - Update Project
   - Push...

6. Rhythmbox / iPod shuffle

    Connecting iPod:
    1. Open GTK file dialog: Rhythmbox -> Preferences -> Music -> Browse
    2. Open iPod

7. Copilot

    Disable terminal progress notifications by adding into `~/.copilot/settins.json`
    ```
    "terminalProgress": false
    ```

8. Firefox extensions

    * Disable passwords and payment methods save/autofill in settings.
