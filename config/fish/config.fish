if status is-interactive
    # NieRi-dots — fish interactive config

    set -g fish_greeting ""

    # Prints system info on every new terminal. Delete this line (or
    # comment it out) if you'd rather it not run automatically.
    fastfetch

    # Starship prompt
    starship init fish | source

    # --- Abbreviations -------------------------------------------------
    # Add/edit freely — these are just a sane starting set for an
    # Arch + yay + git + niri workflow. `abbr --show` lists them all.

    # Package management
    abbr -a up   'sudo pacman -Syu'
    abbr -a yup  'yay -Syu'
    abbr -a pin  'sudo pacman -S'
    abbr -a yin  'yay -S'
    abbr -a prm  'sudo pacman -Rns'

    # Snapper / Btrfs snapshots
    abbr -a snl  'sudo snapper -c root list'
    abbr -a snc  'sudo snapper -c root create --description'

    # Git
    abbr -a gs   'git status'
    abbr -a ga   'git add'
    abbr -a gc   'git commit -m'
    abbr -a gp   'git push'
    abbr -a gl   'git pull'
    abbr -a gco  'git checkout'

    # Niri / session
    abbr -a nirimsg 'niri msg'
    abbr -a reload  'niri msg action load-config-file'

    # Filesystem
    abbr -a ll   'ls -lah'
    abbr -a ..   'cd ..'
    abbr -a ...  'cd ../..'
end
