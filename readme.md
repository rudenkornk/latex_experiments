# LaTeX experiments

A template and an example for LaTeX projects.

## Build

### Option 1: Use container with all the required packages installed

**Requirements:** `podman >= 3.4.4` or `docker >= 24.0.1`

```bash
podman run --interactive --tty --detach \
  --env "TERM=xterm-256color" `# colored terminal` \
  --mount type=bind,source="$(pwd)",target="$(pwd)" `# mount your repo` \
  --mount type=bind,source="$HOME/.cache",target="$HOME/.cache" `# mount cache` \
  --name latex \
  --userns keep-id `# keeps your non-root username` \
  --workdir "$HOME" `# podman sets homedir to the workdir for some reason` \
  ghcr.io/rudenkornk/latex_ubuntu:22.0.7
podman exec --user root latex bash -c "chown $(id --user):$(id --group) $HOME"
podman exec --workdir "$(pwd)" --interactive --tty latex bash
```

```bash
make
```

### Option 2: config your system manually

Deterministic list of requirements exists, but not specified.
You can refer to the [container description](https://github.com/rudenkornk/latex_image) and install similar packages.

```bash
make
```

## Clean

```bash
make clean
```
