# All-in-One : Axelor Builder

The Dockerfile to build All-in-One docker image of build Axelor Apps.

The image includes OpenJDK8 from AdoptOpenJDK, Node.js 8.x and Yarn.

The image also caches build dependencies of the latest Axelor ERP
so that we can rebuild the ERP with same dependencies.

## Build Image

```sh
$ docker build -t axelor/aio-builder .
```

## Build App

```sh
$ docker run --rm -it -v /path/to/app-source:/src -w /src axelor/aio-builder \
	./gradlew -x test build
```

For example, to build Axelor ERP:

```
$ docker run --rm -it -v `pwd`/abs-webapp:/src -w /src axelor/aio-builder \
	./gradlew -x test build
```

