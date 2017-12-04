# ----------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ----------------------------------------------------------------------
# Name.......: Dockerfile 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: 
# Date.......: 
# Revision...: 
# Purpose....: Dockerfile to build OUDSM image
# Notes......: --
# Reference..: --
# License....: CDDL 1.0 + GPL 2.0
# ----------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# TODO.......:
# --
# ----------------------------------------------------------------------

# Pull base image
# ----------------------------------------------------------------------
FROM oraclelinux:7-slim

# Maintainer
# ----------------------------------------------------------------------
MAINTAINER Stefan Oehrli <stefan.oehrli@trivadis.com>

# Arguments for MOS Download
ARG MOS_USER
ARG MOS_PASSWORD

# Arguments for Oracle Installation
ARG ORACLE_ROOT
ARG ORACLE_DATA
ARG ORACLE_BASE

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV DOWNLOAD=/tmp/download \
    DOCKER_SCRIPTS=/opt/docker/bin \
    ORACLE_ROOT=${ORACLE_ROOT:-/u00} \
    ORACLE_DATA=${ORACLE_DATA:-/u01} \
    ORACLE_BASE=${ORACLE_BASE:-/u00/app/oracle} \
    ORACLE_HOME_NAME=fmw12.2.1.3.0 \
    DOMAIN_NAME=${DOMAIN_NAME:-oudsm_domain} \
    DOMAIN_HOME=/u01/domains/${DOMAIN_NAME:-oudsm_domain} \
    ADMIN_PORT=${ADMIN_PORT:-7001} \
    ADMIN_SSLPORT=${ADMIN_SSLPORT:-7002} \
    ADMIN_USER=${ADMIN_USER:-weblogic} \
    ADMIN_PASSWORD=${ADMIN_PASSWORD:-""}

# copy all scripts to DOCKER_BIN
COPY scripts ${DOCKER_SCRIPTS}
COPY software ${DOWNLOAD}

# Java and OUD base environment setup via shell script to reduce layers and 
# optimize final disk usage
RUN ${DOCKER_SCRIPTS}/setup_java.sh MOS_USER=${MOS_USER} MOS_PASSWORD=${MOS_PASSWORD} && \
    ${DOCKER_SCRIPTS}/setup_oudbase.sh

# Switch to user oracle, oracle software as to be installed with regular user
USER oracle

# Instal OUD / OUDSM via shell script to reduce layers and optimize final disk usage
RUN ${DOCKER_SCRIPTS}/setup_oudsm.sh MOS_USER=${MOS_USER} MOS_PASSWORD=${MOS_PASSWORD}

# OUD admin and ldap ports as well the OUDSM console
EXPOSE ${ADMIN_PORT} ${ADMIN_SSLPORT}

# Oracle data volume for OUD instance and configuration files
VOLUME ["${ORACLE_DATA}"]

# entrypoint for OUDSM domain creation, startup and graceful shutdown
ENTRYPOINT ["${DOCKER_SCRIPTS}/create_and_start_OUDSM_Domain.sh"]
CMD [""]
# --- EOF --------------------------------------------------------------