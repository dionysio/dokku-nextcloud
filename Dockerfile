FROM nextcloud:14-fpm-alpine

COPY sbin/* /sbin/

RUN ["chmod", "+x", "/sbin/docker-entrypoint.sh"]

ENTRYPOINT ["/sbin/dokku-entrypoint.sh"]

CMD ["php-fpm"]

COPY nginx.conf.sigil .
COPY nginx.conf.d/nextcloud.conf ./nginx.conf.d/nextcloud.conf
