#!/usr/bin/env bash
set -e

start_nginx() {
	service nginx start
}

start_postgres() {

	if [ -s "$PGDATA/PG_VERSION" ]; then
		# start postgres
		service postgresql start
	else
		# initialize postgresql
		mkdir -p $PGDATA
		mkdir -p /var/log/postgresql

		chown -R postgres:postgres $PGDATA
		chown -R postgres:postgres /var/log/postgresql

		gosu postgres initdb --username=postgres
		echo "host all all all md5" >> $PGDATA/pg_hba.conf \
		echo "listen_addresses='localhost'" >> $PGDATA/postgresql.conf

		# start postgres
		service postgresql start

		local PSQL="gosu postgres psql"

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
		cp $CATALINA_HOME/conf/tomcat-users.xml $CATALINA_BASE/conf/ \
		cp $CATALINA_HOME/conf/logging.properties $CATALINA_BASE/conf/ \
		cp $CATALINA_HOME/conf/server.xml $CATALINA_BASE/conf/ \
		cp $CATALINA_HOME/conf/web.xml $CATALINA_BASE/conf/ \
		sed -i 's/directory="logs"/directory="\/var\/log\/tomcat"/g' $CATALINA_BASE/conf/server.xml \
		sed -i 's/\${catalina.base}\/logs/\/var\/log\/tomcat/g' $CATALINA_BASE/conf/logging.properties \
		chown -R $TOMCAT_USER:$TOMCAT_GROUP $CATALINA_BASE
		chown -R $TOMCAT_USER:$TOMCAT_GROUP /var/log/tomcat
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

