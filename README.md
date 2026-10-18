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
