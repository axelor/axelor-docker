#!/bin/bash

if [ -z "${FIRST_START}" ]; then
    echo "Restoring meta... 🔁"

    curl -sS -o /dev/null --cookie-jar ${COOKIE_JAR} --cookie ${COOKIE_JAR} -X POST \
        -H "Content-Type:application/json" \
        -d '{"action":"action-meta-restore-all","model":"com.axelor.meta.db.MetaView"}' \
        ${APP_URL}/ws/action
fi
