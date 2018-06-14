# Axelor Docker

This repository contains [docker][docker] and [docker-compose][docker-compose] files for [axelor apps][axelor].

## Prerequisite

Install `docker` & `docker-compose` as per the official [docker documentation][docker-doc].

## Build

You can build the base image like this:

```sh
docker build -t axelor/aio-base .
```

## Run app

You can use the base image to run your app.

Copy the war package of your application in current directory and start container like this:

```sh
docker run -it --name axelor-demo \
	-p 80:80 \
	-e NGINX_HOST=your.hostname.com \
	-v `pwd`/volumes/var/lib/postgresql:/var/lib/postgresql \
	-v `pwd`/volumes/var/lib/tomcat:/var/lib/tomcat \
	-v `pwd`/axelor-demo.war:/var/lib/tomcat/webapps/ROOT.war:ro \
	axelor/aio-base
```

The data will be stored under `volumes` directory.

## SSL Support

You can run the application with https.

Prepare `certs` directory with following files:

- `certs/dhparam.pem` - dhparam file
- `certs/nginx.crt` - certificate file
- `certs/nginx.key` - certificate key

and start container like this:

```sh
docker run -it --name axelor-demo \
	-p 80:80 \
	-p 443:443 \
	-e NGINX_HOST=your.hostname.com \
	-e NGINX_PORT=443 \
	-v `pwd`/certs:/etc/nginx/certs:ro \
	-v `pwd`/volumes/var/lib/postgresql:/var/lib/postgresql \
	-v `pwd`/volumes/var/lib/tomcat:/var/lib/tomcat \
	-v `pwd`/axelor-demo.war:/var/lib/tomcat/webapps/ROOT.war:ro \
	axelor/aio-base
```

## Next?

This is still very early work. We are going to make it official docker image
for production deployment.

In the meantime, follow the [docker documentation][docker-doc] to get familiar with it.

[axelor]: https://www.axelor.com/
[docker]: https://www.docker.com/
[docker-doc]: https://docs.docker.com/
[docker-compose]: https://docs.docker.com/compose/
