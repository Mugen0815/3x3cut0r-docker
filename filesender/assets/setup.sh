#!/bin/bash
# This script is based off of ideas from https://github.com/litnet/docker-filesender/blob/master/web/docker-entrypoint.sh

# Make sure we only run once
sv once personalisation

USER='www-data'
USER_ID="$(cat /etc/passwd | grep www-data | cut -d ':' -f 3)"
GROUP_ID="$(cat /etc/passwd | grep www-data | cut -d ':' -f 4)"

FILESENDER_SERIES=${FILESENDER_V%%.*}
FILESENDER_AUTHTYPE=${FILESENDER_AUTHTYPE:-simplesamlphp}
FILESENDER_URL=${FILESENDER_URL:-"http://localhost"}
FILESENDER_LOGOUT_URL=${FILESENDER_LOGOUT_URL:-"$FILESENDER_URL/login.php"}
FILESENDER_STORAGE=${FILESENDER_STORAGE:-"filesystemChunked"}
FILESENDER_FORCE_SSL=${FILESENDER_FORCE_SSL:-false}
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@abcde.edu}
SMTP_SERVER=${SMTP_SERVER:-localhost}

TEMPLATE_DIR="/opt/filesender/config-templates"
FILESENDER_DIR="/opt/filesender/filesender"
SIMPLESAML_DIR="/opt/filesender/simplesamlphp"
SIMPLESAML_MODULES="cas exampleauth"

USER_UID=${USER_UID:-$USER_ID}
USER_GID=${USER_GID:-$GROUP_ID}

DB_HOST=${DB_HOST:-localhost}
DB_TYPE=${DB_TYPE:-mysql}
DB_NAME=${DB_NAME:-filesender}
DB_USER=${DB_USER:-filesender}
DB_PASSWORD=${DB_PASSWORD:-filesender}

TEMPLATE_WARNING=${TEMPLATE_WARNING:-"// !!! DO NOT EDIT THIS FILE! It is regenerated from environment variables every time the container starts !!!"}
LOG_DETAIL=${LOG_DETAIL:-"info"}
FPM_MIN_SPARE_SERVERS=${FPM_MIN_SPARE_SERVERS:-1}
FPM_MAX_SPARE_SERVERS=${FPM_MAX_SPARE_SERVERS:-5}
SIMPLESAML_SESSION_COOKIE_SECURE=${SIMPLESAML_SESSION_COOKIE_SECURE:-false}

EMAIL_FROM_ADDRESS=${EMAIL_FROM_ADDRESS:-"filesender@your.org"}
EMAIL_FROM_NAME=${EMAIL_FROM_NAME:-"{cfg:site_name} - {cfg:site_url}"}
SMTP_PORT=${SMTP_PORT:-"25"}
SMTP_TLS=${SMTP_TLS:-"on"}
SMTP_AUTH=${SMTP_AUTH:-"on"}
SMTP_USER=${SMTP_USER:-"missing"}
SMTP_PASSWORD=${SMTP_PASSWORD:-"secret"}
SMTP_FROM=${SMTP_FROM:${EMAIL_FROM_ADDRESS}}

TRANSFER_MAX_DAYS_VALID=${TRANSFER_MAX_DAYS_VALID:-20}
TRANSFER_DEFAULT_DAYS=${TRANSFER_DEFAULT_DAYS:-7}

REDIS_HOST=${REDIS_HOST:-"localhost"}
REDIS_PORT=${REDIS_PORT:-6379}

if [ "$DB_TYPE" = "mysql" ]; then
  # default port for mysql
  DB_PORT=${DB_PORT:-3306}
else
  # default port for postgresql
  DB_PORT=${DB_PORT:-5432}
fi

