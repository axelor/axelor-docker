FROM debian:stretch as builder

RUN set -ex \
	&& DEBIAN_FRONTEND=noninteractive apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y \
		curl dpkg-dev gcc libapr1-dev libssl-dev make \
	&& rm -rf /var/lib/apt/lists/*

# jdk
ENV JAVA_HOME /opt/java/default
ENV JAVA_OPTS "-Djava.awt.headless=true -XX:+UseConcMarkSweepGC"

# get details from https://api.adoptopenjdk.net/v2/info/releases/openjdk8?openjdk_impl=hotspot&os=linux&arch=x64&type=jdk
RUN set -ex \
	&& export JAVA_ESUM="19c91906c220c8eac38179fb661a810c451779a65b8be530c1d98e15b6bb2673" \
	&& export JAVA_PKG="openjdk.tar.gz" \
	&& mkdir -p /opt/java \
	&& cd /opt/java \
	&& curl -Lso "$JAVA_PKG" "https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u192-b12/OpenJDK8U-jdk_x64_linux_hotspot_8u192b12.tar.gz" \
	&& echo "$JAVA_ESUM $JAVA_PKG" | sha256sum -c - \
	&& tar -xf $JAVA_PKG \
	&& rm -f $JAVA_PKG \
	&& cd - \
	&& export JAVA_DIR=$(ls -1 -d /opt/java/*) \
	&& ln -s $JAVA_DIR /opt/java/latest \
	&& ln -s $JAVA_DIR /opt/java/default

# tomcat
ENV CATALINA_HOME /opt/tomcat/default
ENV CATALINA_BASE /var/lib/tomcat

RUN set -ex \
	&& export TOMCAT_MAJOR="8" \
	&& export TOMCAT_VERSION="8.5.35" \
	&& export TOMCAT_ESUM="1084c067eec2bd27ed2aa5a3729cdc27d0beddbc41968a7004754e75dd88a6703f5fc0e3a01f262cfe2b5d13ed58c95dca1c43bc5ae8789141a11e11f72edd89" \
	&& export TOMCAT_PKG="apache-tomcat-$TOMCAT_VERSION.tar.gz" \
	&& mkdir /opt/tomcat \
	&& cd /opt/tomcat \
	&& curl -L -O "https://www.apache.org/dyn/closer.cgi?action=download&filename=tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/$TOMCAT_PKG" \
	&& echo "$TOMCAT_ESUM $TOMCAT_PKG" | sha512sum -c - \
	&& tar -xf $TOMCAT_PKG \
	&& rm -f $TOMCAT_PKG \
	&& cd - \
	&& export TOMCAT_DIR=$(ls -1 -d /opt/tomcat/*) \
	&& ln -s $TOMCAT_DIR /opt/tomcat/latest \
	&& ln -s $TOMCAT_DIR /opt/tomcat/default \
	&& chmod 755 $TOMCAT_DIR/bin \
	&& chmod 755 $TOMCAT_DIR/lib \
	&& chmod 755 $TOMCAT_DIR/conf \
	&& chmod 644 $TOMCAT_DIR/bin/* \
	&& chmod 644 $TOMCAT_DIR/lib/* \
	&& chmod 644 $TOMCAT_DIR/conf/* \
	&& chmod 755 $TOMCAT_DIR/bin/*.sh \
	&& chown root:$TOMCAT_GROUP $TOMCAT_DIR/conf/* \
	&& mkdir -p $CATALINA_BASE/conf \
	&& mkdir -p $CATALINA_BASE/temp \
	&& mkdir -p $CATALINA_BASE/webapps \
	&& cp $CATALINA_HOME/conf/tomcat-users.xml $CATALINA_BASE/conf/ \
	&& cp $CATALINA_HOME/conf/logging.properties $CATALINA_BASE/conf/ \
	&& cp $CATALINA_HOME/conf/server.xml $CATALINA_BASE/conf/ \
	&& cp $CATALINA_HOME/conf/web.xml $CATALINA_BASE/conf/ \
	&& sed -i 's/directory="logs"/directory="\/var\/log\/tomcat"/g' $CATALINA_BASE/conf/server.xml \
	&& sed -i 's/\${catalina\.base}\/logs/\/var\/log\/tomcat/g' $CATALINA_BASE/conf/logging.properties

# tomcat-native lib path
ENV TOMCAT_NATIVE_LIBDIR $CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR

# build tomcat-native
RUN set -ex \
	&& export NATIVE_BUILD_DIR="$(mktemp -d)" \
	&& tar -xvf $CATALINA_HOME/bin/tomcat-native.tar.gz -C "$NATIVE_BUILD_DIR" --strip-components=1 \
	&& cd $NATIVE_BUILD_DIR/native \
	&& ./configure \
		--build="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
		--libdir="$TOMCAT_NATIVE_LIBDIR" \
		--prefix="$CATALINA_HOME" \
		--with-apr="$(which apr-1-config)" \
		--with-java-home="$JAVA_HOME" \
		--with-ssl=yes \
	&& make -j "$(nproc)" \
	&& make install \
	&& rm -f $CATALINA_HOME/bin/*.bat \
	&& rm -f $CATALINA_HOME/bin/*.tar.gz \
	&& rm -rf $NATIVE_BUILD_DIR

## end of builder stage

FROM debian:stretch
LABEL maintainer="Axelor <support@axelor.com>"

RUN set -ex \
	&& DEBIAN_FRONTEND=noninteractive apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y gnupg dirmngr apt-transport-https \
	&& apt-key adv --fetch-keys http://nginx.org/keys/nginx_signing.key \
	&& echo "deb http://nginx.org/packages/debian/ stretch nginx" >> /etc/apt/sources.list \
	&& apt-key adv --fetch-keys https://www.postgresql.org/media/keys/ACCC4CF8.asc \
	&& echo 'deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
	&& apt-key adv --fetch-keys https://deb.nodesource.com/gpgkey/nodesource.gpg.key \
	&& echo 'deb https://deb.nodesource.com/node_8.x stretch main' > /etc/apt/sources.list.d/nodesource.list \
	&& apt-key adv --fetch-keys https://dl.yarnpkg.com/debian/pubkey.gpg \
	&& echo 'deb https://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list \
	&& DEBIAN_FRONTEND=noninteractive apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y \
		supervisor gosu postgresql-9.6 postgresql-contrib-9.6 \
		libapr1 nginx gettext-base \
		git-core nodejs yarn \
	&& rm -rf /var/lib/apt/lists/*

# update locale
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# jdk
ENV JAVA_HOME /opt/java/default
ENV JAVA_OPTS "-Djava.awt.headless=true -XX:+UseConcMarkSweepGC"

# tomcat
ENV TOMCAT_USER tomcat
ENV TOMCAT_GROUP tomcat

ENV CATALINA_HOME /opt/tomcat/default
ENV CATALINA_BASE /var/lib/tomcat

# copy from builder
COPY --from=builder /opt /opt
COPY --from=builder /var/lib/tomcat $CATALINA_BASE

RUN set -ex \
	&& addgroup --system "$TOMCAT_GROUP" --quiet \
	&& adduser \
		--system --home "$CATALINA_BASE" --no-create-home \
		--ingroup "$TOMCAT_GROUP" --disabled-password --shell /bin/false "$TOMCAT_USER"

RUN set -ex \
	&& update-alternatives --install /usr/bin/java java $JAVA_HOME/bin/java 20000 \
	&& update-alternatives --install /usr/bin/javac javac $JAVA_HOME/bin/javac 20000 \
	&& update-alternatives --install /usr/bin/jar jar $JAVA_HOME/bin/jar 20000 \
	&& update-alternatives --install /usr/bin/tomcat tomcat $CATALINA_HOME/bin/catalina.sh 20000 \
	&& update-alternatives --install /usr/bin/tomcat-digest tomcat-digest $CATALINA_HOME/bin/digest.sh 20000 \
	&& update-alternatives --install /usr/bin/tomcat-tool-wrapper tomcat-tool-wrapper $CATALINA_HOME/bin/tool-wrapper.sh 20000 \
	&& chown root:$TOMCAT_GROUP $CATALINA_HOME/conf/* \
	&& mkdir -p /var/log/tomcat \
	&& mkdir -p $CATALINA_BASE/{} \
	&& chown -R $TOMCAT_USER:$TOMCAT_GROUP $CATALINA_BASE \
	&& chown -R $TOMCAT_USER:$TOMCAT_GROUP /var/log/tomcat

# tomcat-native lib path
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$CATALINA_HOME/native-jni-lib

# postgres
ENV POSTGRES_USER axelor
ENV POSTGRES_PASSWORD axelor
ENV POSTGRES_DB axelor

ENV PATH $PATH:/usr/lib/postgresql/9.6/bin
ENV PGDATA /var/lib/postgresql/9.6/main

RUN set -ex \
	&& echo "host all all all md5" >> /etc/postgresql/9.6/main/pg_hba.conf \
	&& echo "listen_addresses='localhost'" >> /etc/postgresql/9.6/main/postgresql.conf \
	&& rm -rf /var/lib/postgresql/9.6/main \
	&& mkdir -p /var/lib/postgresql/9.6 \
	&& chown -R postgres:postgres /var/lib/postgresql

# nginx
ENV NGINX_HOST localhost
ENV NGINX_PORT 443

COPY nginx.conf /etc/nginx/conf.d.templates/
COPY nginx-ssl.conf /etc/nginx/conf.d.templates/

VOLUME ["/var/lib/tomcat", "/var/lib/postgresql", "/var/log/tomcat", "/var/log/postgresql"]

EXPOSE 80 443 8080 5432

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && mkdir /docker-entrypoint-initdb.d

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["start"]
