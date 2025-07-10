# Axelor Dockerfiles

This repository provides [Dockerfiles](https://docs.docker.com/engine/reference/builder/) and samples to build [Docker](https://www.docker.com/what-docker) images for [Axelor](https://axelor.com) apps.

## AOS Community Edition

For the latest and maintained Docker configuration, please refer to:
- [AOS Community Edition README](./aos-ce/README.md)

## Legacy AIO Images (Deprecated)

**Warning: The following AIO (All-In-One) images are deprecated and should not be used for new projects.**

The `aio-base`, `aio-builder`, and `aio-erp` images are no longer maintained. Please migrate to the AOS Community Edition setup documented above.

### Build Images (Deprecated)

It assumes you have Docker installed on your system.

#### Build base image

```sh
$ cd aio-base
$ docker build -t axelor/aio-base .
```

#### Build builder image

```sh
$ cd aio-builder
$ docker build -t axelor/aio-builder .
```

#### Build app image

```sh
$ cd aio-erp
$ docker build -t axelor/aio-erp .
```

### Run app container

Once app image is built, you can run it like this:

```sh
$ docker run -it -p 8080:80 axelor/aio-erp
```

Once app completes database initialization, it can be access at: http://localhost:8080

