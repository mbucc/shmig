FROM alpine:latest

RUN apk update && \
    apk add bash postgresql-client mysql-client sqlite && \
    apk add --update openssl

ADD shmig /bin/shmig

## SHMIG configuration
ENV TYPE mysql \
    HOST localhost \
    PORT 3389 \
    DATABASE db \
    LOGIN root \
    PASSWORD root \
    ASK_PASSWORD0 0 \
    MIGRATIONS /sql \
    MYSQL /usr/bin/mysql \
    PSQL /usr/bin/psql \
    SQLITE3 /usr/bin/sqlite3 \
    UP_MARK "====  UP  ====" \
    DOWN_MARK "==== DOWN ====" \
    COLOR auto \
    SCHEMA_TABLE shmig_version

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

