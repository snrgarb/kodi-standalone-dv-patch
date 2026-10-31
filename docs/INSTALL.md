# Install and test on CachyOS

Tested on CachyOS (Desktop edition) with Plasma Bigscreen and an AMD Radeon RX 9070 XT.

## Install

1. Copy the `out/` directory to the TV computer.
2. Verify the files and install the packages:

   ```sh
   cd out
   sha256sum -c SHA256SUMS                # each line must show OK
   sudo pacman -U ./*.pkg.tar.zst
   ```

   Do not use a glob that includes a package two times. pacman then shows `duplicate target`.

3. Add your user to these groups. Kodi opens the DRM and input devices directly.

   ```sh
   sudo usermod -aG video,render,input,audio "$USER"
   ```

4. Keep the stock `linux-cachyos` installed. The CB1 kernel gets its own boot entry.
5. Restart the computer. Select the `linux-cachyos-cb1` boot entry.
6. Make sure that the CB1 kernel runs:

   ```sh
   uname -r                                 # expect ...-cachyos-cb1
   journalctl -k -b | grep -i dvbridge      # expect family_supported=1 on the HDMI connector
   ```

Secure Boot: the CB1 kernel has no signature. Sign it with your own key (for example, with
`sbctl`), or disable Secure Boot.

## Use

In Plasma Bigscreen, open **Kodi (Dolby Vision)**.

- Kodi starts on tty7 in its own login session. It controls the display directly.
- Plasma continues to run on its own VT.
- When you exit Kodi, the display goes back to Plasma.

To start Kodi from a terminal: `systemctl start kodi-cb1@$USER.service`

Logs: `journalctl -u kodi-cb1@$USER` and `~/.kodi/temp/kodi.log`.

Kodi uses `~/.kodi`. If you also use the CachyOS Kodi, the two share this directory.

If the display does not go back to Plasma, push Ctrl+Alt+F1 or Ctrl+Alt+F2.
Or connect with SSH and run `sudo systemctl stop kodi-cb1@<user>.service`.

## Test

1. Make sure that the kernel log shows `family_supported=1`.
2. Start Kodi. Make sure that `kodi.log` shows `dv_property=present`.
3. Play a Profile 8.1 file with **DV Standard**. Make sure that:
   - the TV shows the Dolby Vision badge,
   - the colours are correct,
   - `kodi.log` shows `output admission: ... effective=Dolby Vision`.
4. Play a Profile 7 FEL file with **DV Master Reference**. Do the same checks.

## Differences from LibreELEC

- The kernel is 7.2.8, not 7.2.6. CachyOS adds HDMI VRR, ALLM and DSC backports.
  Patch 9927 keeps the Dolby VSIF as the only vendor infoframe while DV is on.
- There is no AirTunes, because Arch does not have libshairplay.
- Binary add-ons from the Arch `kodi` package (inputstream, PVR) do not load.
  They are for a different Kodi version.

## Remove

```sh
sudo pacman -R kodi-cb1 cb1-ffmpeg cb1-libplacebo cb1-libdisplay-info cb1-lightgbm \
  linux-cachyos-cb1 linux-cachyos-cb1-headers
```
