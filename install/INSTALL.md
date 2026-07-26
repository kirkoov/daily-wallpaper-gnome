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

- copy `daily-wallpaper.sh` and `daily-wallpaper-anacron` to `/usr/local/bin/`

- and make both scripts executable:

   ```bash
   sudo chmod +x /usr/local/bin/daily-wallpaper.sh
   sudo chmod +x /usr/local/bin/daily-wallpaper-anacron
   ```

## 3. Configure the wallpaper directory

Edit `daily-wallpaper.sh` and set:

   ```bash
   WALLPAPER_DIR="$HOME/Pictures/DesktopBackgrounds/"
   ```

## 4. Install the anacron job

Copy the `daily-wallpaper` job from `install/anacrontab.example` into `/etc/anacrontab`.

## 5. Enable anacron on battery (optional)

On laptops, anacron does not run on battery by default.
Copy `install/on-ac.conf` to `/etc/systemd/system/anacron.service.d/`.

Then

```bash
sudo systemctl daemon-reload
sudo systemctl restart anacron.timer
```

## 6. Test the installation

```bash
sudo /usr/local/bin/daily-wallpaper-anacron
gsettings get org.gnome.desktop.background picture-uri
gsettings get org.gnome.desktop.background picture-uri-dark
journalctl -u anacron.service --since today | grep daily-wallpaper

```

## Troubleshooting

If the wallpaper does not change automatically, verify that:

- the wallpaper directory exists and contains supported images
- `anacron` is installed and enabled
- the wrapper script points to the correct location of `daily-wallpaper.sh`
- `DISPLAY` and `DBUS_SESSION_BUS_ADDRESS` are correctly configured
- the scripts are executable (`chmod +x`)
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

```text
NB! This does not remove the wallpaper history stored in
~/.local/share/daily-wallpaper/.
```
