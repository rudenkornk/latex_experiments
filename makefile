SHELL = /usr/bin/env bash

PROJECT_NAME := latex_experiments
BUILD_DIR := __build__
BUILD_ABS_DIR := $(abspath $(BUILD_DIR))
VERSION:= 1.0.0

include src/makefile
