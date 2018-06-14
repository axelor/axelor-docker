# All-in-One : Axelor ERP

The Dockerfile to build All-in-One docker image of Axelor ERP.

## Build Image

```sh
$ docker build -t axelor/aio-erp .
```

## Run app container

```sh
$ docker run -it -p 8080:80 axelor/aio-erp
```

## Run with SSL

```sh
$ docker run -it -v /path/to/your/certs:/etc/nginx/certs -p 80:80 -p 443:443 axelor/aio-erp
```

The `certs` directory should contain certificates with following names:

* `nginx.key` - the key file
* `nginx.crt` - the certificate file
* `dhparam.pem` - the dhparam file

## Custom app config

The image uses default `application.properties` from ABS source. You can provide your own
configuration file as bellow:

```sh
$ docker run -it -v /path/to/application.properties:/application.properties -p 8080:80 axelor/aio-erp
```

## Other Options

The docker image exposes following ports:

* `80` - nginx http port
* `443` - nginx https port
* `8080` - tomcat http port
* `5432` - postgresql port

The docker image exposes following volumes:

* `/var/lib/tomcat` - tomcat base directory
* `/var/lib/postgresql` - postgresql data directory
* `/var/log/tomcat` - tomcat log files
* `/var/log/postgresql` - postgresql log files

Following environment variables can be used to change container settings:

* `NGINX_HOST` - the public host name (default: localhost)
* `NGINX_PORT` - the public port (default: 443)
* `POSTGRES_USER` - the postgresql user name (default: axelor)
* `POSTGRES_PASSWORD` - the postgresql user password (default: axelor)
* `POSTGRES_DB` - the postgresql database name (default: axelor)
