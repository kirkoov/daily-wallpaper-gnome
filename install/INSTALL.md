# Installation

## Prerequisites

- Ubuntu 22.04
- GNOME desktop environment
- Bash
- git
- anacron
- gsettings
- gio (required only for the `reject` command)
- notify-send (optional, for desktop notifications)

## 1. Clone the repository

```bash
git clone https://github.com/kirkoov/daily-wallpaper-gnome.git
cd daily-wallpaper-gnome
```

Alternatively, if you prefer SSH and have GitHub SSH access configured:

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

On Ubuntu 22.04, the packaged `anacron.service` includes `ConditionACPower=true`, so anacron jobs do not run while the laptop is on battery unless this condition is overridden.

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

> **Note:**
> Running `daily-wallpaper-anacron` manually tests the wrapper and wallpaper script only. It does not mark the anacron job as executed for the current day.

Verify that the anacron is running correctly: `journalctl -u anacron.service -n 20` or `journalctl -u anacron.service --since today | grep daily-wallpaper`

If you enabled anacron on battery in step 4, verify that the `ConditionACPower=` override appears at the end of the output:

```bash
systemctl cat anacron.service
```

If these checks pass, the installation is complete.

See the main [README](../README.md#usage) for normal use, including changing the wallpaper immediately, rejecting the current wallpaper, optional keyboard shortcuts and custom scheduling.

## Troubleshooting

If the wallpaper does not change automatically, verify that:

- the wallpaper directory exists and contains supported images
- `anacron` is installed and enabled
- the wrapper script points to the correct location of `daily-wallpaper.sh`
- both scripts are executable (`chmod +x /usr/local/bin/daily-wallpaper*`)
- to reset the selection history and start the uniqueness cycle from scratch, run:

  ```bash
  rm -f ~/.local/share/daily-wallpaper/wallpaper-history.log
  rm -f ~/.local/share/daily-wallpaper/cycle-number.txt
  ```

### Removing the installation

To completely remove the installed components, run:

```bash
sudo rm -f /usr/local/bin/daily-wallpaper.sh
sudo rm -f /usr/local/bin/daily-wallpaper-anacron
sudo sed -i '/daily-wallpaper/d' /etc/anacrontab
sudo rm -f /etc/systemd/system/anacron.service.d/on-ac.conf
sudo rm -f /var/spool/anacron/daily-wallpaper
sudo systemctl daemon-reload
```

> **Note:** This does not remove the runtime state stored in `~/.local/share/daily-wallpaper/`.
