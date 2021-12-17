#!/usr/bin/env sh
set -ex

PHP_EXTENSIONS="bcmath bz2 calendar ctype curl dba dom enchant exif ffi fileinfo filter ftp gd gettext gmp hash iconv imap intl json ldap mbstring mysqli oci8 odbc opcache pcntl pdo pdo_dblib pdo_firebird pdo_mysql pdo_oci pdo_odbc pdo_pgsql pdo_sqlite pgsql phar posix pspell readline reflection session shmop simplexml snmp soap sockets sodium spl standard sysvmsg sysvsem sysvshm tidy tokenizer xml xmlreader xmlrpc xmlwriter xsl zend_test zip"
PECL_EXTENSIONS="apcu imagick sqlsrv pdo_sqlsrv mcrypt"
RUN_DEPS="unzip libzip icu libxslt imagemagick libmcrypt recode tidyhtml freetype libjpeg-turbo libpng libwebp libxpm make"
BUILD_DEPS="autoconf g++ libzip-dev zlib-dev libpng-dev libxml2-dev icu-dev bzip2-dev libc-dev gmp-dev libmcrypt-dev recode-dev gettext-dev tidyhtml-dev libxslt-dev imagemagick-dev freetype-dev libjpeg-turbo-dev libpng-dev libwebp-dev libxpm-dev tzdata unixodbc-dev"

apk add --no-cache --virtual rundeps ${RUN_DEPS}
apk add --no-cache --virtual .build-deps ${BUILD_DEPS}
apk update

apk add --no-cache fcgi file gettext gnu-libiconv bash

# install gnu-libiconv and set LD_PRELOAD env to make iconv work fully on Alpine image.
# see https://github.com/docker-library/php/issues/240#issuecomment-763112749
export LD_PRELOAD="/usr/lib/preloadable_libiconv.so"

apk add --no-cache --virtual rundeps ${RUN_DEPS}
apk add --no-cache --virtual .build-deps ${BUILD_DEPS}


docker-php-source extract
docker-php-ext-configure gd --with-freetype --with-jpeg --with-png --with-xpm
docker-php-ext-install -j"$(nproc)" ${PHP_EXTENSIONS}
pecl install ${PECL_EXTENSIONS}
docker-php-ext-enable ${PECL_EXTENSIONS}

docker-php-source delete
rm -r /tmp/pear/cache/* /tmp/pear/download/*

### TimeZone
cp /usr/share/zoneinfo/Europe/Paris /etc/localtime
echo "Europe/Paris" >  /etc/timezone

### Custom - Sql Server
curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.7.2.1-1_amd64.apk
apk add --allow-untrusted msodbcsql17_17.7.2.1-1_amd64.apk
rm msodbcsql17_17.7.2.1-1_amd64.apk

apk del .build-deps

### create php-session DIR
mkdir /tmp/php-sessions/
chmod +rw /tmp/php-sessions/