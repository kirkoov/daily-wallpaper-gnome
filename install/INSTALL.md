# Installation

## Prerequisites

- Ubuntu 22.04 or later
- GNOME desktop environment
- anacron
- gsettings
- notify-send

## 1. Clone the repository

   ```bash
   git clone git@github.com:kirkoov/daily-wallpaper-gnome.git
   cd daily-wallpaper-gnome
   ```

## 2. Install the scripts

Before installing:

- edit `daily-wallpaper.sh` and set `WALLPAPER_DIR`
- edit `daily-wallpaper-anacron` and replace `username` with your Linux username

Then copy both scripts:

```bash
sudo cp daily-wallpaper.sh daily-wallpaper-anacron /usr/local/bin/
```

Make them executable:

```bash
sudo chmod +x /usr/local/bin/daily-wallpaper.sh
sudo chmod +x /usr/local/bin/daily-wallpaper-anacron
```

## 3. Install the anacron job

Copy the contents of `install/anacrontab.example` into `/etc/anacrontab`.

## 4. Enable anacron on battery (optional)

On laptops, anacron does not run on battery by default.

Create the override directory:

```bash
   sudo mkdir -p /etc/systemd/system/anacron.service.d
   sudo cp install/on-ac.conf /etc/systemd/system/anacron.service.d/
```

Then reload systemd and restart the timer:

```bash
sudo systemctl daemon-reload
sudo systemctl restart anacron.timer
```

## 5. Test the installation

Verify the script:

```bash
sudo /usr/local/bin/daily-wallpaper-anacron

gsettings get org.gnome.desktop.background picture-uri
gsettings get org.gnome.desktop.background picture-uri-dark
```

> **Note**
> Running `daily-wallpaper-anacron` manually marks the Anacron job as executed for the current day. Consequently, Anacron will not run it again until the next scheduled day.

Verify that Anacron is running correctly: `journalctl -u anacron.service -n 20` or `journalctl -u anacron.service --since today | grep daily-wallpaper`

Verify that the `ConditionACPower=` override appears at the end of the output:

```bash
systemctl cat anacron.service
```

## Troubleshooting

If the wallpaper does not change automatically, verify that:

- the wallpaper directory exists and contains supported images
- `anacron` is installed and enabled
- the wrapper script points to the correct location of `daily-wallpaper.sh`
- `DISPLAY` and `DBUS_SESSION_BUS_ADDRESS` are set correctly for your GNOME session if you customised the scripts
- both scripts are executable (`chmod +x /usr/local/bin/daily-wallpaper*`)
- to reset everything and start the uniqueness cycle from scratch, run:

   ```bash
   rm ~/.local/share/daily-wallpaper/wallpaper-history.log
   rm ~/.local/share/daily-wallpaper/cycle-number.txt
   ```

### Removing the installation

To completely remove the installed components, run:

```bash
sudo rm /usr/local/bin/daily-wallpaper-anacron
sudo sed -i '/daily-wallpaper/d' /etc/anacrontab
sudo rm -rf /etc/systemd/system/anacron.service.d
sudo systemctl daemon-reload
   ```

`Note: This does not remove the wallpaper history stored in ~/.local/share/daily-wallpaper/.`
