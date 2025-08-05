#!/bin/sh
# https://gist.github.com/msanders/57837aaf6f7da30dcc1eb0bdf6b0b733
# License: MIT
set -o errexit -o nounset

SCRIPT_NAME="$(basename "$0")"

show_usage() {
    cat <<USAGE
Usage: $SCRIPT_NAME <profile> <backup>
Restore cookie exceptions for Firefox profile from a newline-separated list of
domain names. Any exceptions stored in the profile that are not included in the
backup will be removed.
USAGE
}

sql_insertion_statement() (
    dbpath="$1"
    origin="$2"
    mtime="$3"
    cat <<EOF
INSERT INTO
  moz_perms (
    origin,
    type,
    permission,
    expireType,
    expireTime,
    modificationTime
  )
VALUES
  ('$origin', 'cookie', 1, 0, 0, $mtime);
EOF
)

generate_sql() {
    dbpath="$1"
    backup="$2"
    modtime="$(date +%s000)"
    while read -r line; do
        sql_insertion_statement "$dbpath" "https://$line" "$modtime"
        sql_insertion_statement "$dbpath" "http://$line" "$modtime"
    done <"$backup"
}

main() (
    if [ "$#" -ne 2 ]; then
        show_usage
        exit 1
    fi
    for i; do
        case $i in
            -h | --help)
                show_usage
                exit
        esac
    done

    profiledir="$1"
    backup="$2"
    dbpath="$profiledir/permissions.sqlite"
    sql="$(generate_sql "$dbpath" "$backup")"
    sqlite3 -init /dev/null "$dbpath" <<EOF
BEGIN TRANSACTION;
DELETE FROM moz_perms
WHERE
  type = 'cookie'
  AND permission = 1
  AND expireTime = 0;
$sql
COMMIT;
EOF
    printf "Successfully imported cookie exceptions to '%s'.\n" "$dbpath"
)

main "$@"
