FROM alpine/git:latest AS sources

ARG AOS_VERSION=8.5-dev
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

FROM debian:trixie-slim AS runner

ARG UID=1000
ARG GID=1000

ARG TOMCAT_VERSION=9.0.113
ARG BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

ENV USER=axelor
ENV HOME=/home/${USER}

ENV JAVA_OPTS="-Daxelor.ScriptCacheSize=500 -Daxelor.ScriptCacheExpireTime=10"

ENV CATALINA_OPTS="-server"

# Refresh repositories and install tools needed by the entrypoint
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        htop vim bash bash-completion curl coreutils \
        fontconfig fonts-dejavu-core \
        postgresql-client ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install Temurin JDK 11
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"
RUN curl -fsSL https://api.adoptium.net/v3/binary/latest/11/ga/linux/x64/jdk/hotspot/normal/eclipse -o /tmp/jdk.tar.gz && \
    mkdir -p ${JAVA_HOME} && \
    tar -xzf /tmp/jdk.tar.gz -C ${JAVA_HOME} --strip-components=1 && \
    rm /tmp/jdk.tar.gz

ENV TZ=Europe/Paris
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Set locale and timezone
RUN apt-get update && \
    apt-get install -y --no-install-recommends locales tzdata && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen && \
    ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo "${TZ}" > /etc/timezone

RUN groupadd -g ${GID} ${USER} && \
    useradd -u ${UID} -g ${USER} -d ${HOME} -m -s /bin/bash ${USER}

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
RUN mkdir -p ${CATALINA_HOME}/webapps ${CATALINA_HOME}/reports ${CATALINA_HOME}/scripts

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
