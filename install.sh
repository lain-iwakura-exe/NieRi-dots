#!/usr/bin/env bash
#
# NieRi-dots installer
# Niri + Noctalia + YoRHa SDDM + NieR-cursors rice, for Arch Linux
# and Arch derivatives (CachyOS, EndeavourOS, Artix-arch, Manjaro, ...) only.
#
# Usage:
#   ./install.sh            interactive, asks before every risky step
#   ./install.sh --yes       same, but auto-confirms every prompt
#
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTO_YES=0
[[ "${1:-}" == "--yes" || "${1:-}" == "-y" ]] && AUTO_YES=1

# Optional: a tar.gz of wallpapers attached to a GitHub Release, downloaded
# automatically if wallpapers/ in this repo is empty. Leave blank to disable.
# Create it with: tar -czvf nier-wallpapers.tar.gz *.jpg
# then attach it to a Release on GitHub and paste the asset's download URL here.
WALLPAPER_ARCHIVE_URL="https://github.com/lain-iwakura-exe/NieRi-dots/releases/download/wallpapers-v1/wallpapers.tar.gz"

# ---------------------------------------------------------------------------
# Pretty output
# ---------------------------------------------------------------------------
c_reset='\033[0m'
c_dim='\033[2m'
c_purple='\033[38;5;135m'
c_cyan='\033[38;5;80m'
c_red='\033[38;5;204m'
c_green='\033[38;5;120m'

info()  { printf "${c_purple}::${c_reset} %s\n" "$*"; }
ok()    { printf "${c_green}::${c_reset} %s\n" "$*"; }
warn()  { printf "${c_red}::${c_reset} %s\n" "$*"; }
step()  { printf "\n${c_cyan}==>${c_reset} %s\n" "$*"; }

confirm() {
    local prompt="$1"
    if [[ $AUTO_YES -eq 1 ]]; then
        return 0
    fi
    local ans
    read -r -p "$(printf "${c_purple}?${c_reset} %s [y/N] " "$prompt")" ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

banner() {
cat <<'EOF'

  _   _ _      ____  _        _       _
 | \ | (_) ___|  _ \(_)      | |     | |
 |  \| | |/ _ \ |_) |___   __| | ___ | |_ ___
 | . ` | |  __/  _ <| \ \ / _` |/ _ \| __/ __|
 | |\  | |  __| |_) | |\ V | (_| | (_) | |_\__ \
 |_| \_|_|\___|____/|_| \_/ \__,_|\___/ \__|___/

        niri + noctalia + YoRHa rice for Arch
EOF
}

# ---------------------------------------------------------------------------
# Sanity checks
# ---------------------------------------------------------------------------
require_arch() {
    if ! command -v pacman >/dev/null 2>&1; then
        warn "pacman not found. NieRi-dots only supports Arch Linux and its derivatives."
        exit 1
    fi
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        local ok_distro=0
        [[ "${ID:-}" == "arch" ]] && ok_distro=1
        [[ "${ID_LIKE:-}" == *arch* ]] && ok_distro=1
        if [[ $ok_distro -eq 0 ]]; then
            warn "This doesn't look like Arch or an Arch derivative (ID='${ID:-unknown}')."
            confirm "Continue anyway?" || exit 1
        fi
    fi
}

