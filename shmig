#!/usr/bin/env bash

# SHMIG. Database migration tool in BASH.
# Copyright 2013 naquad <naquad@gmail.com>
# Copyright 2014 mbucciarelli <mkbucc@gmail.com>

# shellcheck disable=SC2155
# See issue #61.

# default values for variables


ME="${0##*[/\\]}"
CONFIG="./shmig.conf"
SCHEMA_TABLE="shmig_version"
CONFIG_EXPLICITLY_SET="0"
ASK_PASSWORD="0"
MIGRATIONS="./migrations"

MYSQL=$(command -v mysql)
PSQL=$(command -v psql)
SQLITE3=$(command -v sqlite3)

UP_MARK="====  UP  ===="
DOWN_MARK="==== DOWN ===="

VERSION="Version 1.1.0"

COLOR="never"

# until parsing options and figuring out color policy
# we assume color output is not used

RED=""
CYAN=""
LRED=""
LGREEN=""
LYELLOW=""
LBLUE=""
LMAGENTA=""
LCYAN=""
CLEAR=""
BOLD=""

# some helpers
warn(){
  echo -e "$ME: $*" >&2
}

die(){
  cat >&2 <<EOF
Usage: $ME [options] <action> [arguments...]
Common options:
  -d <database name>
  -t [mysql|postgresql|sqlite3]
  -h
and action is one of create, up, down, rollback, status, redo, and pending.

EOF
  [[ $# -gt 0 ]] && warn "$@"
  exit 1
}

version(){
  printf "%s\n" "$VERSION"
  exit
}

usage(){
  local output="1"

  [[ $1 -ne 0 ]] && output="2"

  cat >&"$output" <<EOF
Usage: $ME [options] <action> [arguments...]
Where options are:
  -h
      show this message

  -c FILE
      read configuration file from (default is $CONFIG)

  -t TYPE
      database type (supported are mysql, postgresql, sqlite3)

  -m DIR
      files with migrations (default is $MIGRATIONS)

  -d DATABASE
      database name

  -l LOGIN
      set database user name to connect as (not used for sqlite3)

  -H HOST
      set database host to connect to (not used for sqlite3)

  -p PASSWORD
      password to be used when connecting (not used for sqlite3)

  -P PORT
      set database port to connect to (not used for sqlite3)

  -s TABLE
      name of schema table (default is $SCHEMA_TABLE)

  -a ARGS
      additional arguments for database client passed as is

  -A
      ask for password

  -C COLOR
      set color policy. possible options:
          auto - default. will use colors if possible
          never - do not use colors
          always - always use colors
      default is $COLOR

  -V
      shows version information

Actions are:
  create <name>
      create migration file in MIGRATIONS directory

  migrate|up [steps=COUNT] [[till=]TILL]
      apply pending COUNT or till (and including) TILL migrations or all
      unless TILL or COUNT given

  down [steps=COUNT] [[till=]TILL]
      rollback migrations till (and including) given version or
      COUNT migrations (if given)

  rollback [COUNT]
      revert COUNT last migrations

  redo [steps=COUNT] [[till]=TILL]
      rolls back COUNT or TILL (and including) migration or all if not given
      and then applies them again

  pending
      show migrations that are not applied

  status
      show which migrations were applied and at which time in UTC

EOF

  exit "$1"
}

### DB-specific functions. Sort of abstraction layer

### Generic implementations

__generic_checker(){
  local exe="$1"
  local show="$2"
  local create="$3"

  [[ -x $exe ]] || die "${BOLD}${LYELLOW}${exe##*[/\\]}${CLEAR} ($exe) is ${RED}not available. Ensure that the ${TYPE} client is installed${CLEAR}"

  TMPF=/tmp/$(((RANDOM<<15)|RANDOM)).$$.out
  rm -f $TMPF
  if ! "${TYPE}_cli" "$show" > $TMPF
  then
    rm -f $TMPF
    return 1
  fi
  grep -F -qx "$SCHEMA_TABLE" $TMPF
  local rc=$?
  rm -f $TMPF

  if [ $rc -eq 0 ]
  then
    true
  else
    warn "${LBLUE}creating migrations table: ${LGREEN}$SCHEMA_TABLE${CLEAR}"
    "${TYPE}_cli" "$create"
    rc=$?
  fi

  return "$rc"
}

__generic_previous_versions(){
  local fields="${3:-version}"
  local sql="select $fields from $1$SCHEMA_TABLE$1 order by version desc"
  [[ -n $2 ]] && sql="$sql limit $2"
  "${TYPE}_cli" "$sql;" || exit 1
}

__generic_bump_version_sql(){
  echo "insert into $1$SCHEMA_TABLE$1(version) values($2);"
}

__generic_drop_version_sql(){
  echo "delete from $1$SCHEMA_TABLE$1 where version = $2;"
}

__generic_status(){
  local sql="select $2 from $1$SCHEMA_TABLE$1 order by version desc"
  "${TYPE}_cli" "$sql;" || exit 1
}

### Generic implementations end

##### MySQL
mysql_cli(){
  local args="-N -A -B $ARGS $DATABASE"

  [[ -n $LOGIN    ]] && args="-u $LOGIN    $args"
  [[ -n $HOST     ]] && args="-h $HOST     $args"
  [[ -n $PORT     ]] && args="-P $PORT     $args"
  [[ -n $PASSWORD ]] && export MYSQL_PWD="$PASSWORD"

  if [[ $# -ne 0 ]]
  then
    # shellcheck disable=2086
    # Quoting $args breaks script.
    "$MYSQL" $args <<< "$@"
  else
    # shellcheck disable=2086
    # Quoting $args breaks script.
    "$MYSQL" $args
  fi
}

mysql_check(){
  __generic_checker "$MYSQL" "show tables;" \
    "create table \`$SCHEMA_TABLE\`(version int not null primary key, migrated_at timestamp not null default current_timestamp);"
}

mysql_previous_versions(){
  local fields="lpad(version, 10, '0') as version"
  __generic_previous_versions '`' "$1" "$fields"
}

mysql_bump_version_sql(){
  __generic_bump_version_sql '`' "$1"
}

mysql_drop_version_sql(){
  __generic_drop_version_sql '`' "$1"
}

mysql_status(){
  __generic_status '`' "version, CONVERT_TZ(\`migrated_at\`, @@session.time_zone, '+00:00') AS \`utc_datetime\`"
}

mysql_up_text() {
cat >> "$1" << EOF
BEGIN;

COMMIT;
EOF
}


mysql_down_text() {
cat >> "$1" << EOF
BEGIN;

COMMIT;
EOF
}

##### MySQL end

##### PostgreSQL

postgresql_cli(){
  export PGOPTIONS="-c client_min_messages=WARNING"
  local args="-q -X -v VERBOSITY=terse -v ON_ERROR_STOP=1 -A -t -w -d $DATABASE $ARGS"

  [[ -n $LOGIN    ]] && args="-U $LOGIN    $args"
  [[ -n $HOST     ]] && args="-h $HOST     $args"
  [[ -n $PORT     ]] && args="-p $PORT     $args"
  [[ -n $PASSWORD ]] && export PGPASSWORD="$PASSWORD"

  if [[ $# -ne 0 ]]
  then
    # shellcheck disable=2086
    # Quoting $args breaks script.
    "$PSQL" $args -c "$*"
  else
    # shellcheck disable=2086
    # Quoting $args breaks script.
    "$PSQL" $args
  fi
}

postgresql_check(){
  __generic_checker "$PSQL" \
    "select table_name from information_schema.tables where table_schema = 'public';" \
    "create table \"$SCHEMA_TABLE\"(version int not null primary key, migrated_at timestamp not null default (now() at time zone 'utc'));"
}

postgresql_previous_versions(){
   local fields="to_char(version,'0000000000') as version"
   __generic_previous_versions '"' "$1" "$fields"
}

postgresql_bump_version_sql(){
  __generic_bump_version_sql '"' "$1"
}

postgresql_drop_version_sql(){
  __generic_drop_version_sql '"' "$1"
}

postgresql_status(){
  __generic_status '"' '*'
}

postgresql_up_text() {
cat >> "$1" << EOF
BEGIN;

COMMIT;
EOF
}


postgresql_down_text() {
cat >> "$1" << EOF
BEGIN;

COMMIT;
EOF
}

##### PostgreSQL end

##### SQLite3

sqlite3_cli(){
  local args="-bail -batch $ARGS $DATABASE"

  if [[ $# -ne 0 ]]
  then
    # shellcheck disable=2086
    # Quoting $args break script.
    "$SQLITE3" $args <<< "$@"
  else
    # shellcheck disable=2086
    # Quoting $args break script.
    "$SQLITE3" $args
  fi
}

sqlite3_check(){
  __generic_checker "$SQLITE3" \
    "select name from sqlite_master where type = 'table';" \
    "create table \`$SCHEMA_TABLE\`(version int not null primary key, migrated_at timestamp not null default (datetime(current_timestamp)));"
}

sqlite3_previous_versions(){
  local fields="substr('0000000000' || version, -10, 10) as version"
  __generic_previous_versions '`' "$1" "$fields"
}

sqlite3_bump_version_sql(){
  __generic_bump_version_sql '`' "$1"
}

sqlite3_drop_version_sql(){
  __generic_drop_version_sql '`' "$1"
}

sqlite3_status(){
  __generic_status '`' '*'
}

sqlite3_up_text() {
cat >> "$1" << EOF
BEGIN;
	PRAGMA foreign_keys = ON;

COMMIT;
EOF
}

sqlite3_down_text() {
cat >> "$1" << EOF
BEGIN;

COMMIT;
EOF
}

##### SQLite3 end

### DB-specific functions end

# a wrapper for find that looks for migration files
find_migrations(){
  find -L "$MIGRATIONS" -maxdepth 1 -mindepth 1 -type f "$@"
}

# extract version from migration file name
migration_version(){
  basename "$1" | cut -d - -f 1
}

# get migration name or title.
# gets -- Migration: line from file or uses file name
migration_name(){
  awk '
    /^-- Migration:/{
      sub("^-- Migration: *", "");
      name = $0;
      exit;
    }

    END{
      print name ? name : FILENAME;
    }
  ' "$1"
}

# quote string for use in sed expression
sed_quote(){
  echo "$1" | sed -e 's/[]*\&\/.^$[]/\\&/g'
}

# retrieves section within "$since" - "$till"
# markers. returns false if section is empty or missing
migration_section(){
  local fname="$1"
  local since="^-- $(sed_quote "$2")\$"
  local till="^-- $(sed_quote "$3")\$"
  local tmpfile="${TMPDIR:-/tmp/}shmig-migration-section.$$.${RANDOM}.sql"
  local result="0"

  sed -n -e '/'"$since"'/,/'"$till"'/p' "$fname"\
	 | grep -v "^--" \
	 > "$tmpfile"

  if grep -E -q '[^ \t]' "$tmpfile"
  then
    cat "$tmpfile"
  else
    result="1"
  fi

  rm -f "$tmpfile"
  return "$result"
}

# generate migration
create(){
  [[ $# -eq 1 ]] || die "${LRED}create takes exactly one argument${CLEAR}: $ME create <name>"
  local name="$1"

  echo "$name" | grep -E -qi '^[a-z0-9_. -]+$' || die "${LRED}invalid migration name:${CLEAR} $name"

  # As of 4/28/2014, seconds since epoch has ten digits.
  find_migrations -name "*[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-$name.sql" \
    | grep -q "\-$name\.sql" \
    && die "${LRED}migration '${LYELLOW}$name${LRED}' already exists${CLEAR}"

  local fname="$MIGRATIONS/$(date +%s)-$(echo "$name" | tr \  _).sql"

  cat > "$fname" << EOF
-- Migration: $name
-- Created at: $(date +"%Y-%m-%d %H:%M:%S")
-- $UP_MARK

EOF

"${TYPE}_up_text" "$fname"

cat >> "$fname" << EOF

-- $DOWN_MARK

EOF

"${TYPE}_down_text" "$fname"

  local retval="$?"

  [[ $retval -eq 0 ]] && echo -e "generated ${BOLD}${LGREEN}$fname${CLEAR}"

  return "$retval"
}

# prints N pending migrations sorted by version in ascending order
# if N is not given then all printed
pending_migrations(){
  local last=$("${TYPE}_previous_versions" 1)
  last="${last:-0}"

  find_migrations | sort -t- -k1nr | awk -v "limit=${1:--1}" -v "last=$last" -F/ \
    'limit&&$NF~/^[0-9]+-.*\.sql$/&&int($NF)>last{
      print;
      --limit;
      if(!limit)
        exit;
    }'
}

# prints N previous migration file names.
# if N is not given then all printed
# in case if record from $SCHEMA_TABLE has no corresponding file
# thats an error
previous_migrations(){
  local version=""

  while read -r version
  do
    local migration=$(find_migrations -name "$version-*.sql")
    [[ -z $migration ]] && die "${LRED}migration version ${LYELLOW}$version ${LRED}can't be found${CLEAR}"
    echo "$migration"
  done < <("${TYPE}_previous_versions" "$1")

  # shellcheck disable=SC2181
  [[ $? -ne 0 ]] && exit 1
}

# a wrapper for pending_migrations to display list of pending migrations
pending(){
  [[ $# -ne 0 ]] && die "${LRED}pending takes no arguments${CLEAR}"

  local fname=""
  pending_migrations "$@" | while read -r fname
  do
    echo "${fname##*[/\\]}"
  done
}

# Get the list of applied migrations
status(){
  echo "Applied migrations:"
  "${TYPE}_status"
}

# checks if given argument is numeric or empty
is_numeric(){
  echo "$1" | grep -E -qi '^[0-9]*$'
}

# main function processing migrations.
migrate(){
  local me="$1" # title of this action
  local message="$2" # message to display when processing migration: applying for up or reverting for down
  local since="$3" # applied section markers and name
  local till="$4"
  local sname="$5"
  local src="$6" # source function. should accept number of migrations to display and print their file names
  local version_change_sql="$7" # command that who gets version and should print sql to execute (used to add/remove version in $SCHEMA_TABLE)
  shift 7

  local steps=""
  local stopver=""

  while [[ $# -ne 0 ]] # parse user given options if any
  do
    case "$1" in
      steps=*)
        steps="${1#*=}"
        ;;
      till=*)
        stopver="${1#*=}"
        ;;
      *=*)
        die "${LRED}unknown option:${CLEAR} ${LYELLOW}$1${LYELLOW}"
        ;;
      *)
        if [[ -z $stopver ]]
        then
          stopver="$1"
        else
          die "${LRED}unexpected argument '${LYELLOW}$1${LRED}' for ${LGREEN}$me${LRED}. usage:${CLEAR} $ME $me [steps=STEPS] [[till=][TILL]"
        fi
    esac
    shift
  done

  is_numeric "$steps" || die "${LYELLOW}STEPS${LRED} should be numeric${CLEAR}"
  is_numeric "$stopver" || die "${LYELLOW}TILL${LRED} should be numeric${CLEAR}"

  local fname=""
  while read -r fname
  do
    local version=$(migration_version "$fname")
    local name=$(migration_name "$fname")

    # if until is given and we're hitting it then break
    if [[ -n $stopver ]]
    then
      case "$me" in
          up) (( version > stopver )) && break ;;
        down) (( version < stopver )) && break ;;
      esac
    fi

    local error_tmpfile="${TMPDIR:-/tmp/}shmig-migration-error.${RANDOM}.tmp"
    # pipe section from migration and version change SQL into CLI client of specified type
    (
      echo -en "$ME: $message '${LMAGENTA}${name}${CLEAR}'\t(${LBLUE}$version${LBLUE}${CLEAR})... " >&2

      migration_section "$fname" "$since" "$till" || die "\n  ${LRED}migration in '${LYELLOW}$fname${LRED}' contains no section ${CYAN}$sname${CLEAR}"
      "$version_change_sql" "$version"
    ) | if "${TYPE}_cli" &> "${error_tmpfile}"; then
          echo -e "${BOLD}${LGREEN}done${CLEAR}" >&2
        else
          echo -e "${BOLD}${LRED}error${CLEAR}" >&2
          cat "${error_tmpfile}"
          rm "${error_tmpfile}"
          exit 1
        fi

    [[ ${PIPESTATUS[0]} -eq 0 && ${PIPESTATUS[1]} -eq 0 ]] || exit 1
  done < <("$src" "$steps")
}

# a wrapper for migrate that applies migrations
up(){
  migrate "up" "${LCYAN}applying ${CLEAR}" "$UP_MARK" "$DOWN_MARK" "UP" \
    "pending_migrations" "${TYPE}_bump_version_sql" "$@"
}

# a wrapper for migrate that reverts migrations
down(){
  migrate "down" "${LGREEN}reverting${CLEAR}" "$DOWN_MARK" "$UP_MARK" "DOWN" \
    "previous_migrations" "${TYPE}_drop_version_sql" "$@"
}

# parse command line and store variables in _VAR to overwrite config values
# later

while getopts hc:t:m:d:l:H:p:P:s:a:AVC: arg
do
  case $arg in
    h)   usage 0                   ;;
    c)   CONFIG_EXPLICITLY_SET="1"
         CONFIG="$OPTARG"          ;;
    t)   _TYPE="$OPTARG"           ;;
    m)   _MIGRATIONS="$OPTARG"     ;;
    d)   _DATABASE="$OPTARG"       ;;
    l)   _LOGIN="$OPTARG"          ;;
    H)   _HOST="$OPTARG"           ;;
    p)   _PASSWORD="$OPTARG"       ;;
    P)   _PORT="$OPTARG"           ;;
    s)   _SCHEMA_TABLE="$OPTARG"   ;;
    a)   _ARGS="$OPTARG"           ;;
    V)   version                   ;;
    A)   ASK_PASSWORD="1"          ;;
    C)   _COLOR="$OPTARG"          ;;
    ?)   exit 1                    ;;
  esac
