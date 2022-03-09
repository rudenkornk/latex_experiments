# LaTeX experiments

[![GitHub Actions Status](https://github.com/rudenkornk/latex_experiments/actions/workflows/workflow.yml/badge.svg)](https://github.com/rudenkornk/latex_experiments/actions)

A simple example of LaTeX capabilities

## Build
Install drawio using steps from github workflow and run
```shell
python3 compile_drawio_images.py
```

Install texlive or use docker image (also from github workflow)
```shell
latexmk
```

docker command for local build:

```shell
sudo docker run  -it --volume <project_source>:<mount_point> ghcr.io/xu-cheng/texlive-full:latest  bash
```

