# LaTeX experiments

[![GitHub Actions Status](https://github.com/rudenkornk/latex_experiments/actions/workflows/workflow.yml/badge.svg)](https://github.com/rudenkornk/latex_experiments/actions)

A simple template for LaTeX projects

## Prerequisites for build
Run docker container with all needed packages installed:
```shell
docker run --interactive --tty \
  --user ci_user \
  --env CI_UID="$(id --user)" --env CI_GID="$(id --group)" \
  --mount type=bind,source="$(pwd)",target=/home/repo \
  rudenkornk/docker_latex:latest
```

OR

Or config your system [using provided scripts from docker repo](https://github.com/rudenkornk/docker_latex#3-use-scripts-from-this-repository-to-setup-your-own-system)

## Build
```shell
make main
```

## Clean
```shell
make clean
```