function sed_file {
  if [ "$2" = "" ]; then
    SRCFILE="$1.default"
    DSTFILE="$1"
    if [ ! -f "$SRCFILE" ]; then
      cp "$1" "$SRCFILE"
    fi
  else
    SRCFILE="$1"
    DSTFILE="$2"
  fi

  cat "$SRCFILE" | sed \
    -e "s|{FILESENDER_URL}|${FILESENDER_URL}|g" \
    -e "s|{FILESENDER_LOGOUT_URL}|${FILESENDER_LOGOUT_URL}|g" \
    -e "s|{FILESENDER_STORAGE}|${FILESENDER_STORAGE}|g" \
    -e "s|{FILESENDER_FORCE_SSL}|${FILESENDER_FORCE_SSL}|g" \
    -e "s|{FILESENDER_AUTHTYPE}|${FILESENDER_AUTHTYPE}|g" \
    -e "s|{FILESENDER_AUTHSAML}|${FILESENDER_AUTHSAML}|g" \
    -e "s|{DB_HOST}|${DB_HOST}|g" \
    -e "s|{DB_PORT}|${DB_PORT}|g" \
    -e "s|{DB_TYPE}|${DB_TYPE}|g" \
    -e "s|{DB_NAME}|${DB_NAME}|g" \
    -e "s|{DB_USER}|${DB_USER}|g" \
    -e "s|{DB_PASSWORD}|${DB_PASSWORD}|g" \
    -e "s|{ADMIN_USERS}|${ADMIN_USERS:-admin}|g" \
    -e "s|{ADMIN_EMAIL}|${ADMIN_EMAIL}|g" \
    -e "s|{ADMIN_PSWD}|${ADMIN_PSWD}|g" \
    -e "s|{SIMPLESAML_SALT}|${SIMPLESAML_SALT}|g" \
    -e "s|'123'|\'${ADMIN_PSWD}\'|g" \
    -e "s|'defaultsecretsalt'|\'${SIMPLESAML_SALT}\'|g" \
    -e "s|{SAML_MAIL_ATTR}|${SAML_MAIL_ATTR}|g" \
    -e "s|{SAML_NAME_ATTR}|${SAML_NAME_ATTR}|g" \
    -e "s|{SAML_UID_ATTR}|${SAML_UID_ATTR}|g" \
    -e "s|{TEMPLATE_WARNING}|${TEMPLATE_WARNING}|g" \
    -e "s|{LOG_DETAIL}|${LOG_DETAIL}|g" \
    -e "s|{EMAIL_FROM_ADDRESS}|${EMAIL_FROM_ADDRESS}|g" \
    -e "s|{EMAIL_FROM_NAME}|${EMAIL_FROM_NAME}|g" \
    -e "s|{SMTP_HOST}|${SMTP_SERVER}|g" \
    -e "s|{SMTP_TLS}|${SMTP_TLS}|g" \
    -e "s|{SMTP_AUTH}|${SMTP_AUTH}|g" \
    -e "s|{SMTP_USER}|${SMTP_USER}|g" \
    -e "s|{SMTP_PASSWORD}|${SMTP_PASSWORD}|g" \
    -e "s|{SMTP_PORT}|${SMTP_PORT}|g" \
    -e "s|{SMTP_FROM}|${SMTP_FROM}|g" \
    -e "s|{SIMPLESAML_SESSION_COOKIE_SECURE}|${SIMPLESAML_SESSION_COOKIE_SECURE}|g" \
    -e "s|{REDIS_HOST}|${REDIS_HOST}|g" \
    -e "s|{REDIS_PORT}|${REDIS_PORT}|g" \
    -e "s|{TRANSFER_MAX_DAYS_VALID}|${TRANSFER_MAX_DAYS_VALID}|g" \
    -e "s|{TRANSFER_DEFAULT_DAYS}|${TRANSFER_DEFAULT_DAYS}|g" \
    -e "s|{USER_UID}|${USER_UID}|g" \
    -e "s|{USER_GID}|${USER_GID}|g" \
    -e "s|{FPM_MIN_SPARE_SERVERS}|${FPM_MIN_SPARE_SERVERS}|g" \
    -e "s|{FPM_MAX_SPARE_SERVERS}|${FPM_MAX_SPARE_SERVERS}|g" \
    -e "s|{SAML_TECHC_NAME}|${SAML_TECHC_NAME}|g" \
    -e "s|{SAML_TECHC_EMAIL}|${SAML_TECHC_EMAIL}|g" \
    -e "s|{FPM_MAX_SPARE_SERVERS}|${FPM_MAX_SPARE_SERVERS}|g" \
   > "$DSTFILE"
}

# fpm setup
sed_file ${TEMPLATE_DIR}/fpm/www.conf /config/fpm/www.conf

# msmtp setup
sed_file ${TEMPLATE_DIR}/msmtp/msmtprc /etc/msmtprc

# simplesaml.php setup:

if [ "$SIMPLESAML_SALT" = "" ]; then
  SIMPLESAML_SALT=`tr -c -d '0123456789abcdefghijklmnopqrstuvwxyz' </dev/urandom | dd bs=32 count=1 2>/dev/null;echo`
