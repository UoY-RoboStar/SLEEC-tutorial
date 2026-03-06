# SLEEC-tutorial

This repository contains a Dockerfile that incorporates LEGOS-SLEEC and SLEEC-TK in a single environment that can be used from a web browser. The image targets Intel/AMD64 but can be executed on macOS under Rosetta emulation, which is enabled by default for Docker.

## Pre-requisites

* Docker (Intel/AMD64 or Apple Silicon under emulation)

## Usage
To execute the prebuilt docker image, open a terminal and use the command:
```
docker run --platform linux/amd64 -it --name sleec-tutorial -p 8080:8080 ghcr.io/uoy-robostar/sleec-tutorial:main
```
After a short while, you should then be able to open a web browser at [http://localhost:8080](http://localhost:8080) to interact with the Linux-based XFCE4 desktop environment as reproduced in the screenshot below. The window can be resized as needed.

![SLEEC environment](/img/sleec-environment.png)

### Building the Docker image (optional)
To build the Docker image in this repository from scratch use the command:
```
docker build --platform linux/amd64 -t sleec-tutorial .
```

### SLEEC-TK
To use SLEEC-TK for analysis, you should, first of all, setup the CSP model-checker [FDR4](https://cocotec.io/fdr/) following the instructions below.

#### Install and activate FDR4
To setup FDR4, click on the shortcut in the desktop named `FDR4 (Launch or Install)`. A terminal will open, and if FDR is not yet installed it will be automatically installed. At the end, press Enter to launch FDR and proceed to obtain a license following the instructions on the screen. You can then close the FDR window that appears afterwards.

#### Running SLEEC-TK
To run SLEEC-TK, double-click on the `SLEEC-TK` shortcut on the desktop. The Eclipse launcher will appear, followed by a dialog asking for selecting a workspace path. You can accept the default `/home/sleec/eclipse-workspace` by clicking on `Launch`.
