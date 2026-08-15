# NieRi-dots

A dark purple NieR: Automata rice for **Arch Linux and Arch derivatives
only** (CachyOS, EndeavourOS, Artix-arch, Manjaro, etc.) — built around
[niri](https://github.com/YaLTeR/niri) +
[Noctalia](https://github.com/noctalia-dev/noctalia-shell) shell.

## What's included

| Component        | Tool                                                     |
|-------------------|-----------------------------------------------------------|
| Compositor        | niri                                                       |
| Shell / bar       | Noctalia                                                   |
| Launcher          | fuzzel (Adwaita-dark)                                      |
| Terminal          | kitty                                                      |
| Shell             | fish + starship prompt                                     |
| System info       | fastfetch                                                  |
| File manager      | Thunar (Adwaita-dark)                                      |
| Screen lock       | swaylock                                                    |
| Wallpaper picker  | waypaper (pre-pointed at your wallpaper folder)             |
| Login manager     | SDDM + [YoRHa-sddm-theme](https://github.com/NeekoKun/YoRHa-sddm-theme) |
| Cursors           | [nier-cursors-bin](https://aur.archlinux.org/packages/nier-cursors-bin) (AUR) |

## Install

```bash
git clone https://github.com/lain-iwakura-exe/NieRi-dots.git
cd NieRi-dots
./install.sh
```

Already have SSH set up with GitHub (as this repo's owner does)? Use this
instead:

```bash
git clone git@github.com:lain-iwakura-exe/NieRi-dots.git
cd NieRi-dots
./install.sh
```

The script is interactive by default — it explains each step and asks
`[y/N]` before touching packages, your `~/.config`, or system files like
`/etc/sddm.conf.d/`. Existing configs are backed up (not overwritten) with a
timestamp suffix, e.g. `~/.config/niri.bak-20260814-053000`.

Non-interactive (accepts every prompt):

```bash
./install.sh --yes
```

## What the installer does

1. **Bootstraps `yay`** if it isn't already installed (builds `yay-bin` from
   the AUR).
2. **Installs packages** — official repo packages via `pacman`, then AUR
   packages (`noctalia`, `waypaper`, `nier-cursors-bin`) via `yay`.
3. **Deploys configs** into `~/.config/{niri,fish,kitty,fuzzel,fastfetch}`
   and `~/.config/starship.toml`.
4. **Copies wallpapers** from `wallpapers/` into `~/Pictures/nier-wallpapers`
   if any are present in the repo — otherwise offers to download and
   extract a wallpaper pack from a GitHub Release (see below) — and
   **points waypaper at that folder automatically** by writing its `folder`
   key in `~/.config/waypaper/config.ini`.
5. **Installs the YoRHa SDDM theme** by cloning it straight into
   `/usr/share/sddm/themes/` and pointing `/etc/sddm.conf.d/nieri-theme.conf`
   at it. Also installs the Qt5 dependencies (`qt5-svg`,
   `qt5-graphicaleffects`, `qt5-quickcontrols2`) the theme needs to render.
6. **Wires the cursor theme** into GTK apps, your session environment, and
   the SDDM greeter. AUR package names don't always match the on-disk
   xcursor theme folder name, so the script tries to auto-detect it under
   `/usr/share/icons` and warns you if `~/.config/niri/config.kdl` needs a
   manual tweak.
7. **Sets Adwaita-dark** as the GTK3/GTK4 theme (via `gnome-themes-extra`)
   so Thunar renders dark, and points fuzzel's icon theme at the same
   Adwaita icon set so launcher icons match.
8. **Installs `fastfetch`** and deploys its config — see the Fastfetch
   section below for the one manual step (your own logo image).

## Adding your own wallpapers

The repo doesn't ship any wallpaper images — they're copyrighted game art,
so they can't be fetched or bundled automatically. There are two ways to
get your set into the install:

### Option A — bundle them as a GitHub Release (recommended)

Keeps the repo's git history free of binary image files.

1. Tar up your wallpapers:
   ```bash
   cd ~/Pictures/"nier wallpapers"
   tar -czvf wallpapers.tar.gz *.jpg
   ```
2. On GitHub: **your repo → Releases → "Create a new release"**
   - Tag: `wallpapers-v1`
   - Title: whatever you like, e.g. `Wallpapers v1`
   - Drag `wallpapers.tar.gz` into the attachments box at the bottom
   - Click **Publish release**
3. Copy the direct download link for that asset (right-click it on the
   release page → Copy Link, or just click it once to see the URL in your
   address bar). It looks like:
   ```
   https://github.com/lain-iwakura-exe/NieRi-dots/releases/download/wallpapers-v1/wallpapers.tar.gz
   ```
4. Paste that URL into `WALLPAPER_ARCHIVE_URL` near the top of `install.sh`,
   commit, and push.

From then on, anyone (including you, on a fresh install) running
`./install.sh` with an empty `wallpapers/` folder gets prompted to download
and extract that archive straight into `~/Pictures/nier-wallpapers`
automatically — no manual step needed after the first setup.

Adding more wallpapers later: tar up the updated set, upload it as a new
release asset (or edit the existing release and swap the file), bump the
tag if you like, and update `WALLPAPER_ARCHIVE_URL` if the filename/tag
changed.

### Option B — commit them straight into the repo

Simpler, but every image adds to the repo's clone size forever.

1. Drop your image files into `wallpapers/` in this repo:
   ```bash
   cp ~/Pictures/nier-wallpapers/*.jpg NieRi-dots/wallpapers/
   ```
2. Commit and push as normal.

If `wallpapers/` has files in it, the installer uses those directly and
skips the Release download entirely — Option B always takes priority over
Option A.

### Either way

Run (or re-run) the installer:
```bash
./install.sh
```
`deploy_wallpapers()` gets your images into `~/Pictures/nier-wallpapers`,
and `configure_waypaper()` points waypaper's `folder` key at that same
directory, using the `awww` backend. `awww-daemon` (the actual wallpaper
renderer waypaper drives) is spawned at niri startup in
`config/niri/config.kdl` — if wallpapers don't seem to apply, check it's
actually running with `pgrep awww-daemon` before anything else. Open the
picker with `Mod+G` — your images are already loaded, just pick one.

It's safe to re-run `./install.sh` any time — already-installed packages
and existing wallpaper files are left alone.

### Picking a wallpaper directly in Noctalia

Noctalia has its own wallpaper picker built into its settings, separate
from waypaper — useful since it also drives the accent-color theming if
you have that turned on.

1. Click into Noctalia's bar to open the Control Center, then go to
   **Settings → Wallpaper**.
2. Set the **browse folder** to the same directory the installer already
   uses: `~/Pictures/nier-wallpapers`.
3. Click any tile in the grid to apply it immediately — it writes straight
   to Noctalia's `settings.toml`, no restart needed. Star (favorite) any
   you want to jump back to quickly later.
4. If you're on a multi-monitor setup, use the monitor selector in the
   panel's toolbar to set a different wallpaper per screen, or leave it on
   **ALL** to apply one everywhere.

You can also drive this from the command line/scripts if you want it
scriptable, e.g. bound to a key or a random-on-login hook:
```bash
qs -c noctalia-shell ipc call wallpaper set /path/to/image.jpg
```

## Fastfetch

`fastfetch` is installed and configured to run automatically whenever you
open a new interactive shell (wired into `config/fish/config.fish`) — if
you'd rather it not print on every terminal open, just delete or comment
out the `fastfetch` line near the top of that file.

The included `config/fastfetch/config.jsonc` uses a kitty-protocol image
logo instead of ASCII art, pointed at:
```
~/.config/fastfetch/logo.jpg
```
That file isn't in the repo — same reasoning as the wallpapers, it's
character art and needs to be sourced by you, not bundled or fetched
automatically. Drop your own logo image there after running the installer:
```bash
mkdir -p ~/.config/fastfetch
cp ~/Downloads/2B.jpg ~/.config/fastfetch/logo.jpg
```
(Any image works — `2B.jpg` is just what's referenced by convention here.
Swap the `logo.source` path in `config/fastfetch/config.jsonc` if you'd
rather keep a different filename or location.)

## You need to add

- **Noctalia's own config** (bar layout, colors, palette source). Noctalia
  stores this separately from niri — once you've got it tuned the way you
  want, drop it in `config/noctalia/` and add a `deploy` line for it in
  `install.sh`'s `deploy_configs()` and I'll wire it in.

## Key binds (niri)

| Bind          | Action                          |
|---------------|----------------------------------|
| `Mod+T`       | Terminal (kitty)                 |
| `Mod+D`       | Launcher (fuzzel)                |
| `Mod+G`       | Wallpaper picker (waypaper)      |
| `Mod+E`       | File manager (Thunar)            |
| `Mod+B`       | Firefox                          |
| `Mod+O`       | Overview                         |
| `Mod+S`       | Preview the SDDM theme live      |
| `Super+Alt+L` | Lock screen (swaylock)           |

Full bind list lives in `config/niri/config.kdl`.

## Uninstall / revert

Config backups are timestamped next to the originals, e.g.:

```bash
mv ~/.config/niri.bak-20260814-053000 ~/.config/niri
```

The SDDM theme change can be reverted by deleting
`/etc/sddm.conf.d/nieri-theme.conf` (SDDM falls back to its default theme).
