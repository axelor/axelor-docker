#!/usr/bin/env bash
set -e

start_nginx() {
	local conf=nginx.conf
	[ -e /etc/nginx/certs/nginx.crt -a \
	  -e /etc/nginx/certs/nginx.key -a \
	  -e /etc/nginx/certs/dhparam.pem ] && conf=nginx-ssl.conf
	envsubst '$NGINX_HOST $NGINX_PORT' < /etc/nginx/conf.d.templates/${conf} > /etc/nginx/conf.d/default.conf
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
		[ -e $PGDATA/pg_hba.conf ] && echo "host all all all md5" >> $PGDATA/pg_hba.conf
		[ -e $PGDATA/postgresql.conf ] && echo "listen_addresses='localhost'" >> $PGDATA/postgresql.conf

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
	if [ -f "$CATALINA_BASE/app.properties" ]; then
		JAVA_OPTS="-Daxelor.config=$CATALINA_BASE/app.properties $JAVA_OPTS" gosu tomcat tomcat run
	else
		gosu tomcat tomcat run
	fi
}

prepare_app() {

	# ensure tomcat specific dirs exist
	mkdir -p /var/log/tomcat
	mkdir -p $CATALINA_BASE/{conf,temp,webapps}

	# prepare tomcat base
	if [ ! -f $CATALINA_BASE/conf/server.xml ]; then
		mkdir -p $CATALINA_BASE/{conf,temp,webapps}
		cp $CATALINA_HOME/conf/tomcat-users.xml $CATALINA_BASE/conf/
		cp $CATALINA_HOME/conf/logging.properties $CATALINA_BASE/conf/
		cp $CATALINA_HOME/conf/server.xml $CATALINA_BASE/conf/
		cp $CATALINA_HOME/conf/web.xml $CATALINA_BASE/conf/
		sed -i 's/directory="logs"/directory="\/var\/log\/tomcat"/g' $CATALINA_BASE/conf/server.xml
		sed -i 's/\${catalina.base}\/logs/\/var\/log\/tomcat/g' $CATALINA_BASE/conf/logging.properties
	fi

	# prepare config file and save it as app.properties
	(
		cd $CATALINA_BASE; \
		[ ! -e axelor-config.properties -a -e webapps/ROOT.war ] \
			&& jar xf webapps/ROOT.war WEB-INF/classes/axelor-config.properties \
			&& mv WEB-INF/classes/axelor-config.properties . \
			&& rm -rf WEB-INF;
		[ ! -e app.properties -a -e axelor-config.properties ] \
			&& cp axelor-config.properties app.properties \
			&& echo >> app.properties \
			&& echo "application.mode = prod" >> app.properties \
			&& echo "db.default.url = jdbc:postgresql://localhost:5432/$POSTGRES_DB" >> app.properties \
			&& echo "db.default.user = axelor" >> app.properties \
			&& echo "db.default.password = axelor" >> app.properties;
		exit 0;
	)

	# ensure proper permissions
	( chown -hfR $TOMCAT_USER:adm /var/log/tomcat || exit 0 )
	( chown -hfR $TOMCAT_USER:$TOMCAT_GROUP $CATALINA_BASE || exit 0 )

	# copy static files in a separate directory for nginx
	(
		cd $CATALINA_BASE/webapps; \
		[ ! -d static -a -e ROOT.war ] \
			&& mkdir -p static \
			&& cd static \
			&& jar xf ../ROOT.war css js img ico lib dist partials \
			&& cd .. \
			&& chown -R tomcat:nginx static;
		exit 0;
	)
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
