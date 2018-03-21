#!/usr/bin/env bash
set -e

start_nginx() {
	service nginx start
}

start_postgres() {

	# initialize postgresql
	if [ ! -s "$PGDATA/PG_VERSION" ]; then
		mkdir -p $PGDATA
		chown -R postgres:postgres $PGDATA
		gosu postgres initdb --username=postgres
		echo "host all all all md5" >> $PGDATA/pg_hba.conf \
		echo "listen_addresses='localhost'" >> $PGDATA/postgresql.conf
	fi

	# start postgres
	service postgresql start

	if [[ ! -f /var/lib/postgresql/.init_done ]]; then

		PSQL="gosu postgres psql"

		# create user
		if [ "$POSTGRES_USER" = 'postgres' ]; then
			$PSQL --command "ALTER USER $POSTGRES_USER WITH SUPERUSER PASSWORD '$POSTGRES_PASSWORD'"
		else
			$PSQL --command "CREATE USER $POSTGRES_USER WITH SUPERUSER PASSWORD '$POSTGRES_PASSWORD'"
		fi

		# create db
		if [ "$POSTGRES_DB" != 'postgres' ]; then
			$PSQL --command "CREATE DATABASE $POSTGRES_DB WITH OWNER '$POSTGRES_USER'"
		fi

		for f in /docker-entrypoint-initdb.d/*; do
			case "$f" in
				*.sh)     echo "$0: running $f"; . "$f" ;;
				*.sql)    echo "$0: running $f"; $PSQL -U $POSTGRES_USER -d $POSTGRES_DB -f "$f"; echo ;;
				*.sql.gz) echo "$0: running $f"; gunzip -c "$f" | $PSQL -U $POSTGRES_USER -d $POSTGRES_DB; echo ;;
				*)        echo "$0: ignoring $f" ;;
			esac
			echo
		done

		touch /var/lib/postgresql/.init_done
	fi
}

start_tomcat() {
	cd $CATALINA_BASE

	if [[ -f $CATALINA_BASE/application.properties ]]; then
		export JAVA_OPTS="-Daxelor.config=$CATALINA_BASE/application.properties $JAVA_OPTS"
	fi

	gosu tomcat tomcat run
}

prepare_app() {
	# tomcat base
	if [[ ! -d $CATALINA_BASE/conf ]]; then
		mkdir -p $CATALINA_BASE/{conf,temp,webapps}
		cp $CATALINA_HOME/conf/server.xml $CATALINA_BASE/conf/
		cp $CATALINA_HOME/conf/web.xml $CATALINA_BASE/conf/
		chown -R $TOMCAT_USER:$TOMCAT_GROUP $CATALINA_BASE
	fi
}

if [ "$1" = "start" ]; then
	shift
	prepare_app
	start_nginx
	start_postgres
	start_tomcat
fi

# Else default to run whatever the user wanted like "bash"
exec "$@"

