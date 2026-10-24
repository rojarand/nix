Once basic files are set run only once:

```bash
sudo nix run nix-darwin -- switch --flake ~/.dotfiles 
```

After that run `./rebuild.sh`

Check the nix config:
```bash
nix flake check --no-build
```

## Raspberry Pi (Linux)

On a Linux machine, apply the Home Manager configuration instead of the
nix-darwin one:

```bash
./rebuild-pi.sh
```

This targets `homeConfigurations.zebul`, links the repository to `~/.dotfiles`,
and installs the packages from `home/default.nix` into `~/.nix-profile`.

## Shared tools

Both machines apply the same Home Manager configuration, so tools that should
exist everywhere are listed once in `home/common.nix` (currently `ffmpeg`,
`git`, `herdr`, `neovim`, `ripgrep`, `tmux` and the zsh plugins).

- Do not also list these in `homebrew.brews` in `configuration.nix`.
- Keep `homebrew` for macOS-only GUI apps and tools that nixpkgs does not have
  (for example the `wezterm` cask and `jira-cli`).
- Packages missing from the pinned 26.05 release (such as `herdr`) are pulled
  from the `nixpkgs-unstable` input through the overlay in `flake.nix`. Add a
  name to `unstablePackages` there to expose another one as `pkgs.<name>`.
- `~/.config/herdr/config.toml` is linked from the repository, but the rest of
  `~/.config/herdr` is runtime state. Never link the whole directory, or herdr
  will write sockets into the repo and `nix flake` will fail on them.