done
shift $((OPTIND - 1))

# if config exists
if [[ -e $CONFIG ]]
then
  # any error in configuration file should cause failure
  # to avoid potential database corruption
  trap 'die "Configuration failed"' ERR
  # shellcheck source=/dev/null
  . "$CONFIG"
  # reset handler
  trap - ERR
elif [[ $CONFIG_EXPLICITLY_SET -eq 1 ]]
then
  # if user explicitly requested config to be parsed and it is missing
  # we should bail out with error
  die "Configuration file '$CONFIG' doesn't exist"
fi

# Include local config, if available (e.g., shmig.local.conf
LOCAL_CONFIG="${CONFIG%.*}.local.${CONFIG##*.}"
if [ -e "$LOCAL_CONFIG" ]; then
  # any error in configuration file should cause failure
  # to avoid potential database corruption
  trap 'die "Local configuration failed"' ERR
  # shellcheck source=/dev/null
  . "$LOCAL_CONFIG"
  # reset handler
  trap - ERR
fi


[[ $ASK_PASSWORD -eq 1 ]] && read -r -s -p "Password: " _PASSWORD

# options from command line have higher priority than configuration
# file. if they were given then we overwrite values
[[ -n $_TYPE         ]] && TYPE="$_TYPE"
[[ -n $_MIGRATIONS   ]] && MIGRATIONS="$_MIGRATIONS"
[[ -n $_DATABASE     ]] && DATABASE="$_DATABASE"
[[ -n $_LOGIN        ]] && LOGIN="$_LOGIN"
[[ -n $_HOST         ]] && HOST="$_HOST"
[[ -n $_PASSWORD     ]] && PASSWORD="$_PASSWORD"
[[ -n $_PORT         ]] && PORT="$_PORT"
[[ -n $_SCHEMA_TABLE ]] && SCHEMA_TABLE="$_SCHEMA_TABLE"
[[ -n $_ARGS         ]] && ARGS="$_ARGS"
[[ -n $_COLOR        ]] && COLOR="$_COLOR"

