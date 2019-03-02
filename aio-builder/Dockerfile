FROM adoptopenjdk/openjdk8
LABEL maintainer="Axelor <support@axelor.com>"

RUN set -ex \
	&& DEBIAN_FRONTEND=noninteractive apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y gnupg dirmngr apt-transport-https locales \
	&& apt-key adv --batch --fetch-keys https://deb.nodesource.com/gpgkey/nodesource.gpg.key \
	&& echo 'deb https://deb.nodesource.com/node_8.x bionic main' > /etc/apt/sources.list.d/nodesource.list \
	&& apt-key adv --batch --fetch-keys https://dl.yarnpkg.com/debian/pubkey.gpg \
	&& echo 'deb https://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list \
	&& DEBIAN_FRONTEND=noninteractive apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y \
		git-core nodejs yarn \
	&& rm -rf /var/lib/apt/lists/*

# update locale
RUN set -ex && \
	echo 'en_GB.UTF-8 UTF-8' >> /etc/locale.gen && \
	echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && locale-gen
ENV LANG en_US.utf8

# jdk
ENV JAVA_HOME /opt/java/openjdk

RUN set -ex \
	&& update-alternatives --install /usr/bin/java java $JAVA_HOME/bin/java 20000 \
	&& update-alternatives --install /usr/bin/javac javac $JAVA_HOME/bin/javac 20000 \
	&& update-alternatives --install /usr/bin/jar jar $JAVA_HOME/bin/jar 20000

RUN \
  set -ex && \
  mkdir -p /app/src && cd /app/src && \
  git clone https://github.com/axelor/axelor-development-kit.git && \
  cd axelor-development-kit && \
  ./gradlew --no-daemon -x test build

RUN \
  set -ex && \
  cd /app/src && \
  git clone https://github.com/axelor/abs-webapp.git axelor-erp && \
  sed -e 's|git@github.com:|https://github.com/|' -i axelor-erp/.gitmodules && \
  cd axelor-erp && \
  git checkout master && \
  git submodule sync && \
  git submodule init && \
  git submodule update && \
  git submodule foreach git checkout master && \
  git submodule foreach git pull origin master && \
  sed -e 's|^application.theme.*|application.theme = modern|g' -i src/main/resources/application.properties && \
  ./gradlew --no-daemon -x test npm-build build && \
  find ~/.gradle -type d -name "com.axelor" | xargs rm -rf && \
  find ~/.gradle -type f -name "axelor-*.jar" -delete && \
  rm -rf /app

