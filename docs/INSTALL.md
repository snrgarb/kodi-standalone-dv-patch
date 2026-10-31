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

## Audio

Use ALSA for HDMI audio. PulseAudio (PipeWire) passes through only AC3, E-AC3 and DTS core,
and it adds 250-500 ms of audio delay. ALSA passes through all formats, with no extra delay.

1. Let the Kodi service use ALSA and PulseAudio:

   ```sh
   sudo mkdir -p /etc/systemd/system/kodi-cb1@.service.d
   printf '[Service]\nEnvironment=KODI_AE_SINK=ALSA+PULSE\n' | sudo tee /etc/systemd/system/kodi-cb1@.service.d/audio.conf
   sudo systemctl daemon-reload
   ```

2. Set the PipeWire HDMI profile to 7.1. Then PCM audio in Plasma is not limited to stereo.
   Find the card with `pactl list cards short` and the profile with `pactl list cards`:

   ```sh
   pactl set-card-profile alsa_card.pci-0000_09_00.1 output:hdmi-surround71-extra3
   ```

3. Start Kodi. Go to **Settings > System > Audio** (settings level **Expert**).
4. Set **Audio output device** and **Passthrough output device** to the ALSA HDMI device
   for your TV or receiver, for example `HDA ATI, <TV name> on HDMI #3`.
   Do not use the `PULSE` or `pipewire` devices.
5. Enable **Allow passthrough** and the formats that your TV or receiver supports.
6. If you set an audio offset before, set it to 0.

While Kodi plays, Kodi has the HDMI audio device. When you exit Kodi, PipeWire gets the device again.

## Test

Do these tests after each install. Write the result for each test.

| No. | Test | Expected result |
| --- | --- | --- |
| 1 | Boot the CB1 kernel. Run `journalctl -k -b \| grep -i dvbridge`. | `family_supported=1` on the HDMI connector |
| 2 | Start Kodi from Plasma Bigscreen. | Kodi shows on the TV. `kodi.log` shows `dv_property=present`. `kodi.log` does not show `Failed to authorize drm magic` |
| 3 | Play a Profile 8.1 file with **DV Standard**. | TV shows the Dolby Vision badge. Colours are correct. `kodi.log` shows `output admission: ... effective=Dolby Vision` |
| 4 | Play a Profile 7 FEL file with **DV Master Reference**. | Same as test 3. Player information shows **Full FEL** |
| 5 | During playback, open **Player information**. | The CB1 dialog shows (Video, Dolby Vision, Audio, Output & Processing) |
| 6 | Play a file with E-AC3 audio. | TV or receiver shows Dolby Audio. Speech and lips are in sync. Player information shows **Passthrough** |
| 7 | Play a file with DTS-HD MA audio. | Player information shows `pt-dtshd` and **Passthrough**. TV or receiver shows DTS |
| 8 | Play a file with TrueHD / Atmos audio. | Player information shows **Passthrough**. TV or receiver shows Dolby TrueHD or Dolby Atmos |
| 9 | Play a file with AAC or stereo audio. | Audio plays correctly |
| 10 | Select **Power > Exit** in Kodi. | Kodi stops. The TV shows Plasma again |

If test 2 shows a black screen, `kodi.log` shows `Failed to authorize drm magic`.
Plasma (KWin) did not release the display. Restart the computer, or log out of Plasma and log in again.
This can occur when Kodi starts again a few seconds after it stops.

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