# figure out color policy
case "$COLOR" in
  always)
    COLOR="0"
    ;;
  never)
    COLOR="1"
    ;;
  auto)
    tty &>/dev/null
    COLOR="$?"
    ;;
  *)
    die "color should be one of 'auto', 'never', 'always', got '$COLOR'"
    ;;
esac

# if colors enabled then assign color codes to appropriate variables
if [[ $COLOR -eq 0 ]]
then
  RED="\e[31m"
  CYAN="\e[36m"
  LRED="\e[91m"
  LGREEN="\e[92m"
  LYELLOW="\e[93m"
  LBLUE="\e[94m"
  LMAGENTA="\e[95m"
  LCYAN="\e[96m"
  BOLD="\e[1m"
  CLEAR="\e[0m"
fi

# required arguments and sanity checks
[[ -z $TYPE       ]] && die "${BOLD}${LYELLOW}database type${CLEAR} ${RED}required${CLEAR}"
[[ -z $DATABASE   ]] && die "${BOLD}${LYELLOW}database name${CLEAR} ${RED}required${CLEAR}"
[[ -d $MIGRATIONS ]] || die "${BOLD}${LYELLOW}the migrations directory ($MIGRATIONS)${CLEAR} ${RED}is not a directory${CLEAR}"

[[ $# -eq 0 ]] && die "${BOLD}${LYELLOW}action${CLEAR} ${RED}required${CLEAR}"
ACTION="$1"
shift

# database types list is not hard-coded. we just check that TYPE_check function exists
[[ $(type -t "${TYPE}_check") = "function" ]] || die "${LRED}unknown database type:${CLEAR} $TYPE"

# if database-specifc checker fails then bail out
[[ $ACTION == "create" ]] || "${TYPE}_check" || exit 1

case "$ACTION" in
  create)
    create "$@"
    ;;
  migrate|up)
    up "$@"
    ;;
  down)
    down "$@"
    ;;
  rollback) # rollback is just a handy down wrapper
    [[ $# -gt 1 ]] && die "${LRED}rollback takes only one optional argument - COUNT${CLEAR}"
    down steps="${1:-1}"
    ;;
  redo)
    CURRENT_VERSION=$("${TYPE}_previous_versions" 1)
    # special case: no migrations
    [[ -z $CURRENT_VERSION || $CURRENT_VERSION -eq 0 ]] && exit 0
    down "$@" && up "$CURRENT_VERSION"
    ;;
  pending)
    pending "$@"
    ;;
  status)
    status "$@"
    ;;
  *)
    die "${LRED}unknown action:${CLEAR} $ACTION"
    ;;
esac
