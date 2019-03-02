# Axelor Dockerfiles

This repository provides [Dockerfiles](https://docs.docker.com/engine/reference/builder/) and samples to build [Docker](https://www.docker.com/what-docker) images for [Axelor](https://axelor.com) apps.

## Build Images

It assumes you have Docker installed on your system.

### Build base image

```sh
$ cd aio-base
$ docker build -t axelor/aio-base .
```

### Build builder image

```sh
$ cd aio-builder
$ docker build -t axelor/aio-builder .
```

### Build app image

```sh
$ cd aio-erp
$ docker build -t axelor/aio-erp .
```

## Run app container

Once app image is built, you can run it like this:

```sh
$ docker run -it -p 8080:80 axelor/aio-erp
```

Once app completes database initialization, it can be access at: http://localhost:8080