fi

sed_file "${TEMPLATE_DIR}/simplesaml/config.php" "${SIMPLESAML_DIR}/config/config.php"
sed_file "${TEMPLATE_DIR}/simplesaml/authsources.php" "${SIMPLESAML_DIR}/config/authsources.php"

for MODULE in $SIMPLESAML_MODULES; do
  if [ -d ${SIMPLESAML_DIR}/modules/$MODULE ]; then
    touch ${SIMPLESAML_DIR}/modules/$MODULE/enable
  fi
done

# filesender setup:

if [ -f ${TEMPLATE_DIR}/filesender/login.php ]; then
  sed_file ${TEMPLATE_DIR}/filesender/login.php ${FILESENDER_DIR}/www/login.php
fi

FILESENDER_AUTHTYPE=${FILESENDER_AUTHTYPE:-"saml"}

if [ "$FILESENDER_AUTHTYPE" = "shibboleth" ]; then
  # Attributes passed via environment variables from shibboleth
  SAML_MAIL_ATTR=${SAML_MAIL_ATTR:-"HTTP_SHIB_MAIL"}
  SAML_NAME_ATTR=${SAML_NAME_ATTR:-"HTTP_SHIB_CN"}
  SAML_UID_ATTR=${SAML_UID_ATTR:-"HTTP_SHIB_UID"}
elif [ "$FILESENDER_AUTHTYPE" = "fake" ]; then
  # Manually set attribute values for v2.0 "fake authentication"
  SAML_MAIL_ATTR=${SAML_MAIL_ATTR:-"fakeuser@abcde.edu"}
  SAML_NAME_ATTR=${SAML_NAME_ATTR:-"Fake User"}
  SAML_UID_ATTR=${SAML_UID_ATTR:-"fakeuser"}
else
  # Attributes passed from simplesamlphp
  FILESENDER_AUTHSAML=${FILESENDER_AUTHSAML:-"sp-default"}
  SAML_MAIL_ATTR=${SAML_MAIL_ATTR:-"mail"}
  SAML_NAME_ATTR=${SAML_NAME_ATTR:-"cn"}
  SAML_UID_ATTR=${SAML_UID_ATTR:-"uid"}
fi

if [ -f ${TEMPLATE_DIR}/filesender/config.php ]; then
  sed_file ${TEMPLATE_DIR}/filesender/config.php ${FILESENDER_DIR}/config/config.php
fi

# setup database
if [ "`which nc`" != "" ]; then
  RESULT=`nc -z -w1 ${DB_HOST} ${DB_PORT} && echo 1 || echo 0`

  while [ $RESULT -ne 1 ]; do
    echo " **** Database at ${DB_HOST}:${DB_PORT} is not responding, waiting... **** "
    sleep 5
    RESULT=`nc -z -w1 ${DB_HOST} ${DB_PORT} && echo 1 || echo 0`
  done

  php ${FILESENDER_DIR}/scripts/upgrade/database.php

  if [ "xx$SELENIUM_HOST" != "xx" ]; then
    export PGPASSWORD=$DB_PASSWORD
    psql -c 'create database filesenderdataset;' -h $DB_HOST -U $DB_USER
    bzcat ${FILESENDER_DIR}/scripts/dataset/dumps/filesender-2.0beta1.pg.bz2 | psql -h $DB_HOST -U $DB_USER -d filesenderdataset
  fi
fi

chown -R www-data:www-data /opt/*

# Check if www-data's uid:gid has been requested to be changed
NEW_UID=${CHOWN_WWW%%:*}
NEW_GID=${CHOWN_WWW##*:}

if [ "$NEW_GID" = "" ]; then
  NEW_GID=$NEW_UID
fi

if [ "$NEW_UID" != "" ]; then
  # Change old $USER_ID to $NEW_UID, similarly old $GROUP_ID->$NEW_GID
  groupmod -g $NEW_GID $USER
  usermod -u $NEW_UID $USER
  find / -type d -path /proc -prune -o -group $GROUP_ID -exec chgrp -h $USER {} \;
  find / -type d -path /proc -prune -o -user $USER_ID -exec chown -h $USER {} \;
fi

# Make sure we don't run again when we exit cleanly
touch /etc/service/personalisation/down

# We are done here
exit 0
