# NieRi-dots

A NieR: Automata rice for **Arch Linux and Arch derivatives only**
(CachyOS, EndeavourOS, Artix-arch, Manjaro, etc.) — built around
[niri](https://github.com/YaLTeR/niri) +
[Noctalia](https://github.com/noctalia-dev/noctalia-shell) shell. Purple
accents in kitty and fuzzel (`#a277ff`), blue focus ring in niri
(`#7fc8ff`), blue-grey starship prompt.

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

Using SSH instead of HTTPS:

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
   packages (`noctalia`, `waypaper-git`, `nier-cursors-bin`) via `yay`.
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

## Wallpapers

The 10 wallpapers in `wallpapers/` are already committed to this repo, so
running `./install.sh` just works out of the box — `deploy_wallpapers()`
copies them into `~/Pictures/nier-wallpapers` and `configure_waypaper()`
points waypaper's `folder` key at that same directory, using the `awww`
backend. That directory name is hardcoded in `install.sh`, not something
each person picks — if you fork this and want a different path, change it
in `deploy_wallpapers()` and `configure_waypaper()`.

`awww-daemon` (the actual wallpaper renderer waypaper drives) is spawned at
niri startup in `config/niri/config.kdl`. If wallpapers don't seem to
apply, check it's actually running first: `pgrep awww-daemon`. Once it's
up, open the picker with `Mod+G` — the images are already loaded, just
pick one.

It's safe to re-run `./install.sh` any time — already-installed packages
and existing wallpaper files are left alone.

If you add more images later, drop them straight into `wallpapers/` and
push — same as the first ten.

### If the repo ever gets too heavy to clone

Images bundled straight into git add to the clone size forever, which is
fine at 10 wallpapers but won't scale forever. If that becomes annoying,
the alternative is tarring them up and attaching that as a GitHub Release
asset instead, then pointing `WALLPAPER_ARCHIVE_URL` at the top of
`install.sh` at the download link. `deploy_wallpapers()` already checks for
that URL and downloads it whenever `wallpapers/` is empty — so switching
over just means moving the files out of the repo and into a Release,
nothing in the script needs to change.

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
  stores this separately from niri — once it's tuned the way you want, drop
  it in `config/noctalia/` and add it to `deploy_configs()` in `install.sh`.

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
