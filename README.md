# Daily Wallpaper for GNOME

A lightweight Bash utility that automatically changes the GNOME desktop wallpaper each day using a local image collection.

## Features

- scans the target wallpaper directory recursively for JPG, JPEG, PNG and WebP images
- ships with a daily anacron setup using a 10-min delay before a due run
- catches up after a missed daily run when the machine was powered off
- selects randomly without repeats within a cycle, then starts a new cycle after every current image has been successfully shown
- uses GNOME's `scaled` wallpaper mode by default for proportional image fitting
- lets the user reject the current wallpaper by moving it to the Rubbish Bin, removing it from wallpaper history, and immediately selecting a replacement
- applies the wallpaper to both GNOME Light and Dark settings and verifies both URI values
- optionally displays a desktop notification, splitting recognised creator/title filename patterns for better readability
- performs one wallpaper change per invocation and exits; no `daily-wallpaper` process remains resident between changes

## Requirements

- Ubuntu 22.04 with GNOME (tested)
- Bash
- anacron
- gsettings
- gio (required only for the `reject` command)
- notify-send (optional, for desktop notifications)

Other Ubuntu/GNOME releases may work but have not been verified.

## Installation

See [install/INSTALL.md](install/INSTALL.md) for detailed installation and configuration instructions.
The instructions have been cleanly tested on Ubuntu 22.04 using only the steps documented.

## Usage

Once installed, the supplied anacron job handles the daily wallpaper change automatically. The script can also be run manually at any time.

To change the wallpaper immediately, run in your Terminal:

```bash
/usr/local/bin/daily-wallpaper.sh
```

To reject and trash the current wallpaper:

```bash
/usr/local/bin/daily-wallpaper.sh reject
```

The `reject` command moves the current image to the Rubbish Bin, removes its records from the utility's wallpaper history, and immediately selects and applies a replacement.

### Optional keyboard shortcuts

GNOME custom shortcuts can provide quick control without adding any background process.

For example:

| Shortcut | Action                   | Command                                                                  |
| -------- | ------------------------ | ------------------------------------------------------------------------ |
| `Alt+N`  | Change wallpaper now     | `/usr/local/bin/daily-wallpaper.sh`                                      |
| `Alt+W`  | Reject current wallpaper | `/usr/local/bin/daily-wallpaper.sh reject`                               |
| `Alt+0`  | Scaled                   | `gsettings set org.gnome.desktop.background picture-options 'scaled'`    |
| `Alt+1`  | Wallpaper / tiled        | `gsettings set org.gnome.desktop.background picture-options 'wallpaper'` |
| `Alt+2`  | Centred                  | `gsettings set org.gnome.desktop.background picture-options 'centered'`  |
| `Alt+3`  | Zoom                     | `gsettings set org.gnome.desktop.background picture-options 'zoom'`      |
| `Alt+4`  | Stretched                | `gsettings set org.gnome.desktop.background picture-options 'stretched'` |
| `Alt+5`  | Spanned                  | `gsettings set org.gnome.desktop.background picture-options 'spanned'`   |

These key combinations are examples only; choose shortcuts that do not conflict with your existing GNOME bindings.

Custom shortcuts can be added under **Settings → Keyboard → View and Customize Shortcuts → Custom Shortcuts → +**. Do not use `sudo`.

A display-mode shortcut affects the current wallpaper only. Every normal wallpaper change made by `daily-wallpaper.sh` restores the default `scaled` mode.

## How it works

The selection model is deliberately simple and inspectable, with no hidden queue or directory weighting.

- recursively scans the configured wallpaper directory for supported image files
- keeps a persistent history of successfully displayed image paths together with their cycle numbers
- gives every image path not yet successfully shown in the current cycle an equal chance of selection, regardless of subdirectory
- applies the selected image to both GNOME Light and Dark wallpaper settings
- verifies both URI values before recording the image as successfully shown
- when no unshown images remain, increments the cycle and starts again

### State files

Runtime state is kept under:

```text
~/.local/share/daily-wallpaper/
```

The main files are:

- `wallpaper-history.log` — successful-display records used for cycle tracking; rejected images are removed from it
- `current-wallpaper.txt` — the currently recorded wallpaper and its details
- `cycle-number.txt` — the current cycle number

These are plain-text files and can be inspected directly.

### Custom scheduling

The script itself has no built-in timer. Each invocation performs one wallpaper change and exits.

The supplied anacron configuration provides the default once-daily behaviour with a 10-minute delay. Advanced users can change that delay or invoke `/usr/local/bin/daily-wallpaper.sh` from another scheduler if they want a different frequency.

If another scheduler replaces the supplied daily schedule, disable or remove the anacron entry to avoid unintended extra changes.

On the tested Ubuntu 22.04 system, suspending the laptop during the 10-minute anacron delay paused the effective delay; it continued after resume. This is observed behaviour rather than a compatibility guarantee for other releases.

## Project structure

```text
daily-wallpaper-gnome/
├── daily-wallpaper.sh
├── daily-wallpaper-anacron
├── install/
│   ├── INSTALL.md
│   ├── anacrontab.example
│   └── on-ac.conf
├── README.md
├── LICENCE
└── .gitignore
```

## Why this project?

This utility was created to rotate a large local wallpaper collection reliably on a laptop, including after days when the machine was powered off.

It demonstrates practical Bash scripting, Linux automation, persistent state management, and interaction with GNOME via `gsettings`.

The script keeps its main responsibilities separated into focused functions for wallpaper selection, application and rejection, while remaining small enough to inspect from start to end.

### Why not a full wallpaper manager?

Full-featured wallpaper managers are a good choice if you want online sources, frequent rotation, favourites, filters, a GUI, and other desktop-management features.

`daily-wallpaper-gnome` is intentionally narrower.

> **One wallpaper a day does not require a wallpaper application running all day.**

It delegates scheduling to existing system tools and keeps its state in inspectable plain-text files.

The project deliberately favours a small, predictable and auditable workflow over a broader always-available application.

## Licence

This project is distributed under the terms of the licence included in the `LICENCE` file.
