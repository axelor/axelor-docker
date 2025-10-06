#!/bin/sh

export DATABASE_URL=${DATABASE_URL:-postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}}

if [ "$1" = "start" ]; then
  shift

  exec node server.js
fi

exec "$@"