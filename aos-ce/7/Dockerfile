FROM alpine/git:latest AS sources

ARG AOS_VERSION=master
ARG WEBAPP_VERSION=${AOS_VERSION}

ARG ADDITIONAL_MODULES

RUN git clone https://github.com/axelor/open-suite-webapp.git -b ${WEBAPP_VERSION} /webapp && \
    git clone https://github.com/axelor/axelor-open-suite.git -b ${AOS_VERSION} /webapp/modules/axelor-open-suite && \
    chmod +x /webapp/gradlew

RUN for module in $ADDITIONAL_MODULES; do \
    if echo "$module" | grep -q "|"; then \
    url=$(echo "$module" | cut -d'|' -f1); \
    branch=$(echo "$module" | cut -d'|' -f2); \
    name=$(basename "$url" .git); \
    git clone "$url" -b "$branch" "/webapp/modules/$name"; \
    else \
    name=$(basename "$module" .git); \
    git clone "$module" "/webapp/modules/$name"; \
    fi; \
    done

FROM eclipse-temurin:11-jdk AS builder

COPY --from=sources /webapp /app
WORKDIR /app

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends unzip && \
    ./gradlew --no-daemon -xtest -xcheck -xspotlessApply build && \
    mkdir -p /app/webapps/ROOT && \
    unzip -q -o /app/build/libs/*.war -d /app/webapps/ROOT/ && \
    mkdir -p /app/reports && \
    if ls /app/build/libs/*-reports.zip 1> /dev/null 2>&1; then unzip -q -o /app/build/libs/*-reports.zip -d /app/reports/; fi && \
    rm -rf /var/lib/apt/lists/*

FROM alpine:3.22 AS runner

ARG UID=1000
ARG GID=1000

ARG TOMCAT_VERSION=9.0.100
ARG BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

ENV USER=axelor
ENV HOME=/home/${USER}

ENV JAVA_OPTS="-Daxelor.ScriptCacheSize=500 -Daxelor.ScriptCacheExpireTime=10"

ENV CATALINA_OPTS="-server"

# Refresh repositories and install tools needed by the entrypoint
RUN apk update && \
    apk add --no-cache htop vim bash bash-completion curl coreutils openjdk11-jdk

# Install fontconfig (required for excel support)
RUN apk add --no-cache fontconfig ttf-dejavu

ENV TZ=Europe/Paris
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Set timezone
RUN apk add --no-cache musl musl-utils musl-locales tzdata && \
    cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo "${TZ}" > /etc/timezone

RUN addgroup -g ${GID} -S ${USER} && \
    adduser -u ${UID} -S -G ${USER} -h ${HOME} -s /bin/bash ${USER}

RUN mkdir /data
RUN chown -R ${USER}:${USER} /data

USER ${USER}

ENV CATALINA_HOME="${HOME}/tomcat"
ENV CATALINA_BASE="${HOME}/tomcat"
ENV PATH="${CATALINA_HOME}/bin:${PATH}"
WORKDIR ${CATALINA_HOME}

RUN export TOMCAT_MINOR_VERSION=$(echo ${TOMCAT_VERSION} | cut -d"." -f 1) && \
    mkdir -p ${CATALINA_HOME} && \
    curl -L https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MINOR_VERSION}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz | tar xvzf - --exclude="apache-tomcat*/webapps/*" --strip-components=1 --directory=${CATALINA_HOME}

# Remove default AccessLogValve from server.xml
RUN sed -i -E ':a;N;$!ba;s/<Valve className=\"org.apache.catalina.valves.AccessLogValve\"(.|\n)*\/>//' ${CATALINA_HOME}/conf/server.xml

# Add HealthCheckValve to server.xml inside <Host> tag at the end
RUN sed -i -E '/<\/Host>/i <Valve className="org.apache.catalina.valves.HealthCheckValve" />' ${CATALINA_HOME}/conf/server.xml

# Create important directories
RUN mkdir ${CATALINA_HOME}/webapps ${CATALINA_HOME}/reports ${CATALINA_HOME}/scripts

# Expose ports
EXPOSE 8080

# Copy files
COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/
COPY --chmod=755 post-startup.d/* /usr/local/bin/post-startup.d/

# Copy app
COPY --from=builder --chown=${USER}:${USER} --chmod=700 /app/webapps/ ${CATALINA_HOME}/webapps/
COPY --from=builder --chown=${USER}:${USER} --chmod=700 /app/reports/ ${CATALINA_HOME}/reports/

# Label images
LABEL \
    maintainer="Axelor <support@axelor.com>" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date="${BUILD_DATE}" \
    org.label-schema.name="aos-ce" \
    org.label-schema.vendor="Axelor"

# Entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["start"]