require_not_root() {
    if [[ "$EUID" -eq 0 ]]; then
        warn "Don't run this as root. Run it as your normal user; it will call sudo when it needs to."
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# yay bootstrap
# ---------------------------------------------------------------------------
ensure_yay() {
    if command -v yay >/dev/null 2>&1; then
        ok "yay already installed."
        return
    fi
    step "yay (AUR helper) not found."
    confirm "Install yay-bin from the AUR now?" || { warn "Skipping yay install — AUR packages will be skipped too."; return 1; }

    sudo pacman -S --needed --noconfirm base-devel git

    local tmpdir
    tmpdir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
    (cd "$tmpdir/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
    ok "yay installed."
}

# ---------------------------------------------------------------------------
# Package lists
# ---------------------------------------------------------------------------
PACMAN_PACKAGES=(
    niri
    kitty
    fish
    fuzzel
    thunar
    swaylock
    polkit-gnome
    git
    curl
    unzip
    base-devel
    brightnessctl
    playerctl
    pipewire
    pipewire-pulse
    wireplumber
    ntfs-3g
    udisks2
    blueman
    bluez
    bluez-utils
    starship
    ttf-jetbrains-mono-nerd
    sddm
    qt5-svg
    qt5-graphicaleffects
    qt5-quickcontrols2
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    gnome-themes-extra
    adwaita-icon-theme
    fastfetch
    awww
)

AUR_PACKAGES=(
    noctalia
    waypaper-git
    nier-cursors-bin
)

install_pacman_packages() {
    step "Installing official-repo packages"
    printf '%s\n' "${PACMAN_PACKAGES[@]}" | sed 's/^/    - /'
    confirm "Proceed with pacman install?" || { warn "Skipped official package install."; return; }
    sudo pacman -S --needed "${PACMAN_PACKAGES[@]}"
}

install_aur_packages() {
    if ! command -v yay >/dev/null 2>&1; then
        warn "yay not available, skipping AUR packages (${AUR_PACKAGES[*]})."
        return
    fi
    step "Installing AUR packages"
    printf '%s\n' "${AUR_PACKAGES[@]}" | sed 's/^/    - /'
    confirm "Proceed with yay install?" || { warn "Skipped AUR package install."; return; }
    yay -S --needed "${AUR_PACKAGES[@]}"
}

# ---------------------------------------------------------------------------
# Config deployment
# ---------------------------------------------------------------------------
backup_if_exists() {
    local target="$1"
    if [[ -e "$target" || -L "$target" ]]; then
        local backup="${target}.bak-$(date +%Y%m%d-%H%M%S)"
        mv "$target" "$backup"
        info "Backed up existing $(basename "$target") to $(basename "$backup")"
    fi
}

deploy_configs() {
    step "Deploying configs to ~/.config"
    confirm "This will back up and replace ~/.config/niri, fish, kitty, fuzzel, fastfetch and ~/.config/starship.toml. Continue?" || { warn "Skipped config deployment."; return; }

    mkdir -p "$HOME/.config"

    backup_if_exists "$HOME/.config/niri"
    mkdir -p "$HOME/.config/niri"
    cp "$REPO_DIR/config/niri/config.kdl" "$HOME/.config/niri/config.kdl"

    backup_if_exists "$HOME/.config/fish/config.fish"
    mkdir -p "$HOME/.config/fish"
    cp "$REPO_DIR/config/fish/config.fish" "$HOME/.config/fish/config.fish"

    backup_if_exists "$HOME/.config/kitty"
    mkdir -p "$HOME/.config/kitty"
    cp "$REPO_DIR/config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"

    backup_if_exists "$HOME/.config/fuzzel"
    mkdir -p "$HOME/.config/fuzzel"
    cp "$REPO_DIR/config/fuzzel/fuzzel.ini" "$HOME/.config/fuzzel/fuzzel.ini"

    backup_if_exists "$HOME/.config/starship.toml"
    cp "$REPO_DIR/config/starship/starship.toml" "$HOME/.config/starship.toml"

    backup_if_exists "$HOME/.config/fastfetch/config.jsonc"
    mkdir -p "$HOME/.config/fastfetch"
    cp "$REPO_DIR/config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
    if [[ ! -f "$HOME/.config/fastfetch/logo.jpg" ]]; then
        warn "fastfetch config points at ~/.config/fastfetch/logo.jpg — that image isn't"
        warn "bundled (character art), so copy your own logo there, e.g.:"
        warn "    cp ~/Downloads/2B.jpg ~/.config/fastfetch/logo.jpg"
    fi

    ok "Configs deployed."
}

set_fish_as_shell() {
    local fish_path
    fish_path="$(command -v fish || true)"
    [[ -z "$fish_path" ]] && return
    if [[ "$SHELL" != "$fish_path" ]]; then
        confirm "Set fish as your login shell (chsh)?" || return
        chsh -s "$fish_path"
        ok "Login shell changed to fish (takes effect on next login)."
    fi
}

# ---------------------------------------------------------------------------
# Wallpapers
# ---------------------------------------------------------------------------
deploy_wallpapers() {
    step "Wallpapers"
    local dest="$HOME/Pictures/nier-wallpapers"
    mkdir -p "$dest"

    if compgen -G "$REPO_DIR/wallpapers/*" > /dev/null 2>&1; then
        cp -n "$REPO_DIR"/wallpapers/* "$dest"/ 2>/dev/null
        ok "Copied wallpapers from the repo's wallpapers/ folder to $dest"
        return
    fi

    if [[ -n "$WALLPAPER_ARCHIVE_URL" ]]; then
        download_wallpaper_archive "$dest" && return
    fi

    warn "No local wallpapers and no archive downloaded."
    info "Either drop images into $REPO_DIR/wallpapers/ and re-run, or put them"
    info "directly into $dest yourself."
}

download_wallpaper_archive() {
    local dest="$1"

    if ! command -v curl >/dev/null 2>&1; then
        warn "curl not installed, can't fetch the wallpaper archive."
        return 1
    fi

    step "Downloading wallpaper pack"
    info "Source: $WALLPAPER_ARCHIVE_URL"
    confirm "Download and extract wallpapers from this URL?" || { warn "Skipped wallpaper download."; return 1; }

    local tmpdir archive
    tmpdir="$(mktemp -d)"
    archive="$tmpdir/wallpapers.tar.gz"

    if ! curl -fsSL "$WALLPAPER_ARCHIVE_URL" -o "$archive"; then
        warn "Download failed. Check WALLPAPER_ARCHIVE_URL at the top of install.sh"
        warn "— the release/tag/filename may not exist yet."
        rm -rf "$tmpdir"
        return 1
    fi

    if ! tar -xzf "$archive" -C "$dest" 2>/dev/null; then
        # Not a tar.gz — try it as a zip instead.
        if command -v unzip >/dev/null 2>&1 && unzip -q "$archive" -d "$dest" 2>/dev/null; then
            :
        else
            warn "Couldn't extract the downloaded file as .tar.gz or .zip."
            rm -rf "$tmpdir"
            return 1
        fi
    fi

    rm -rf "$tmpdir"
    ok "Wallpapers downloaded and extracted to $dest"
}

# ---------------------------------------------------------------------------
# SDDM: YoRHa theme
# ---------------------------------------------------------------------------
install_sddm_theme() {
    step "YoRHa SDDM theme"
    confirm "Clone and install NeekoKun/YoRHa-sddm-theme to /usr/share/sddm/themes/?" || { warn "Skipped SDDM theme."; return; }

    local theme_dir="/usr/share/sddm/themes/YoRHa-sddm-theme"
    if [[ -d "$theme_dir" ]]; then
        info "Theme already present at $theme_dir, pulling latest instead of re-cloning."
        sudo git -C "$theme_dir" pull
    else
        sudo git clone --depth=1 https://github.com/NeekoKun/YoRHa-sddm-theme.git "$theme_dir"
    fi

    sudo mkdir -p /etc/sddm.conf.d
    sudo tee /etc/sddm.conf.d/nieri-theme.conf > /dev/null <<EOF
[Theme]
Current=YoRHa-sddm-theme
CursorTheme=nier-cursors-bin
EOF
    ok "SDDM theme installed and set as current."

    confirm "Preview the theme now with sddm-greeter --test-mode? (needs an X/Wayland test window)" && \
        QML2_IMPORT_PATH=/usr/lib/qt/qml sddm-greeter --test-mode --theme "$theme_dir" || true

    if ! systemctl is-enabled sddm >/dev/null 2>&1; then
        confirm "Enable sddm.service to boot into it?" && sudo systemctl enable sddm
    else
        ok "sddm.service already enabled."
    fi
}

# ---------------------------------------------------------------------------
# Cursor theme wiring beyond niri (GTK apps, SDDM greeter, X apps via env)
# ---------------------------------------------------------------------------
wire_cursor_theme() {
    step "Cursor theme"
    local theme_name="nier-cursors-bin"

    # Try to detect the actual xcursor theme name the AUR package installs,
    # since the pkgname and the on-disk cursor theme name don't always match.
    local found
    found="$(find /usr/share/icons ~/.icons -maxdepth 1 -iname '*nier*' 2>/dev/null | head -n1)"
    if [[ -n "$found" ]]; then
        theme_name="$(basename "$found")"
        ok "Detected cursor theme name: $theme_name"
        if [[ "$theme_name" != "nier-cursors-bin" ]]; then
            warn "This differs from the placeholder in config.kdl and gtk settings."
            warn "Update xcursor-theme in ~/.config/niri/config.kdl and Xcursor-theme below to: $theme_name"
        fi
    else
        warn "Couldn't auto-detect the installed cursor theme folder under /usr/share/icons."
        warn "After installing nier-cursors-bin, check 'ls /usr/share/icons' and update"
        warn "xcursor-theme in ~/.config/niri/config.kdl to match the exact folder name."
    fi

    mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" "$HOME/.icons/default"

    # GTK3 (covers Thunar): cursor theme + Adwaita-dark
    cat > "$HOME/.config/gtk-3.0/settings.ini" <<EOF
[Settings]
gtk-cursor-theme-name=$theme_name
gtk-cursor-theme-size=24
gtk-theme-name=Adwaita-dark
gtk-application-prefer-dark-theme=1
gtk-icon-theme-name=Adwaita
EOF

    # GTK4 apps follow color-scheme rather than a named theme
    cat > "$HOME/.config/gtk-4.0/settings.ini" <<EOF
[Settings]
gtk-cursor-theme-name=$theme_name
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF

    cat > "$HOME/.icons/default/index.theme" <<EOF
[Icon Theme]
Inherits=$theme_name
EOF

    mkdir -p "$HOME/.config/environment.d"
    cat > "$HOME/.config/environment.d/cursor.conf" <<EOF
XCURSOR_THEME=$theme_name
XCURSOR_SIZE=24
GTK_THEME=Adwaita-dark
EOF

    ok "Cursor theme + Adwaita-dark wired for GTK apps (Thunar) and session environment."
}

# ---------------------------------------------------------------------------
# waypaper: point it at the wallpaper folder automatically
# ---------------------------------------------------------------------------
configure_waypaper() {
    if ! command -v waypaper >/dev/null 2>&1; then
        warn "waypaper not installed, skipping its config."
        return
    fi
    step "Pointing waypaper at your wallpaper folder"

    local wp_dir="$HOME/Pictures/nier-wallpapers"
    local wp_conf_dir="$HOME/.config/waypaper"
    local wp_conf="$wp_conf_dir/config.ini"

    mkdir -p "$wp_conf_dir"
    backup_if_exists "$wp_conf"

    # Minimal, known-good waypaper schema (per upstream docs). If a future
    # waypaper version renames these keys, just set the folder once via the
    # GUI (Mod+G) — it persists back into this same file.
    # backend=awww requires the awww-daemon to already be running — that's
    # spawned at niri startup (see config/niri/config.kdl).
    cat > "$wp_conf" <<EOF
[Settings]
language = en
folder = $wp_dir
backend = awww
monitors = All
fill = Fill
sort = name
subfolders = False
show_hidden = False
number_of_columns = 3
EOF

    ok "waypaper's folder set to $wp_dir — Mod+G opens straight into it."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    banner
    require_not_root
    require_arch

    info "This installer will:"
    echo "    1. Install yay (if missing)"
    echo "    2. Install official + AUR packages (niri, noctalia, fuzzel, kitty,"
    echo "       fish, waypaper, nier-cursors-bin, sddm, starship, fastfetch, ...)"
    echo "    3. Back up and deploy niri / fish / kitty / fuzzel / fastfetch / starship configs"
    echo "    4. Copy wallpapers (if present in the repo) and point waypaper at them"
    echo "    5. Install and enable the YoRHa SDDM theme"
    echo "    6. Wire up the NieR cursor theme + Adwaita-dark system-wide"
    echo
    confirm "Continue?" || { warn "Aborted."; exit 0; }

    ensure_yay
    install_pacman_packages
    install_aur_packages
    deploy_configs
    set_fish_as_shell
    deploy_wallpapers
    install_sddm_theme
    wire_cursor_theme
    configure_waypaper

    step "Done"
    ok "Reboot or restart your session to boot into niri via the new SDDM theme."
    info "Mod+D  = fuzzel   Mod+T = kitty   Mod+G = waypaper   Mod+O = overview"
    info "Check ~/.config/niri/config.kdl if the cursor theme name needed adjusting above."
    info "Don't forget your fastfetch logo: cp ~/Downloads/2B.jpg ~/.config/fastfetch/logo.jpg"
}

main "$@"
