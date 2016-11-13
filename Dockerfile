FROM alpine
RUN apk update
RUN apk add bash
RUN apk add postgresql-client
RUN apk add mysql-client
RUN apk add sqlite
RUN apk add --update openssl

RUN wget -O /bin/shmig https://raw.githubusercontent.com/naquad/shmig/master/shmig
RUN chmod +x /bin/shmig

## SHMIG configuration
ENV TYPE mysql
ENV HOST localhost
ENV PORT 3389
ENV DATABASE db
ENV LOGIN root
ENV PASSWORD ''
ENV ASK_PASSWORD0 0
ENV MIGRATIONS "/sql"
ENV MYSQL "/usr/bin/mysql"
ENV PSQL "/usr/bin/psql"
ENV SQLITE3 "/usr/bin/sqlite3"
ENV UP_MARK="====  UP  ===="
ENV DOWN_MARK="==== DOWN ===="
ENV COLOR auto
ENV SCHEMA_TABLE shmig_version

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]