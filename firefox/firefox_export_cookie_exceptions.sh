#!/bin/sh
# https://gist.github.com/msanders/57837aaf6f7da30dcc1eb0bdf6b0b733
# License: MIT
set -o errexit -o nounset

SCRIPT_NAME="$(basename "$0")"

show_usage() {
    cat <<USAGE
Usage: $SCRIPT_NAME <profile>
Export cookie exceptions from a Firefox profile as a newline-separated list of
domain names.
USAGE
}

main() (
    if [ "$#" -ne 1 ]; then
        show_usage
        exit 1
    fi
    case "$1" in
        -h | --help)
            show_usage
            exit
    esac

    profiledir="$(readlink -f "$1")"
    dbpath="$profiledir/permissions.sqlite"
    sqlite3 -init /dev/null -readonly "file://$dbpath?immutable=1" <<EOF | sed "s_^https\{0,1\}://__" | sort -u
SELECT
  origin
FROM
  moz_perms
WHERE
  type = 'cookie'
  AND permission = 1
  AND expireTime = 0;
EOF
)

main "$@"
