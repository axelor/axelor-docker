#!/bin/sh

APP_USER="${APP_USER:-admin}"
APP_PASS="${APP_PASS:-admin}"

PGHOST="${PGHOST:-postgres}"
PGPORT="${PGPORT:-5432}"
PGUSER="${PGUSER:-axelor}"
PGPASSWORD="${PGPASSWORD:-axelor}"
PGDATABASE="${PGDATABASE:-axelor}"

APP_LANGUAGE="${APP_LANGUAGE:-en}"
APP_DEMO_DATA="${APP_DEMO_DATA:-false}"
APP_MODE="${APP_MODE:-dev}"
LOG_LEVEL="${LOG_LEVEL:-DEBUG}"
ENABLE_QUARTZ="${ENABLE_QUARTZ:-false}"

APP_DATA_BASE_DIR="/data"
APP_DATA_EXPORTS_DIR="${APP_DATA_EXPORTS_DIR:-$APP_DATA_BASE_DIR/exports}"
APP_DATA_ATTACHMENTS_DIR="${APP_DATA_ATTACHMENTS_DIR:-$APP_DATA_BASE_DIR/attachments}"

if [ ! -z "${JAVA_XMS}" ]; then
  CATALINA_OPTS="${CATALINA_OPTS} -Xms${JAVA_XMS}"
fi
if [ ! -z "${JAVA_XMX}" ]; then
  CATALINA_OPTS="${CATALINA_OPTS} -Xmx${JAVA_XMX}"
fi

mkdir -p ${APP_DATA_EXPORTS_DIR} ${APP_DATA_ATTACHMENTS_DIR}

wait_for_postgres() {
  retries=5
  until psql --command "SELECT 1" > /dev/null 2>&1 || [ ${retries} -eq 0 ]; do
    echo "Waiting for postgres server, ${retries} remaining attempts..."
    retries=$((retries-1))
    sleep 3
  done

  if [ ${retries} -eq 0 ]; then
    echo "Impossible to contact PostgreSQL"
  else
    echo "Postgresql Ready"
  fi
}

init_postgres() {
  if [ -z "`psql -t --command "SELECT extname FROM pg_extension WHERE extname = 'unaccent'"`" ]; then
    echo "Configuring app:database 🔧"
    psql --command "CREATE EXTENSION IF NOT EXISTS unaccent"
  fi
}

update_properties() {
  echo "Configuring app:properties 🔧"

  APP_PROP_FILE_PATH="${CATALINA_HOME}/webapps/ROOT/WEB-INF/classes/axelor-config.properties"

  # keep the name defined in the property file if no explicit name is provided in env variables
  if [ ! -z "${APP_NAME}" ]; then
    findAndReplace "application.name" "${APP_NAME}" ${APP_PROP_FILE_PATH}
  fi

  if [ ! -z "${APP_LOAD_APPS}" ]; then
    findAndReplace "studio.apps.install" "${APP_LOAD_APPS}" ${APP_PROP_FILE_PATH}
  fi
  findAndReplace "application.mode" "${APP_MODE}" ${APP_PROP_FILE_PATH}
  findAndReplace "data.export.dir" "${APP_DATA_EXPORTS_DIR}" ${APP_PROP_FILE_PATH}
  findAndReplace "application.locale" "${APP_LANGUAGE}" ${APP_PROP_FILE_PATH}
  findAndReplace "data.import.demo-data" "${APP_DEMO_DATA}" ${APP_PROP_FILE_PATH}
  findAndReplace "data.upload.dir" "${APP_DATA_ATTACHMENTS_DIR}" ${APP_PROP_FILE_PATH}
  findAndReplace "reports.design.dir" "${CATALINA_HOME}/reports" ${APP_PROP_FILE_PATH}
  findAndReplace "db.default.ddl" "update" ${APP_PROP_FILE_PATH}
  findAndReplace "db.default.driver" "org.postgresql.Driver" ${APP_PROP_FILE_PATH}
  findAndReplace "db.default.password" "${PGPASSWORD}" ${APP_PROP_FILE_PATH}
  findAndReplace "db.default.url" "jdbc:postgresql://${PGHOST}:${PGPORT}/${PGDATABASE}" ${APP_PROP_FILE_PATH}
  findAndReplace "db.default.user" "${PGUSER}" ${APP_PROP_FILE_PATH}
  findAndReplace "hibernate.hikari.maximumPoolSize" "50" ${APP_PROP_FILE_PATH}
  findAndReplace "hibernate.hikari.idleTimeout" "600000" ${APP_PROP_FILE_PATH}
  findAndReplace "hibernate.search.default.directory_provider" "none" ${APP_PROP_FILE_PATH}
  findAndReplace "logging.level.com.axelor" "${LOG_LEVEL}" ${APP_PROP_FILE_PATH}
  findAndReplace "quartz.enable" "${ENABLE_QUARTZ}" ${APP_PROP_FILE_PATH}
  if [ "${ENABLE_QUARTZ}" == "true" ]; then
    findAndReplace "quartz.thread-count" "5" ${APP_PROP_FILE_PATH}
  fi
  findAndReplace "temp.dir" "{java.io.tmpdir}" ${APP_PROP_FILE_PATH}
  findAndReplace "encryption.password" "${ENCRYPTION_PASSWORD}" ${APP_PROP_FILE_PATH}

  if [ ! -z "$ADDITIONAL_PROPERTIES" ]; then
    echo "$ADDITIONAL_PROPERTIES" | while IFS='=' read -r key value; do
      findAndReplace "$key" "$value" ${APP_PROP_FILE_PATH}
    done
  fi
}

