Once basic files are set run only once:

```bash
sudo nix run nix-darwin -- switch --flake ~/.dotfiles 
```

After that run `./rebuild.sh`

Check the nix config:
```bash
nix flake check --no-build
```
