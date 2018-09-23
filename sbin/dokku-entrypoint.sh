#!/bin/sh

if [ "${DB_TYPE}" = "postgresql" ]
then
    export POSTGRES_DB="${DB_NAME}"
    export POSTGRES_USER="${DB_USER}"
    export POSTGRES_PASSWORD="${DB_PASS}"
    export POSTGRES_HOST="${DB_HOST}"
else
    export MYSQL_DATABASE="${DB_PATH}"
    export MYSQL_USER="${DB_USER}"
    export MYSQL_PASSWORD="${DB_PASS}"
    export MYSQL_HOST="${DB_HOST}"
fi

# hacky and dumb as hell, but we have to override the parent entrypoint,
# because they are doing some weird rsync fuckery there which deletes stuff like nginx.conf.sigil

# version_greater A B returns whether A > B
version_greater() {
    [ "$(printf '%s\n' "$@" | sort -t '.' -n -k1,1 -k2,2 -k3,3 -k4,4 | head -n 1)" != "$1" ]
}

# return true if specified directory is empty
directory_empty() {
    [ -z "$(ls -A "$1/")" ]
}

run_as() {
    if [ "$(id -u)" = 0 ]; then
        su - www-data -s /bin/sh -c "$1"
    else
        sh -c "$1"
    fi
}

installed_version="0.0.0.0"
if [ -f /var/www/html/version.php ]; then
    # shellcheck disable=SC2016
    installed_version="$(php -r 'require "/var/www/html/version.php"; echo implode(".", $OC_Version);')"
fi
# shellcheck disable=SC2016
image_version="$(php -r 'require "/usr/src/nextcloud/version.php"; echo implode(".", $OC_Version);')"

if version_greater "$installed_version" "$image_version"; then
    echo "Can't start Nextcloud because the version of the data ($installed_version) is higher than the docker image version ($image_version) and downgrading is not supported. Are you sure you have pulled the newest image version?"
    exit 1
fi

if version_greater "$image_version" "$installed_version"; then
    if [ "$installed_version" != "0.0.0.0" ]; then
        run_as 'php /var/www/html/occ app:list' | sed -n "/Enabled:/,/Disabled:/p" > /tmp/list_before
    fi
    if [ "$(id -u)" = 0 ]; then
        rsync_options="-rlDog --chown www-data:root"
    else
        rsync_options="-rlD"
    fi
    rsync $rsync_options --delete --exclude /nginx.conf.sigil --exclude /nginx.conf.d/ --exclude /config/ --exclude /data/ --exclude /custom_apps/ --exclude /themes/ /usr/src/nextcloud/ /var/www/html/

    for dir in nginx.conf.sigil nginx.conf.d config data custom_apps themes; do
        if [ ! -d "/var/www/html/$dir" ] || directory_empty "/var/www/html/$dir"; then
            rsync $rsync_options --include "/$dir/" --exclude '/*' /usr/src/nextcloud/ /var/www/html/
        fi
    done

    if [ "$installed_version" != "0.0.0.0" ]; then
        run_as 'php /var/www/html/occ upgrade'

        run_as 'php /var/www/html/occ app:list' | sed -n "/Enabled:/,/Disabled:/p" > /tmp/list_after
        echo "The following apps have been disabled:"
        diff /tmp/list_before /tmp/list_after | grep '<' | cut -d- -f2 | cut -d: -f1
        rm -f /tmp/list_before /tmp/list_after
    fi
fi

exec "$@"