post_startup() {
  echo "Waiting tomcat startup... 🕒"

  export APP_URL="http://localhost:8080"
  export COOKIE_JAR="/tmp/cookies.txt"

  counter=1
  command="curl --connect-timeout 5 --fail -s -o /dev/null -w %{http_code} -X GET ${APP_URL}/ws/public/app/info"
  until [ "`eval $command`" = "200" ] || [ ${counter} -gt 30 ]; do
    echo "Waiting 20sec for Tomcat to be ready, attempt ${counter}"
    counter=$((counter+1))
    sleep 20
  done

  if [ ${counter} -gt 30 ]; then
    echo
    echo "ERROR: "
    echo "  Unable to reach instance. (code: `eval $command`)"
    echo "  It seems the app has not started or is still loading."
    echo "  Aborting... 🧨"
    echo
    exit 1
  fi

  curl -sS -o /dev/null --cookie-jar ${COOKIE_JAR} -X POST \
    -H "Content-Type:application/json" \
    -d '{"username":"'"${APP_USER}"'","password":"'"${APP_PASS}"'"}' \
    ${APP_URL}/callback

  for f in /usr/local/bin/post-startup.d/*; do
    [ -f "$f" ] && [ -x "$f" ] && "$f"
  done

  curl -sS -o /dev/null --cookie-jar ${COOKIE_JAR} --cookie ${COOKIE_JAR} -X GET \
    -H "Content-Type:application/json" \
    ${APP_URL}/logout

  rm ${COOKIE_JAR}
}

findAndReplace() {
  PROP=$1
  VALUE=$2
  FILE=$3

  if [ ! -f ${FILE} ]; then
    return
  fi

  if grep -q "^${PROP}" ${FILE}; then
    sed -i "s|^${PROP}.*|${PROP} = ${VALUE}|" ${FILE}
  else
    echo -e "\n${PROP} = ${VALUE}" >> ${FILE}
  fi
}

update_properties

if [ "$1" = "start" ]; then
  shift

  if [ ! -f ${APP_DATA_BASE_DIR}/.first_start_completed ]; then
    wait_for_postgres
    init_postgres
    touch ${APP_DATA_BASE_DIR}/.first_start_completed
    export FIRST_START=true
  fi

  post_startup &
  exec ${CATALINA_HOME}/bin/catalina.sh run
fi

exec "$@"
