# Daily Wallpaper for GNOME

A lightweight Bash utility that automatically changes the GNOME desktop wallpaper each day using a local image collection.

## Features

- the script respects your existing GNOME wallpaper scaling mode
- randomly selects an unseen image without repeats until all images have been shown
- automatically starts a new cycle afterwards
- designed to run daily via anacron
- survives reboots and missed boot times
- updates both GNOME Light and Dark wallpaper settings
- verifies that the wallpaper was successfully applied
- displays a desktop notification with the image name
- supports JPG, JPEG, PNG and WebP images

## Requirements

- Ubuntu 22.04 or later
- GNOME
- anacron
- gsettings
- notify-send

## Installation

See [install/INSTALL.md](install/INSTALL.md) for detailed installation and configuration instructions.
The instructions have been tested on a clean system using only the steps documented.

## Usage

Once installed, the wallpaper is changed automatically by anacron whenever the daily job becomes due.

## How it works

- keeps a persistent history of displayed images
- scans the configured wallpaper directory
- randomly selects an unseen image
- updates both GNOME wallpaper settings
- starts a new cycle after every image has been displayed

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

This utility was created to solve a practical problem: changing the GNOME desktop wallpaper automatically every day on a laptop, including after missed boot times, while ensuring that images are not repeated until the entire collection has been displayed.

It demonstrates practical Bash scripting, Linux automation, persistent state management, and interaction with GNOME via `gsettings`.

## Licence

This project is distributed under the terms of the licence included in the `LICENCE` file.
