# LaTeX experiments

[![GitHub Actions Status](https://github.com/rudenkornk/latex_experiments/actions/workflows/workflow.yml/badge.svg)](https://github.com/rudenkornk/latex_experiments/actions)

A simple template for LaTeX projects

## Build
### Option 1: Use docker container with all required packages installed
```bash
make in_docker TARGET=main
```

### Option 2: Use docker container interactively
```bash
make container
docker attach latex_experiments_container
make main
```

### Option 3: config your system with provided scripts
Config your system [using provided scripts from docker repo](https://github.com/rudenkornk/docker_latex#3-use-scripts-from-this-repository-to-setup-your-own-system) and run:
```bash
make main
```
